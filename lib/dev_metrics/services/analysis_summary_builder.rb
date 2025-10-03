# frozen_string_literal: true

require 'time'

module DevMetrics
  module Services
    # Service object responsible for building analysis summaries
    class AnalysisSummaryBuilder
      attr_reader :results, :repository

      def initialize(results, repository)
        @results = results
        @repository = repository
      end

      def build
        return {} if results.empty?

        {
          total_metrics: results.size,
          categories: build_categories_summary,
          execution_time: calculate_total_execution_time,
          data_coverage: calculate_data_coverage,
          repository_info: build_repository_info,
        }
      end

      private

      def build_categories_summary
        categories = results.group_by { |_, data| data[:metadata][:category] }
        categories.transform_values(&:size)
      end

      def calculate_total_execution_time
        return 0 if results.empty?

        results.values.sum { |data| data[:metadata][:execution_time] || 0 }
      end

      def calculate_data_coverage
        return 0 if results.empty?

        metrics_with_data = results.count do |_, data|
          (data[:metadata][:data_points] || 0).positive?
        end

        (metrics_with_data.to_f / results.size * 100).round(1)
      end

      def build_repository_info
        {
          name: repository.name,
          path: repository.path,
          analyzed_at: Time.now.iso8601,
        }
      end
    end
  end
end
