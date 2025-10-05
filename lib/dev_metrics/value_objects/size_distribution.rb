# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing commit size distribution categories
    class SizeDistribution
      SMALL_THRESHOLD = 10
      MEDIUM_THRESHOLD = 100
      LARGE_THRESHOLD = 500

      attr_reader :small_commits, :medium_commits, :large_commits, :huge_commits, :total_commits

      def initialize(small_commits:, medium_commits:, large_commits:, huge_commits:, total_commits:)
        @small_commits = small_commits
        @medium_commits = medium_commits
        @large_commits = large_commits
        @huge_commits = huge_commits
        @total_commits = total_commits
        freeze
      end

      def small_percentage
        return 0.0 if total_commits.zero?

        ((small_commits.to_f / total_commits) * 100).round(1)
      end

      def medium_percentage
        return 0.0 if total_commits.zero?

        ((medium_commits.to_f / total_commits) * 100).round(1)
      end

      def large_percentage
        return 0.0 if total_commits.zero?

        ((large_commits.to_f / total_commits) * 100).round(1)
      end

      def huge_percentage
        return 0.0 if total_commits.zero?

        ((huge_commits.to_f / total_commits) * 100).round(1)
      end

      def mostly_small_commits?
        small_percentage > 60
      end

      def balanced_distribution?
        percentages = [small_percentage, medium_percentage, large_percentage, huge_percentage]
        percentages.none? { |p| p > 70 }
      end

      def to_h
        {
          small_commits: small_commits,
          medium_commits: medium_commits,
          large_commits: large_commits,
          huge_commits: huge_commits,
          small_percent: small_percentage,
          medium_percent: medium_percentage,
          large_percent: large_percentage,
          huge_percent: huge_percentage,
        }
      end
    end
  end
end
