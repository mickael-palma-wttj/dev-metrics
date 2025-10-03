# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for generating result summaries
    class SummaryGenerator
      def self.generate(results)
        new(results).generate
      end

      def initialize(results)
        @results = results
      end

      def generate
        {
          total_metrics: @results.size,
          successful_metrics: count_successful,
          failed_metrics: count_failed,
          categories: extract_categories,
        }
      end

      private

      def count_successful
        @results.count(&:success?)
      end

      def count_failed
        @results.count(&:failed?)
      end

      def extract_categories
        ResultGrouper.new(@results).group_by_category.keys
      end
    end

    # Helper class for grouping results
    class ResultGrouper
      def initialize(results)
        @results = results
      end

      def group_by_category
        grouped = {}
        @results.each do |result|
          category = Services::CategoryInferencer.infer(result.metric_name)
          grouped[category] ||= []
          grouped[category] << result
        end
        grouped
      end

      def group_analysis_results(results)
        results.group_by { |_, data| data[:metadata][:category] }
      end
    end
  end
end
