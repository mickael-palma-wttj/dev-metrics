# frozen_string_literal: true

require 'csv'

module DevMetrics
  module CLI
    module Formatters
      class CsvFormatter < Base
        def format_results(results, _metadata)
          CSV.generate do |csv|
            csv << csv_headers_for_results
            results.each { |result| csv << csv_row_for_result(result) }
          end
        end

        def format_analysis_results(results, _summary)
          CSV.generate do |csv|
            csv << csv_headers_for_analysis
            results.each { |metric_name, data| csv << csv_row_for_analysis(metric_name, data) }
          end
        end

        private

        def csv_headers_for_results
          %w[metric_name value repository status error]
        end

        def csv_headers_for_analysis
          %w[category metric_name value data_points execution_time]
        end

        def csv_row_for_result(result)
          [
            result.metric_name,
            result.value,
            result.repository,
            result.success? ? 'success' : 'failed',
            result.error,
          ]
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
