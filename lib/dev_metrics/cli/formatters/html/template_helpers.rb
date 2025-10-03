# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Template helper methods extracted from HtmlFormatter
        class TemplateHelpers
          def self.format_value(value)
            Utils::ValueFormatter.format_generic_value(value)
          end

          def self.format_execution_time(time_seconds)
            Utils::StringUtils.format_execution_time(time_seconds)
          end

          def self.humanize_string(str)
            Utils::StringUtils.humanize(str)
          end

          def self.truncate_text(text, length)
            Utils::StringUtils.truncate(text, length)
          end

          def self.format_metric_value(value)
            Utils::ValueFormatter.format_metric_value(value)
          end

          def self.group_results_by_category(results)
            Services::ResultGrouper.new(results).group_by_category
          end

          def self.group_analysis_results(results)
            results.group_by { |_, data| data[:metadata][:category] }
          end
        end
      end
    end
  end
end
