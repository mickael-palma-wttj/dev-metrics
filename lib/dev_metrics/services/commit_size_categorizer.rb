# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for categorizing commits by size
    # Follows Single Responsibility Principle - only handles size categorization
    class CommitSizeCategorizer
      SMALL_THRESHOLD = 10
      MEDIUM_THRESHOLD = 100
      LARGE_THRESHOLD = 500

      def initialize(sizes)
        @sizes = sizes
      end

      def categorize
        ValueObjects::SizeDistribution.new(
          small_commits: count_small_commits,
          medium_commits: count_medium_commits,
          large_commits: count_large_commits,
          huge_commits: count_huge_commits,
          total_commits: sizes.size
        )
      end

      private

      attr_reader :sizes

      def count_small_commits
        sizes.count { |size| size <= SMALL_THRESHOLD }
      end

      def count_medium_commits
        sizes.count { |size| size > SMALL_THRESHOLD && size <= MEDIUM_THRESHOLD }
      end

      def count_large_commits
        sizes.count { |size| size > MEDIUM_THRESHOLD && size <= LARGE_THRESHOLD }
      end

      def count_huge_commits
        sizes.count { |size| size > LARGE_THRESHOLD }
      end
    end
  end
end
