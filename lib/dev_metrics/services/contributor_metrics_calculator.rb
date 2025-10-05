# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating contributor statistics and metrics
    # Follows Single Responsibility Principle - only handles statistical calculations
    class ContributorMetricsCalculator
      def initialize(contributors)
        @contributors = contributors
      end

      def calculate
        ValueObjects::ContributorStats.new(
          contributors: sorted_contributors,
          total_contributors: contributors.size,
          total_commits: calculate_total_commits,
          avg_commits_per_contributor: calculate_average_commits,
          top_contributor: find_top_contributor
        )
      end

      private

      attr_reader :contributors

      def sorted_contributors
        Services::ContributorSorter.new(contributors).sort_by_commits_desc
      end

      def calculate_total_commits
        contributors.sum(&:commit_count)
      end

      def calculate_average_commits
        return 0.0 if contributors.empty?

        (calculate_total_commits.to_f / contributors.size).round(2)
      end

      def find_top_contributor
        return nil if contributors.empty?

        contributors.max_by(&:commit_count)&.name
      end
    end
  end
end
