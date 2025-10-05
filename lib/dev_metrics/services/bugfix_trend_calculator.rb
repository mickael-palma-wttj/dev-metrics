# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for calculating bugfix trend analysis
    class BugfixTrendCalculator
      def initialize(time_patterns)
        @time_patterns = time_patterns
      end

      def calculate_trend
        return 0 if invalid_data?

        monthly_data = time_patterns[:by_month]
        return 0 if insufficient_data?(monthly_data)

        calculate_trend_percentage(monthly_data)
      end

      private

      attr_reader :time_patterns

      def invalid_data?
        time_patterns.empty? || !time_patterns[:by_month]
      end

      def insufficient_data?(monthly_data)
        monthly_data.size < 2
      end

      def calculate_trend_percentage(monthly_data)
        months = monthly_data.keys.sort
        first_avg = calculate_period_average(months.first(months.size / 2), monthly_data)
        second_avg = calculate_period_average(months.last(months.size / 2), monthly_data)

        return 0 if first_avg.zero?

        ((second_avg - first_avg) / first_avg * 100).round(1)
      end

      def calculate_period_average(period_months, monthly_data)
        return 0.0 if period_months.empty?

        total = period_months.sum { |month| monthly_data[month] }
        total / period_months.size.to_f
      end
    end
  end
end
