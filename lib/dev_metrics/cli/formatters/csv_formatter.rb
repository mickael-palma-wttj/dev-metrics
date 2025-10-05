# frozen_string_literal: true

require 'csv'

module DevMetrics
  module CLI
    module Formatters
      class CsvFormatter < Base
        def format_analysis_results(results, _summary)
          CSV.generate do |csv|
            csv << csv_headers_for_analysis
            results.each { |metric_name, data| csv << csv_row_for_analysis(metric_name, data) }
          end
        end

        private

        def csv_headers_for_analysis
          %w[category metric_name value data_points execution_time]
        end

        def csv_row_for_analysis(metric_name, data)
          metric_result = data[:metric]
          [
            data[:metadata][:category],
            metric_name,
            Utils::ValueFormatter.format_metric_value(metric_result.value),
            metric_result.metadata[:data_points] || 0,
            data[:metadata][:execution_time] || 0,
          ]
        end
      end
    end
  end
end
