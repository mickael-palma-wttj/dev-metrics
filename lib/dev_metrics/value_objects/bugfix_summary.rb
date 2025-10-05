# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing overall bugfix statistics
    class BugfixSummary
      attr_reader :total_commits, :bugfix_commits, :feature_commits, :maintenance_commits,
                  :bugfix_ratio, :feature_ratio, :maintenance_ratio, :quality_score

      def initialize(total_commits:, bugfix_commits:, feature_commits:, maintenance_commits:)
        @total_commits = total_commits
        @bugfix_commits = bugfix_commits
        @feature_commits = feature_commits
        @maintenance_commits = maintenance_commits
        @bugfix_ratio = calculate_ratio(bugfix_commits, total_commits)
        @feature_ratio = calculate_ratio(feature_commits, total_commits)
        @maintenance_ratio = calculate_ratio(maintenance_commits, total_commits)
        @quality_score = calculate_quality_score(bugfix_commits, feature_commits)
        freeze
      end

      def high_quality?
        quality_score > 0.7 && bugfix_ratio < 20.0
      end

      def needs_attention?
        bugfix_ratio > 40.0 || quality_score < 0.3
      end

      def balanced?
        feature_ratio > 30.0 && bugfix_ratio < 30.0
      end

      def to_h
        {
          total_commits: total_commits,
          bugfix_commits: bugfix_commits,
          feature_commits: feature_commits,
          maintenance_commits: maintenance_commits,
          bugfix_ratio: bugfix_ratio,
          feature_ratio: feature_ratio,
          maintenance_ratio: maintenance_ratio,
          quality_score: quality_score,
        }
      end

      private

      def calculate_ratio(count, total)
        return 0.0 if total.zero?

        (count.to_f / total * 100).round(2)
      end

      def calculate_quality_score(bugfix_commits, feature_commits)
        total_productive = bugfix_commits + feature_commits
        return 1.0 if total_productive.zero?

        feature_ratio = feature_commits.to_f / total_productive
        [feature_ratio, 0.0].max.round(3)
      end
    end
  end
end
