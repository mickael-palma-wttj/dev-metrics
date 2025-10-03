require 'json'

module DevMetrics
  module CLI
    # Handles formatting and output of metric results
    class OutputFormatter
      FORMATS = %w[text json csv html].freeze

      attr_reader :format, :output_file

      def initialize(format = 'text', output_file = nil)
        @format = format.to_s.downcase
        @output_file = output_file

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
        # Similar to existing HTML format but adapted for analysis results
        format_html([], summary.merge(results: results))
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
    end
  end
end
