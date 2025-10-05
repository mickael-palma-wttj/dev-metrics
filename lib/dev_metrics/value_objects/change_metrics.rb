# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing overall change metrics for the repository
    class ChangeMetrics
      attr_reader :author_stats, :total_additions, :total_deletions, :contributing_authors

      def initialize(author_stats:, total_additions:, total_deletions:, contributing_authors:)
        @author_stats = author_stats.freeze
        @total_additions = total_additions
        @total_deletions = total_deletions
        @contributing_authors = contributing_authors
        freeze
      end

      def net_additions
        total_additions - total_deletions
      end

      def total_changes
        total_additions + total_deletions
      end

      def overall_churn_ratio
        return 0.0 if total_changes.zero?

        (total_deletions.to_f / total_changes * 100).round(1)
      end

      def avg_changes_per_author
        return 0.0 if contributing_authors.zero?

        (total_changes.to_f / contributing_authors).round(2)
      end

      def net_positive_repository?
        net_additions.positive?
      end

      def high_churn_repository?
        overall_churn_ratio > 40
      end

      def top_contributor
        author_stats.max_by(&:total_changes)
      end

      def most_productive_contributors
        author_stats.select(&:productive_contributor?)
      end

      def high_churn_contributors
        author_stats.select(&:high_churn?)
      end

      def to_h
        result = {}
        author_stats.each do |author_stat|
          result[author_stat.display_name] = author_stat.to_h
        end
        result
      end

      def metadata_hash
        {
          total_additions: total_additions,
          total_deletions: total_deletions,
          net_additions: net_additions,
          total_changes: total_changes,
          overall_churn_ratio: overall_churn_ratio,
          contributing_authors: contributing_authors,
          avg_changes_per_author: avg_changes_per_author,
        }
      end
    end
  end
end
