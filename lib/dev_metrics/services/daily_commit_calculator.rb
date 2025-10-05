# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating daily commit statistics
    # Follows Single Responsibility Principle - only handles daily calculations
    class DailyCommitCalculator
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        daily_counts = group_commits_by_date

        ValueObjects::DailyCommitStats.new(
          by_date: daily_counts,
          average: calculate_average(daily_counts),
          max: daily_counts.values.max || 0,
          min: daily_counts.values.min || 0
        )
      end

      private

      attr_reader :commits_data

      def group_commits_by_date
        commits_data.group_by { |commit| format_date(commit[:date]) }
          .transform_values(&:count)
      end

      def format_date(date)
        date.strftime('%Y-%m-%d')
      end

      def calculate_average(daily_counts)
        return 0.0 if daily_counts.empty?

        (daily_counts.values.sum.to_f / daily_counts.size).round(2)
      end
    end
  end
end
