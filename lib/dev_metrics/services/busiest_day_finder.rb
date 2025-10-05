# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for finding the busiest day
    # Follows Single Responsibility Principle - only handles busiest day detection
    class BusiestDayFinder
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def find
        return nil if commits_data.empty?

        daily_counts = group_commits_by_date
        busiest_date_info = daily_counts.max_by { |_, count| count }

        return nil unless busiest_date_info

        ValueObjects::BusiestDay.new(
          date: busiest_date_info[0],
          commits: busiest_date_info[1]
        )
      end

      private

      attr_reader :commits_data

      def group_commits_by_date
        commits_data.group_by { |commit| commit[:date].strftime('%Y-%m-%d') }
          .transform_values(&:count)
      end
    end
  end
end
