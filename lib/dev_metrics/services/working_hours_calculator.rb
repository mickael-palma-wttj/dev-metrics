# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating working hours statistics
    # Follows Single Responsibility Principle - only handles working hours analysis
    class WorkingHoursCalculator
      include Utils::TimeHelper

      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        working_hours_count = count_working_hours_commits
        off_hours_count = commits_data.size - working_hours_count

        ValueObjects::WorkingHoursStats.new(
          working_hours: working_hours_count,
          off_hours: off_hours_count,
          working_hours_percentage: calculate_percentage(working_hours_count),
          off_hours_percentage: calculate_percentage(off_hours_count)
        )
      end

      private

      attr_reader :commits_data

      def count_working_hours_commits
        commits_data.count { |commit| working_hours?(commit[:date]) }
      end

      def calculate_percentage(count)
        return 0.0 if commits_data.empty?

        (count.to_f / commits_data.size * 100).round(1)
      end
    end
  end
end
