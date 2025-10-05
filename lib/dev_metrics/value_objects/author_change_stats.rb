# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing an author's change statistics
    class AuthorChangeStats
      attr_reader :author_name, :author_email, :additions, :deletions, :commits

      def initialize(author_name:, author_email:, additions: 0, deletions: 0, commits: 0)
        @author_name = author_name
        @author_email = author_email
        @additions = additions
        @deletions = deletions
        @commits = commits
        freeze
      end

      def display_name
        return formatted_name_with_email if email_present?

        author_name
      end

      def net_changes
        additions - deletions
      end

      def total_changes
        additions + deletions
      end

      def avg_changes_per_commit
        return 0.0 if commits.zero?

        (total_changes.to_f / commits).round(2)
      end

      def churn_ratio
        return 0.0 if total_changes.zero?

        (deletions.to_f / total_changes * 100).round(1)
      end

      def net_positive?
        net_changes.positive?
      end

      def net_negative?
        net_changes.negative?
      end

      def high_churn?
        churn_ratio > 50
      end

      def productive_contributor?
        commits > 10 && total_changes > 1000
      end

      def to_h
        {
          additions: additions,
          deletions: deletions,
          net_changes: net_changes,
          total_changes: total_changes,
          commits: commits,
          avg_changes_per_commit: avg_changes_per_commit,
          churn_ratio: churn_ratio,
        }
      end

      private

      def email_present?
        author_email && !author_email.empty?
      end

      def formatted_name_with_email
        "#{author_name} <#{author_email}>"
      end
    end
  end
end
