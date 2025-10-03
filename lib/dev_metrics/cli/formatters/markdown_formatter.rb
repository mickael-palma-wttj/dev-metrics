# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      class MarkdownFormatter < Base
        def format_results(results, metadata)
          template_name = 'basic_report.markdown'
          render_template_or_fallback(template_name, { results: results, metadata: metadata }) do
            # Fallback to text format if no markdown template
            Formatters::TextFormatter.new(template_renderer).format_results(results, metadata)
          end
        end

        def format_analysis_results(results, summary)
          template_name = 'analysis_report.markdown'
          render_template_or_fallback(template_name, { results: results, summary: summary }) do
            # Fallback to text format if no markdown template
            Formatters::TextFormatter.new(template_renderer).format_analysis_results(results, summary)
          end
        end
      end
    end
  end
end
