# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Builder for results sections with extracted formatting logic
        class ResultsBuilder
          def self.build_analysis(results)
            new(results).build_analysis
          end

          def initialize(results)
            @results = results
          end

          def build_analysis
            output = []
            categories = group_analysis_results

            categories.each do |category, metrics|
              add_category_header(output, category, 40)
              add_analysis_metrics(output, metrics)
              add_blank_line(output)
            end

            output
          end

          private

          attr_reader :results

          def add_category_header(output, category, separator_length)
            output << category.to_s.upcase.gsub('_', ' ')
            output << ('-' * separator_length)
          end

          def add_analysis_metrics(output, metrics)
            metrics.each do |metric_name, data|
              output.concat(format_analysis_metric(metric_name, data))
            end
          end

          def format_analysis_metric(metric_name, data)
            metric_result = data[:metric]
            data_points = extract_data_points(metric_result)

            [
              "  #{metric_name}:",
              '    Status: ✅ Success',
              "    Data Points: #{data_points[:count]} #{data_points[:label]}",
              "    Value: #{Utils::ValueFormatter.format_metric_value(metric_result.value)}",
              '',
            ]
          end

          def extract_data_points(metric_result)
            {
              count: metric_result.metadata[:data_points] || 0,
              label: metric_result.metadata[:data_points_label] || 'records',
            }
          end

          def group_analysis_results
            results.group_by { |_, data| data[:metadata][:category] }
          end

          def add_blank_line(output)
            output << ''
          end
        end
      end
    end
  end
end
