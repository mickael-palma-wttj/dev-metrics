# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      class MarkdownFormatter < Base
        def format_analysis_results(results, summary)
          template_name = 'analysis_report.markdown'
          render_template_or_fallback(template_name, { results: results, summary: summary }) do
            # Fallback to text format if no markdown template
            Formatters::TextFormatter.new(template_renderer).format_analysis_results(results, summary)
          end
        end

        # Template helper methods
        def group_analysis_results(results)
          results.group_by { |_, data| data[:metadata][:category] }
        end

        def format_metric_value(value)
          Utils::ValueFormatter.format_metric_value(value)
        end
      end
    end
  end
end
