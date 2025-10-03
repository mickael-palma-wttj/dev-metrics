# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      # Refactored TextFormatter following Sandi Metz rules and SOLID principles
      # Uses Strategy pattern for different report types
      class TextFormatter < Base
        def format_results(results, metadata)
          template_name = 'basic_report.text'
          render_template_or_fallback(template_name, { results: results, metadata: metadata }) do
            basic_report_strategy(results, metadata).build({})
          end
        end

        def format_analysis_results(results, summary)
          processed_summary = Services::ContributorFilterProcessor.process(summary)
          template_name = 'analysis_report.text'

          render_template_or_fallback(template_name, { results: results, summary: processed_summary }) do
            analysis_report_strategy(results, processed_summary).build({})
          end
        end

        private

        # Factory methods for creating strategies
        def basic_report_strategy(results, metadata)
          Text::BasicReportStrategy.new(results, metadata)
        end

        def analysis_report_strategy(results, summary)
          Text::AnalysisReportStrategy.new(results, summary)
        end

        # Template helper methods for backward compatibility
        def group_analysis_results(results)
          results.group_by { |_, data| data[:metadata][:category] }
        end

        def format_execution_time(execution_time)
          Utils::StringUtils.format_execution_time(execution_time)
        end

        def format_metric_value(value)
          Utils::ValueFormatter.format_metric_value(value)
        end
      end
    end
  end
end
