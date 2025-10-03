module DevMetrics
  module CLI
    module Formatters
      class HtmlFormatter < Base
        def format_results(results, metadata)
          template_name = 'basic_report.html'
          render_template_or_fallback(template_name, { results: results, metadata: metadata }) do
            format_html_fallback(results, metadata)
          end
        end

        def format_analysis_results(results, summary)
          template_name = 'analysis_report.html'
          render_template_or_fallback(template_name, { results: results, summary: summary }) do
            # Fallback to existing HTML format
            format_results([], summary.merge(results: results))
          end
        end

        # Methods that can be called from ERB templates
        def render_metric_details(metric_name, value)
          return '<div class="metric-detail">No data available</div>' unless value

          renderer_class = metric_renderer_class(metric_name)
          renderer_class.new(value).render
        end

        def render_metadata_details(metadata)
          return '' unless metadata

          html = '<div class="metric-details">'
          skip_keys = %i[data_points data_points_label computed_at execution_time]

          metadata.each do |key, value|
            next if skip_keys.include?(key)

            html << '<div class="metric-detail">'
            html << "<strong>#{DevMetrics::Utils::StringUtils.humanize(key.to_s)}:</strong> "
            html << ValueFormatter.format_metadata_value(value)
            html << '</div>'
          end

          html << '</div>'
          html
        end

        def group_results_by_category(results)
          Services::ResultGrouper.new(results).group_by_category
        end

        def format_value(value)
          ValueFormatter.format_generic_value(value)
        end

        def format_execution_time(time_seconds)
          DevMetrics::Utils::StringUtils.format_execution_time(time_seconds)
        end

        def humanize_string(str)
          DevMetrics::Utils::StringUtils.humanize(str)
        end

        def truncate_text(text, length)
          DevMetrics::Utils::StringUtils.truncate(text, length)
        end

        def group_analysis_results(results)
          results.group_by { |_, data| data[:metadata][:category] }
        end

        def format_metric_value(value)
          ValueFormatter.format_metric_value(value)
        end

        private

        def metric_renderer_class(metric_name)
          case metric_name.to_s
          when 'commit_frequency'
            HtmlRenderers::CommitFrequencyRenderer
          when 'large_commits'
            HtmlRenderers::LargeCommitsRenderer
          when 'bugfix_ratio'
            HtmlRenderers::BugfixRatioRenderer
          else
            HtmlRenderers::GenericRenderer
          end
        end

        def format_html_fallback(results, metadata)
          html = build_html_document_start
          html.concat(build_html_body(results, metadata))
          html << '</body></html>'
          html.join("\n")
        end

        def build_html_document_start
          [
            '<!DOCTYPE html>',
            '<html><head><title>Developer Metrics Report</title>',
            build_css_styles,
            '</head><body>',
            '<h1>Developer Metrics Report</h1>'
          ]
        end

        def build_css_styles
          [
            '<style>',
            'body { font-family: Arial, sans-serif; margin: 40px; }',
            'h1 { color: #333; border-bottom: 2px solid #ddd; }',
            'h2 { color: #666; margin-top: 30px; }',
            '.metric { margin: 10px 0; padding: 10px; background: #f5f5f5; }',
            '.success { border-left: 4px solid #4CAF50; }',
            '.error { border-left: 4px solid #f44336; }',
            '.metadata { background: #e3f2fd; padding: 15px; margin-bottom: 20px; }',
            '</style>'
          ].join("\n")
        end

        def build_html_body(results, metadata)
          html = []
          html.concat(build_metadata_section(metadata)) if metadata.any?
          html.concat(build_results_sections(results))
          html
        end

        def build_metadata_section(metadata)
          html = ["<div class='metadata'>", '<h3>Report Information</h3>']
          metadata.each do |key, value|
            html << "<p><strong>#{key.to_s.capitalize}:</strong> #{value}</p>"
          end
          html << '</div>'
          html
        end

        def build_results_sections(results)
          html = []
          grouped_results = group_results_by_category(results)

          grouped_results.each do |category, category_results|
            html << "<h2>#{category.upcase.gsub('_', ' ')}</h2>"
            html.concat(build_category_results(category_results))
          end

          html
        end

        def build_category_results(category_results)
          category_results.map do |result|
            css_class = result.success? ? 'metric success' : 'metric error'
            content = if result.success?
                        format_value(result.value)
                      else
                        "ERROR - #{result.error}"
                      end

            "<div class='#{css_class}'><strong>#{result.metric_name}:</strong> #{content}</div>"
          end
        end
      end
    end
  end
end
