# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing overall lead time metrics
    class LeadTimeMetrics
      attr_reader :total_commits, :commits_with_lead_time, :avg_lead_time_hours,
                  :median_lead_time_hours, :p95_lead_time_hours, :min_lead_time_hours,
                  :max_lead_time_hours, :flow_efficiency

      def initialize(total_commits:, commits_with_lead_time:, avg_lead_time_hours:,
                     median_lead_time_hours:, p95_lead_time_hours:, min_lead_time_hours:,
                     max_lead_time_hours:, flow_efficiency:)
        @total_commits = total_commits
        @commits_with_lead_time = commits_with_lead_time
        @avg_lead_time_hours = avg_lead_time_hours
        @median_lead_time_hours = median_lead_time_hours
        @p95_lead_time_hours = p95_lead_time_hours
        @min_lead_time_hours = min_lead_time_hours
        @max_lead_time_hours = max_lead_time_hours
        @flow_efficiency = flow_efficiency
        freeze
      end

      def high_performance?
        avg_lead_time_hours < 48 && flow_efficiency > 0.8
      end

      def needs_improvement?
        avg_lead_time_hours > 168 || flow_efficiency < 0.5
      end

      def good_coverage?
        commits_with_lead_time.to_f / total_commits > 0.7
      end

      def performance_category
        return 'excellent' if avg_lead_time_hours < 24 && flow_efficiency > 0.9
        return 'good' if avg_lead_time_hours < 72 && flow_efficiency > 0.7
        return 'fair' if avg_lead_time_hours < 168 && flow_efficiency > 0.5

        'needs_improvement'
      end

      def to_h
        {
          total_commits: total_commits,
          commits_with_lead_time: commits_with_lead_time,
          avg_lead_time_hours: avg_lead_time_hours,
          median_lead_time_hours: median_lead_time_hours,
          p95_lead_time_hours: p95_lead_time_hours,
          min_lead_time_hours: min_lead_time_hours,
          max_lead_time_hours: max_lead_time_hours,
          flow_efficiency: flow_efficiency,
        }
      end
    end
  end
end
