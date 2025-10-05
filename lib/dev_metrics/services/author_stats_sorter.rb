# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for sorting author statistics by various criteria
    class AuthorStatsSorter
      def initialize(change_metrics)
        @change_metrics = change_metrics
      end

      def sort_by_total_changes
        sorted_stats = @change_metrics.author_stats.sort_by(&:total_changes).reverse
        create_sorted_change_metrics(sorted_stats)
      end

      def sort_by_net_changes
        sorted_stats = @change_metrics.author_stats.sort_by(&:net_changes).reverse
        create_sorted_change_metrics(sorted_stats)
      end

      def sort_by_additions
        sorted_stats = @change_metrics.author_stats.sort_by(&:additions).reverse
        create_sorted_change_metrics(sorted_stats)
      end

      def sort_by_deletions
        sorted_stats = @change_metrics.author_stats.sort_by(&:deletions).reverse
        create_sorted_change_metrics(sorted_stats)
      end

      private

      def create_sorted_change_metrics(sorted_stats)
        ValueObjects::ChangeMetrics.new(
          author_stats: sorted_stats,
          total_additions: @change_metrics.total_additions,
          total_deletions: @change_metrics.total_deletions,
          contributing_authors: @change_metrics.contributing_authors
        )
      end
    end
  end
end
