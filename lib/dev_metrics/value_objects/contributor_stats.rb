# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing contributor statistics and metrics
    class ContributorStats
      attr_reader :contributors, :total_contributors, :total_commits, :avg_commits_per_contributor, :top_contributor

      def initialize(contributors:, total_contributors:, total_commits:, avg_commits_per_contributor:, top_contributor:)
        @contributors = contributors.freeze
        @total_contributors = total_contributors
        @total_commits = total_commits
        @avg_commits_per_contributor = avg_commits_per_contributor
        @top_contributor = top_contributor
        freeze
      end

      def high_activity_contributors
        contributors.select(&:high_activity?)
      end

      def low_activity_contributors
        contributors.select(&:low_activity?)
      end

      def balanced_team?
        return false if contributors.empty?

        max_commits = contributors.map(&:commit_count).max
        min_commits = contributors.map(&:commit_count).min

        max_commits <= (min_commits * 3)
      end

      def top_contributor_dominance
        return 0.0 if total_commits.zero? || contributors.empty?

        max_commits = contributors.map(&:commit_count).max || 0
        (max_commits.to_f / total_commits * 100).round(1)
      end

      def contributor_distribution
        {
          high_activity: high_activity_contributors.size,
          medium_activity: medium_activity_contributors.size,
          low_activity: low_activity_contributors.size,
        }
      end

      def to_h
        result = {}
        contributors.each do |contributor|
          result[contributor.display_name] = contributor.commit_count
        end
        result
      end

      private

      def medium_activity_contributors
        contributors.reject { |c| c.high_activity? || c.low_activity? }
      end
    end
  end
end
