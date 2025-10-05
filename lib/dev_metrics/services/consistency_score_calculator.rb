# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating consistency score
    # Follows Single Responsibility Principle - only handles consistency calculations
    class ConsistencyScoreCalculator
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        return 0 if commits_data.empty?

        daily_counts = get_daily_commit_counts
        return 100 if daily_counts.size <= 1

        coefficient_of_variation = calculate_coefficient_of_variation(daily_counts)
        convert_to_consistency_score(coefficient_of_variation)
      end

      private

      attr_reader :commits_data

      def get_daily_commit_counts
        commits_data.group_by { |commit| commit[:date].strftime('%Y-%m-%d') }
          .transform_values(&:count)
          .values
      end

      def calculate_coefficient_of_variation(values)
        mean = calculate_mean(values)
        return 0 if mean.zero?

        variance = calculate_variance(values, mean)
        standard_deviation = Math.sqrt(variance)

        standard_deviation / mean
      end

      def calculate_mean(values)
        values.sum.to_f / values.size
      end

      def calculate_variance(values, mean)
        values.map { |value| (value - mean)**2 }.sum / values.size
      end

      def convert_to_consistency_score(coefficient_of_variation)
        # Convert to 0-100 scale where lower CV = higher consistency
        consistency = [100 - (coefficient_of_variation * 50), 0].max
        consistency.round(1)
      end
    end
  end
end
