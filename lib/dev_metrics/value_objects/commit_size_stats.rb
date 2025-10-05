# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing commit size statistics
    class CommitSizeStats
      attr_reader :total_commits, :average_size, :median_size, :min_size, :max_size, :distribution

      def initialize(total_commits:, average_size:, median_size:, min_size:, max_size:, distribution:)
        @total_commits = total_commits
        @average_size = average_size
        @median_size = median_size
        @min_size = min_size
        @max_size = max_size
        @distribution = distribution
        freeze
      end

      def size_range
        max_size - min_size
      end

      def large_commit_ratio
        return 0.0 if total_commits.zero?

        ((distribution.large_commits + distribution.huge_commits).to_f / total_commits * 100).round(1)
      end

      def average_above_median?
        average_size > median_size
      end

      def high_variance?
        size_range > (average_size * 3)
      end

      def to_h
        {
          total_commits: total_commits,
          average_size: average_size,
          median_size: median_size,
          min_size: min_size,
          max_size: max_size,
          small_commits: distribution.small_commits,
          medium_commits: distribution.medium_commits,
          large_commits: distribution.large_commits,
          huge_commits: distribution.huge_commits,
          distribution_percentages: distribution.to_h,
        }
      end
    end
  end
end
