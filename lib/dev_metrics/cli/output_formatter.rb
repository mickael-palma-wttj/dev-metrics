require 'json'

module DevMetrics
  module CLI
    # Handles formatting and output of metric results
    class OutputFormatter
      FORMATS = %w[text json csv html markdown].freeze

      attr_reader :format, :output_file, :template_renderer

      def initialize(format = 'text', output_file = nil)
        @format = format.to_s.downcase
        @output_file = output_file
        @template_renderer = Utils::TemplateRenderer.new

        validate_format
      end

      def format_results(results, metadata = {})
        case format
        when 'text'
          format_text(results, metadata)
        when 'json'
          format_json(results, metadata)
        when 'csv'
          format_csv(results, metadata)
        when 'html'
          format_html(results, metadata)
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end

      def format_analysis_results(results, summary = {})
        case format
        when 'text'
          format_analysis_text(results, summary)
        when 'json'
          format_analysis_json(results, summary)
        when 'csv'
          format_analysis_csv(results, summary)
        when 'html'
          format_analysis_html(results, summary)
        when 'markdown'
          format_analysis_markdown(results, summary)
        else
          raise ArgumentError, "Unsupported format: #{format}"
        end
      end

      def output(content)
        if output_file
          File.write(output_file, content)
          puts "Results written to: #{output_file}"
        else
          puts content
        end
      end

      private

      def validate_format
        return if FORMATS.include?(format)

        raise ArgumentError, "Invalid format '#{format}'. Valid formats: #{FORMATS.join(', ')}"
      end

      def format_text(results, metadata)
        template_name = 'basic_report.text'

        if template_renderer.template_exists?(template_name)
          render_basic_template(template_name, results, metadata)
        else
          format_text_fallback(results, metadata)
        end
      end

      def format_json(results, metadata)
        {
          metadata: metadata,
          results: results.map(&:to_h),
          summary: generate_summary(results)
        }.to_json
      end

      def format_csv(results, metadata)
        require 'csv'

        CSV.generate do |csv|
          # Header
          csv << %w[metric_name value repository status error]

          # Data rows
          results.each do |result|
            csv << [
              result.metric_name,
              result.value,
              result.repository,
              result.success? ? 'success' : 'failed',
              result.error
            ]
          end
        end
      end

      def format_html(results, metadata)
        template_name = 'basic_report.html'

        if template_renderer.template_exists?(template_name)
          render_basic_template(template_name, results, metadata)
        else
          format_html_fallback(results, metadata)
        end
      end

      def group_results_by_category(results)
        # Group results by metric category (inferred from metric name)
        grouped = {}

        results.each do |result|
          category = infer_category(result.metric_name)
          grouped[category] ||= []
          grouped[category] << result
        end

        grouped
      end

      def infer_category(metric_name)
        case metric_name.downcase
        when /commit.*activity/, /commits.*per/, /commit.*size/, /commit.*frequency/
          'commit_activity'
        when /churn/, /authors.*per.*file/, /ownership/, /co.*change/
          'code_churn'
        when /revert/, /bugfix/, /large.*commit/
          'reliability'
        when /lead.*time/, /deployment/
          'flow'
        when /pr.*/, /pull.*request/
          'pr_throughput'
        when /review/
          'review_collaboration'
        when /cross.*repo/, /critical.*file/
          'knowledge'
        when /off.*hours/, /pickup/, /change.*failure/, /mttr/
          'team_health'
        else
          'other'
        end
      end

      def format_analysis_text(results, summary)
        # Show contributor filter information if active
        if summary[:contributor_filter]
          filter_info = summary[:contributor_filter]
          contributors_list = filter_info[:contributors].join(', ')
          summary[:contributor_filter_display] =
            "Filtered by Contributors: #{contributors_list} (#{filter_info[:count]} contributor#{if filter_info[:count] != 1
                                                                                                   's'
                                                                                                 end})"
        end

        template_name = 'analysis_report.text'

        if template_renderer.template_exists?(template_name)
          render_with_template(template_name, results, summary)
        else
          format_analysis_text_fallback(results, summary)
        end
      end

      def format_analysis_json(results, summary)
        {
          summary: summary,
          results: results.transform_values do |data|
            {
              category: data[:metadata][:category],
              metric: data[:metric].to_h,
              execution_time: data[:metadata][:execution_time]
            }
          end
        }.to_json
      end

      def format_analysis_csv(results, summary)
        require 'csv'

        CSV.generate do |csv|
          csv << %w[category metric_name value data_points execution_time]

          results.each do |metric_name, data|
            metric_result = data[:metric]
            csv << [
              data[:metadata][:category],
              metric_name,
              format_metric_value(metric_result.value),
              metric_result.metadata[:data_points] || 0,
              data[:metadata][:execution_time] || 0
            ]
          end
        end
      end

      def format_analysis_html(results, summary)
        template_name = 'analysis_report.html'

        if template_renderer.template_exists?(template_name)
          render_with_template(template_name, results, summary)
        else
          # Fallback to existing HTML format
          format_html([], summary.merge(results: results))
        end
      end

      def format_analysis_markdown(results, summary)
        template_name = 'analysis_report.markdown'

        if template_renderer.template_exists?(template_name)
          render_with_template(template_name, results, summary)
        else
          # Fallback to text format if no markdown template
          format_analysis_text(results, summary)
        end
      end

      def group_analysis_results(results)
        results.group_by { |_, data| data[:metadata][:category] }
      end

      def format_metric_value(value)
        case value
        when Numeric
          value.round(2)
        when Array
          "#{value.size} items"
        when Hash
          if value.empty?
            'No data'
          else
            "#{value.keys.size} categories"
          end
        else
          value.to_s
        end
      end

      def format_value(value)
        case value
        when Numeric
          value.round(2)
        when Array
          "#{value.size} items"
        when Hash
          "#{value.keys.size} categories"
        else
          value.to_s
        end
      end

      def generate_summary(results)
        {
          total_metrics: results.size,
          successful_metrics: results.count(&:success?),
          failed_metrics: results.count(&:failed?),
          categories: group_results_by_category(results).keys
        }
      end

      def format_execution_time(time_seconds)
        return '0s' if time_seconds.nil? || time_seconds == 0

        if time_seconds < 1
          "#{(time_seconds * 1000).round(0)}ms"
        else
          "#{time_seconds.round(2)}s"
        end
      end

      # Template rendering methods
      def render_with_template(template_name, results, summary)
        binding_context = create_template_binding(results, summary)
        template_renderer.render(template_name, binding_context)
      end

      def render_basic_template(template_name, results, metadata)
        binding_context = create_basic_template_binding(results, metadata)
        template_renderer.render(template_name, binding_context)
      end

      def create_template_binding(results, summary)
        # Use this instance's binding so the template has access to all methods
        template_binding = binding
        template_binding.local_variable_set(:results, results)
        template_binding.local_variable_set(:summary, summary)
        template_binding
      end

      def create_basic_template_binding(results, metadata)
        # Use this instance's binding so the template has access to all methods
        template_binding = binding
        template_binding.local_variable_set(:results, results)
        template_binding.local_variable_set(:metadata, metadata)
        template_binding
      end

      # Fallback methods (original implementations)
      def format_analysis_text_fallback(results, summary)
        output = []

        # Header
        output << 'Git Metrics Analysis Report'
        output << '=' * 50
        output << ''

        # Summary
        if summary[:repository_info]
          repo_info = summary[:repository_info]
          output << "Repository: #{repo_info[:name]}"
          output << "Path: #{repo_info[:path]}"
          output << "Analyzed: #{repo_info[:analyzed_at]}"
          output << ''
        end

        # Show contributor filter information if active
        if summary[:contributor_filter]
          filter_info = summary[:contributor_filter]
          contributors_list = filter_info[:contributors].join(', ')
          output << "Filtered by Contributors: #{contributors_list} (#{filter_info[:count]} contributor#{if filter_info[:count] != 1
                                                                                                           's'
                                                                                                         end})"
          output << ''
        end

        output << "Total Metrics: #{summary[:total_metrics] || 0}"
        output << "Execution Time: #{format_execution_time(summary[:execution_time])}"
        output << "Data Coverage: #{summary[:data_coverage] || 0}%"
        output << ''

        # Results by category
        categories = group_analysis_results(results)

        categories.each do |category, metrics|
          output << category.to_s.upcase.gsub('_', ' ')
          output << '-' * 40

          metrics.each do |metric_name, data|
            metric_result = data[:metric]
            output << "  #{metric_name}:"
            output << '    Status: ✅ Success'
            data_points_count = metric_result.metadata[:data_points] || 0
            data_points_label = metric_result.metadata[:data_points_label] || 'records'
            output << "    Data Points: #{data_points_count} #{data_points_label}"
            output << "    Value: #{format_metric_value(metric_result.value)}"
            output << ''
          end

          output << ''
        end

        output.join("\n")
      end

      def format_text_fallback(results, metadata)
        output = []

        # Header
        output << 'Developer Metrics Report'
        output << '=' * 50
        output << ''

        # Metadata
        output << "Repository: #{metadata[:repository]}" if metadata[:repository]
        output << "Time Period: #{metadata[:time_period]}" if metadata[:time_period]
        output << "Generated: #{metadata[:generated_at]}" if metadata[:generated_at]
        output << ''

        # Results by category
        grouped_results = group_results_by_category(results)

        grouped_results.each do |category, category_results|
          output << category.upcase.gsub('_', ' ')
          output << '-' * 30

          category_results.each do |result|
            output << if result.success?
                        "  #{result.metric_name}: #{format_value(result.value)}"
                      else
                        "  #{result.metric_name}: ERROR - #{result.error}"
                      end
          end

          output << ''
        end

        output.join("\n")
      end

      # Helper methods for detailed HTML template rendering
      def render_metric_details(metric_name, value)
        return '<div class="metric-detail">No data available</div>' unless value

        case metric_name.to_s
        when 'commit_frequency'
          render_commit_frequency_details(value)
        when 'commit_size'
          render_commit_size_details(value)
        when 'commits_per_developer'
          render_commits_per_developer_details(value)
        when 'lines_changed'
          render_lines_changed_details(value)
        when 'file_churn'
          render_file_churn_details(value)
        when 'file_ownership'
          render_file_ownership_details(value)
        when 'authors_per_file'
          render_authors_per_file_details(value)
        when 'co_change_pairs'
          render_co_change_pairs_details(value)
        when 'revert_rate'
          render_revert_rate_details(value)
        when 'bugfix_ratio'
          render_bugfix_ratio_details(value)
        when 'large_commits'
          render_large_commits_details(value)
        when 'lead_time'
          render_lead_time_details(value)
        when 'deployment_frequency'
          render_deployment_frequency_details(value)
        else
          render_generic_details(value)
        end
      end

      def render_metadata_details(metadata)
        return '' unless metadata

        html = '<div class="metric-details">'

        # Skip basic fields already shown elsewhere
        skip_keys = %i[data_points data_points_label computed_at execution_time]

        metadata.each do |key, value|
          next if skip_keys.include?(key)

          html << '<div class="metric-detail">'
          html << "<strong>#{key.to_s.humanize}:</strong> "
          html << format_metadata_value(value)
          html << '</div>'
        end

        html << '</div>'
        html
      end

      private

      def render_commit_frequency_details(value)
        html = '<div class="nested-data">'

        if value[:commits_per_day]
          html << '<h5>Daily Activity</h5>'
          html << '<div class="metric-details">'
          html << "<div class=\"metric-detail\"><strong>Average per day:</strong> <span class=\"count\">#{value[:commits_per_day][:average]}</span></div>"
          html << "<div class=\"metric-detail\"><strong>Max in a day:</strong> <span class=\"count\">#{value[:commits_per_day][:max]}</span></div>"
          html << "<div class=\"metric-detail\"><strong>Total commits:</strong> <span class=\"count\">#{value[:total_commits]}</span></div>"
          html << '</div>'
        end

        if value[:commits_per_hour] && value[:commits_per_hour].any?
          html << '<h5>Hourly Distribution</h5>'
          html << '<div class="metric-details">'
          value[:commits_per_hour].each do |hour, count|
            html << "<div class=\"metric-detail\"><strong>#{hour}:00:</strong> <span class=\"count\">#{count} commits</span></div>"
          end
          html << '</div>'
        end

        if value[:working_hours_commits]
          html << '<h5>Work Pattern</h5>'
          html << '<div class="metric-details">'
          html << "<div class=\"metric-detail\"><strong>Working hours:</strong> <span class=\"percentage\">#{value[:working_hours_commits][:working_hours_percentage]}%</span> (<span class=\"count\">#{value[:working_hours_commits][:working_hours]} commits</span>)</div>"
          html << "<div class=\"metric-detail\"><strong>Off hours:</strong> <span class=\"percentage\">#{value[:working_hours_commits][:off_hours_percentage]}%</span> (<span class=\"count\">#{value[:working_hours_commits][:off_hours]} commits</span>)</div>"
          html << '</div>'
        end

        html << '</div>'
        html
      end

      def render_generic_details(value)
        html = '<div class="nested-data">'

        case value
        when Hash
          html << '<div class="metric-details">'
          value.each do |key, val|
            html << '<div class="metric-detail">'
            html << "<strong>#{key.to_s.humanize}:</strong> #{format_generic_value(val)}"
            html << '</div>'
          end
          html << '</div>'
        when Array
          html << "<div class=\"metric-detail\"><strong>Items:</strong> <span class=\"count\">#{value.length}</span></div>"
        else
          html << "<div class=\"metric-detail\">#{format_generic_value(value)}</div>"
        end

        html << '</div>'
        html
      end

      def render_large_commits_details(value)
        html = '<div class="nested-data">'

        if value[:overall]
          html << '<h5>Overall Statistics</h5>'
          html << '<div class="metric-details">'
          html << "<div class=\"metric-detail\"><strong>Total commits:</strong> <span class=\"count\">#{value[:overall][:total_commits]}</span></div>"
          html << "<div class=\"metric-detail\"><strong>Large commits:</strong> <span class=\"count\">#{value[:overall][:large_commits]}</span> (<span class=\"percentage\">#{value[:overall][:large_commit_ratio]}%</span>)</div>"
          html << "<div class=\"metric-detail\"><strong>Huge commits:</strong> <span class=\"count\">#{value[:overall][:huge_commits]}</span> (<span class=\"percentage\">#{value[:overall][:huge_commit_ratio]}%</span>)</div>"
          html << "<div class=\"metric-detail\"><strong>Risk score:</strong> <span class=\"#{value[:overall][:risk_score] > 30 ? 'risk-high' : 'percentage'}\">#{value[:overall][:risk_score]}</span></div>"
          html << '</div>'
        end

        if value[:thresholds]
          html << '<h5>Size Thresholds</h5>'
          html << '<div class="metric-details">'
          value[:thresholds].each do |size, threshold|
            html << "<div class=\"metric-detail\"><strong>#{size.to_s.capitalize}:</strong> <span class=\"count\">#{threshold} lines</span></div>"
          end
          html << '</div>'
        end

        if value[:largest_commits] && value[:largest_commits].any?
          html << '<h5>Largest Commits</h5>'
          html << '<table class="data-table">'
          html << '<tr><th>Date</th><th>Author</th><th>Size</th><th>Message</th></tr>'
          value[:largest_commits].first(5).each do |commit|
            html << '<tr>'
            html << "<td>#{commit[:date].to_s.split(' ').first}</td>"
            html << "<td>#{commit[:author_name]}</td>"
            html << "<td><span class=\"count\">#{commit[:calculated_size]} lines</span></td>"
            html << "<td>#{truncate_text(commit[:subject], 50)}</td>"
            html << '</tr>'
          end
          html << '</table>'
        end

        html << '</div>'
        html
      end

      def render_bugfix_ratio_details(value)
        html = '<div class="nested-data">'

        if value[:overall]
          html << '<h5>Commit Classification</h5>'
          html << '<div class="metric-details">'
          html << "<div class=\"metric-detail\"><strong>Total commits:</strong> <span class=\"count\">#{value[:overall][:total_commits]}</span></div>"
          html << "<div class=\"metric-detail\"><strong>Bugfix commits:</strong> <span class=\"count\">#{value[:overall][:bugfix_commits]}</span> (<span class=\"percentage\">#{value[:overall][:bugfix_ratio]}%</span>)</div>"
          html << "<div class=\"metric-detail\"><strong>Feature commits:</strong> <span class=\"count\">#{value[:overall][:feature_commits]}</span> (<span class=\"percentage\">#{value[:overall][:feature_ratio]}%</span>)</div>"
          html << "<div class=\"metric-detail\"><strong>Quality score:</strong> <span class=\"percentage\">#{value[:overall][:quality_score]}</span></div>"
          html << '</div>'
        end

        html << '</div>'
        html
      end

      def format_metadata_value(value)
        case value
        when Hash
          if value.keys.length <= 3
            value.map { |k, v| "#{k}: #{v}" }.join(', ')
          else
            "#{value.keys.length} items"
          end
        when Array
          if value.length <= 3
            value.join(', ')
          else
            "#{value.length} items"
          end
        when Numeric
          value.is_a?(Float) ? format('%.2f', value) : value.to_s
        else
          value.to_s
        end
      end

      def format_generic_value(value)
        case value
        when Float
          format('%.2f', value)
        when Hash
          "#{value.keys.length} items"
        when Array
          "#{value.length} items"
        else
          value.to_s
        end
      end

      def truncate_text(text, length)
        return text unless text

        text.length > length ? "#{text[0...length]}..." : text
      end

      def format_html_fallback(results, metadata)
        html = []
        html << '<!DOCTYPE html>'
        html << '<html><head><title>Developer Metrics Report</title>'
        html << '<style>'
        html << 'body { font-family: Arial, sans-serif; margin: 40px; }'
        html << 'h1 { color: #333; border-bottom: 2px solid #ddd; }'
        html << 'h2 { color: #666; margin-top: 30px; }'
        html << '.metric { margin: 10px 0; padding: 10px; background: #f5f5f5; }'
        html << '.success { border-left: 4px solid #4CAF50; }'
        html << '.error { border-left: 4px solid #f44336; }'
        html << '.metadata { background: #e3f2fd; padding: 15px; margin-bottom: 20px; }'
        html << '</style></head><body>'

        html << '<h1>Developer Metrics Report</h1>'

        # Metadata section
        if metadata.any?
          html << "<div class='metadata'>"
          html << '<h3>Report Information</h3>'
          metadata.each do |key, value|
            html << "<p><strong>#{key.to_s.capitalize}:</strong> #{value}</p>"
          end
          html << '</div>'
        end

        # Results by category
        grouped_results = group_results_by_category(results)

        grouped_results.each do |category, category_results|
          html << "<h2>#{category.upcase.gsub('_', ' ')}</h2>"

          category_results.each do |result|
            css_class = result.success? ? 'metric success' : 'metric error'
            html << "<div class='#{css_class}'>"
            html << "<strong>#{result.metric_name}:</strong> "

            html << if result.success?
                      format_value(result.value)
                    else
                      "ERROR - #{result.error}"
                    end

            html << '</div>'
          end
        end

        html << '</body></html>'
        html.join("\n")
      end

      # String humanization helper
      def humanize_string(str)
        str.to_s.gsub(/[_-]/, ' ').split(' ').map(&:capitalize).join(' ')
      end

      # Add missing render methods for other metrics
      %w[commit_size commits_per_developer lines_changed file_churn file_ownership
         authors_per_file co_change_pairs revert_rate lead_time deployment_frequency].each do |metric|
        define_method("render_#{metric}_details") do |value|
          render_generic_details(value)
        end
      end
    end
  end
end

# String extension for humanization
class String
  def humanize
    gsub(/[_-]/, ' ').split(' ').map(&:capitalize).join(' ')
  end

  def titleize
    gsub(/[_-]/, ' ').split(' ').map(&:capitalize).join(' ')
  end
end
