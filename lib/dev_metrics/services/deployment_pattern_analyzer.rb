# frozen_string_literal: true

module DevMetrics
  module Services
    # Service class for analyzing deployment patterns and trends
    class DeploymentPatternAnalyzer
      def initialize(deployments)
        @deployments = deployments
      end

      def analyze_deployment_patterns
        return {} if deployments.empty?

        deployment_dates = deployments.map { |d| d[:date] }

        {
          by_day_of_week: analyze_by_day_of_week(deployment_dates),
          by_hour: analyze_by_hour(deployment_dates),
          by_month: analyze_by_month(deployment_dates),
          working_hours_ratio: calculate_working_hours_ratio_from_dates(deployment_dates),
          weekday_ratio: calculate_weekday_ratio_from_dates(deployment_dates),
        }
      end

      def analyze_frequency_trends
        return {} if deployments.empty?

        # Split deployments into two halves for trend analysis
        mid_point = deployments.size / 2
        return {} if mid_point < 2

        first_half = deployments[mid_point..] # Earlier deployments
        second_half = deployments[0...mid_point] # Recent deployments

        first_avg = calculate_average_interval(first_half)
        second_avg = calculate_average_interval(second_half)

        {
          first_half_avg_days: first_avg.round(2),
          second_half_avg_days: second_avg.round(2),
          trend_direction: calculate_trend_direction(first_avg, second_avg),
          improvement_factor: first_avg.positive? ? (first_avg / [second_avg, 0.1].max).round(2) : 1.0,
        }
      end

      private

      attr_reader :deployments

      def analyze_by_day_of_week(dates)
        counts = Hash.new(0)
        dates.each { |date| counts[date.strftime('%A')] += 1 }
        counts
      end

      def analyze_by_hour(dates)
        counts = Hash.new(0)
        dates.each { |date| counts[date.hour] += 1 }
        counts
      end

      def analyze_by_month(dates)
        counts = Hash.new(0)
        dates.each { |date| counts[date.strftime('%Y-%m')] += 1 }
        counts
      end

      def calculate_working_hours_ratio_from_dates(dates)
        return 0.0 if dates.empty?

        working_hours_count = dates.count { |date| (9..17).include?(date.hour) }
        (working_hours_count.to_f / dates.size).round(3)
      end

      def calculate_weekday_ratio_from_dates(dates)
        return 0.0 if dates.empty?

        weekday_count = dates.count { |date| (1..5).include?(date.wday) }
        (weekday_count.to_f / dates.size).round(3)
      end

      def calculate_average_interval(deployment_subset)
        return 0.0 if deployment_subset.size < 2

        dates = deployment_subset.map { |d| d[:date] }.sort
        intervals = []

        (1...dates.size).each do |i|
          interval_days = (dates[i] - dates[i - 1]).to_i
          intervals << interval_days
        end

        intervals.empty? ? 0.0 : intervals.sum.to_f / intervals.size
      end

      def calculate_trend_direction(first_avg, second_avg)
        return 'stable' if first_avg.zero? && second_avg.zero?
        return 'improving' if first_avg > second_avg * 1.2
        return 'declining' if second_avg > first_avg * 1.2

        'stable'
      end
    end
  end
end
