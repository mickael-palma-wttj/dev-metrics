# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating hourly commit distribution
    # Follows Single Responsibility Principle - only handles hourly calculations
    class HourlyCommitCalculator
      HOURS_IN_DAY = (0..23)

      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        hourly_counts = build_hourly_distribution
        ValueObjects::HourlyCommitStats.new(hourly_counts)
      end

      private

      attr_reader :commits_data

      def build_hourly_distribution
        distribution = initialize_all_hours
        populate_commit_counts(distribution)
        distribution
      end

      def initialize_all_hours
        HOURS_IN_DAY.each_with_object({}) { |hour, hash| hash[hour] = 0 }
      end

      def populate_commit_counts(distribution)
        commits_data.each do |commit|
          hour = commit[:date].hour
          distribution[hour] += 1
        end
      end
    end
  end
end
