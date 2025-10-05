# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for detecting deployment bottlenecks and performance issues
    class BottleneckDetector
      def initialize(commit_lead_times, author_stats)
        @commit_lead_times = commit_lead_times
        @author_stats = author_stats
      end

      def detect_bottlenecks
        {
          slow_authors: identify_slow_authors,
          blocked_commits: identify_blocked_commits,
          weekend_bottlenecks: identify_weekend_bottlenecks,
          large_commit_delays: identify_large_commit_delays,
          merge_commit_delays: identify_merge_commit_delays,
        }
      end

      private

      attr_reader :commit_lead_times, :author_stats

      def identify_slow_authors
        return [] if author_stats.empty?

        median_lead_time = calculate_overall_median
        threshold = median_lead_time * 2

        author_stats.select do |_, stats|
          stats.avg_lead_time_hours > threshold
        end.keys
      end

      def identify_blocked_commits
        commit_lead_times.select(&:very_slow?).map(&:hash)
      end

      def identify_weekend_bottlenecks
        weekend_commits = commit_lead_times.select(&:weekend_commit?)
        return {} if weekend_commits.empty?

        weekend_avg = calculate_average_lead_time(weekend_commits)
        weekday_commits = commit_lead_times.reject(&:weekend_commit?)
        weekday_avg = calculate_average_lead_time(weekday_commits)

        {
          weekend_avg_hours: weekend_avg,
          weekday_avg_hours: weekday_avg,
          bottleneck_factor: (weekend_avg / weekday_avg).round(2),
        }
      end

      def identify_large_commit_delays
        # Since we don't have commit size data in lead time analysis,
        # we'll use long commit messages as a proxy for potentially complex commits
        complex_commits = commit_lead_times.select(&:large_message?)
        return {} if complex_commits.empty?

        {
          count: complex_commits.size,
          avg_lead_time: calculate_average_lead_time(complex_commits),
          worst_commit: find_slowest_commit(complex_commits),
        }
      end

      def identify_merge_commit_delays
        merge_commits = commit_lead_times.select(&:merge_commit?)
        return {} if merge_commits.empty?

        {
          count: merge_commits.size,
          avg_lead_time: calculate_average_lead_time(merge_commits),
          worst_commit: find_slowest_commit(merge_commits),
        }
      end

      def calculate_overall_median
        lead_times = commit_lead_times.map(&:lead_time_hours)
        calculate_median(lead_times)
      end

      def calculate_median(values)
        return 0.0 if values.empty?

        sorted = values.sort
        mid = sorted.length / 2

        if sorted.length.odd?
          sorted[mid]
        else
          (sorted[mid - 1] + sorted[mid]) / 2.0
        end
      end

      def calculate_average_lead_time(commits)
        return 0.0 if commits.empty?

        lead_times = commits.map(&:lead_time_hours)
        (lead_times.sum.to_f / lead_times.size).round(2)
      end

      def find_slowest_commit(commits)
        return nil if commits.empty?

        slowest = commits.max_by(&:lead_time_hours)
        {
          hash: slowest.hash,
          lead_time_hours: slowest.lead_time_hours,
          author: slowest.author,
        }
      end
    end
  end
end
