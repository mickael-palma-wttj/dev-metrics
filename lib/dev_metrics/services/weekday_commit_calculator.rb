# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating weekday commit distribution
    # Follows Single Responsibility Principle - only handles weekday calculations
    class WeekdayCommitCalculator
      WEEKDAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        weekday_counts = Hash.new(0)

        commits_data.each do |commit|
          weekday_name = get_weekday_name(commit[:date])
          weekday_counts[weekday_name] += 1
        end

        weekday_counts
      end

      private

      attr_reader :commits_data

      def get_weekday_name(date)
        WEEKDAY_NAMES[date.wday]
      end
    end
  end
end
