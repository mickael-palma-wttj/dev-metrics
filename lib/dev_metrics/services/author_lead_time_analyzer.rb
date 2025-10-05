# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for calculating author-specific lead time statistics
    class AuthorLeadTimeAnalyzer
      def initialize(commit_lead_times)
        @commit_lead_times = commit_lead_times
      end

      def analyze
        return {} if commit_lead_times.empty?

        author_commits = group_commits_by_author
        calculate_author_stats(author_commits)
      end

      private

      attr_reader :commit_lead_times

      def group_commits_by_author
        commit_lead_times.group_by(&:author)
      end

      def calculate_author_stats(author_commits)
        author_commits.transform_values do |commits|
          create_author_stats(commits)
        end.sort_by { |_, stats| stats.avg_lead_time_hours }.to_h
      end

      def create_author_stats(commits)
        lead_times = commits.map(&:lead_time_hours)

        ValueObjects::AuthorLeadTimeStats.new(
          author: commits.first.author,
          total_commits: calculate_total_commits(commits.first.author),
          commits_deployed: commits.size,
          avg_lead_time_hours: calculate_average(lead_times),
          median_lead_time_hours: calculate_median(lead_times),
          min_lead_time_hours: lead_times.min,
          max_lead_time_hours: lead_times.max,
          deployment_rate: calculate_deployment_rate(commits.first.author, commits.size)
        )
      end

      def calculate_total_commits(author)
        commit_lead_times.count { |commit| commit.author == author }
      end

      def calculate_average(values)
        return 0.0 if values.empty?

        (values.sum.to_f / values.size).round(2)
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

      def calculate_deployment_rate(author, deployed_commits)
        total_commits = calculate_total_commits(author)
        return 0.0 if total_commits.zero?

        (deployed_commits.to_f / total_commits * 100).round(2)
      end
    end
  end
end
