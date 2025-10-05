# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing lead time statistics for an author
    class AuthorLeadTimeStats
      attr_reader :author, :total_commits, :commits_deployed, :avg_lead_time_hours,
                  :median_lead_time_hours, :min_lead_time_hours, :max_lead_time_hours,
                  :deployment_rate

      def initialize(author:, total_commits:, commits_deployed:, avg_lead_time_hours:,
                     median_lead_time_hours:, min_lead_time_hours:, max_lead_time_hours:,
                     deployment_rate:)
        @author = author
        @total_commits = total_commits
        @commits_deployed = commits_deployed
        @avg_lead_time_hours = avg_lead_time_hours
        @median_lead_time_hours = median_lead_time_hours
        @min_lead_time_hours = min_lead_time_hours
        @max_lead_time_hours = max_lead_time_hours
        @deployment_rate = deployment_rate
        freeze
      end

      def fast_author?
        avg_lead_time_hours < 24
      end

      def high_deployment_rate?
        deployment_rate > 80
      end

      def consistent_performer?
        (max_lead_time_hours - min_lead_time_hours) < (avg_lead_time_hours * 0.5)
      end

      def frequent_deployer?
        commits_deployed > 10
      end

      def to_h
        {
          total_commits: total_commits,
          commits_deployed: commits_deployed,
          avg_lead_time_hours: avg_lead_time_hours,
          median_lead_time_hours: median_lead_time_hours,
          min_lead_time_hours: min_lead_time_hours,
          max_lead_time_hours: max_lead_time_hours,
          deployment_rate: deployment_rate,
        }
      end
    end
  end
end
