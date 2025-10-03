# frozen_string_literal: true

module DevMetrics
  module Services
    # Service class for calculating deployment frequency metrics
    class FrequencyCalculator
      def initialize(deployments, time_period)
        @deployments = deployments
        @time_period = time_period
      end

      def calculate_frequency_metrics
        return default_frequency_metrics if deployments.empty?

        deployment_dates = deployments.map { |d| d[:date] }.sort
        total_deployments = deployment_dates.size

        # Calculate intervals between deployments
        intervals = calculate_deployment_intervals(deployment_dates)

        # Period metrics
        period_start = time_period.start_date
        period_end = time_period.end_date
        period_days = (period_end - period_start).to_i + 1
        period_weeks = period_days / 7.0

        deployments_per_week = (total_deployments / period_weeks).round(2)
        avg_days_between = intervals.empty? ? 0 : (intervals.sum / intervals.size).round(2)

        last_deployment_time = deployment_dates.last
        days_since_last = calculate_days_since_last(last_deployment_time)

        {
          total_deployments: total_deployments,
          deployments_per_week: deployments_per_week,
          avg_days_between_deployments: avg_days_between,
          days_since_last_deployment: days_since_last,
          frequency_category: categorize_frequency(deployments_per_week),
          period_days: period_days,
          deployment_intervals: intervals.first(10),
        }
      end

      private

      attr_reader :deployments, :time_period

      def calculate_deployment_intervals(sorted_dates)
        return [] if sorted_dates.size < 2

        intervals = []
        (1...sorted_dates.size).each do |i|
          interval_days = (sorted_dates[i] - sorted_dates[i - 1]).to_i
          intervals << interval_days
        end
        intervals
      end

      def default_frequency_metrics
        {
          total_deployments: 0,
          deployments_per_week: 0.0,
          avg_days_between_deployments: 0.0,
          days_since_last_deployment: 0,
          frequency_category: 'unknown',
          period_days: 0,
          deployment_intervals: [],
        }
      end

      def calculate_days_since_last(last_deployment_time)
        return 0 unless last_deployment_time

        (Time.now - last_deployment_time).to_i / (24 * 60 * 60)
      end

      def categorize_frequency(deployments_per_week)
        case deployments_per_week
        when 0...0.14 # Less than once every two weeks
          'low'
        when 0.14...0.5 # Once every 2-7 days
          'moderate'
        when 0.5...2 # Several times per week
          'high'
        else # Multiple per day
          'very_high'
        end
      end
    end
  end
end
