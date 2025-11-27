# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating revert statistics and author metrics
    class RevertStatisticsCalculator
      def initialize(commits_data, revert_commits, reverted_commits)
        @commits_data = commits_data
        @revert_commits = revert_commits
        @reverted_commits = reverted_commits
      end

      def calculate_author_stats
        stats = initialize_author_stats

        populate_commit_counts(stats)
        calculate_derived_metrics(stats)

        stats.sort_by { |_, data| -data[:reverted_rate] }.to_h
      end

      def calculate_overall_stats
        total_commits = commits_data.size
        total_reverts = revert_commits.size
        total_reverted = reverted_commits.size

        build_overall_stats_hash(total_commits, total_reverts, total_reverted)
      end

      def build_overall_stats_hash(total_commits, total_reverts, total_reverted)
        {
          total_commits: total_commits,
          revert_commits: total_reverts,
          reverted_commits: total_reverted,
          revert_rate: calculate_rate(total_reverts, total_commits),
          reverted_rate: calculate_rate(total_reverted, total_commits),
          stability_score: calculate_stability_score(total_reverted, total_commits),
        }
      end

      def count_high_risk_authors(author_stats)
        author_stats.count { |_, stats| stats[:reverted_rate] > 5.0 }
      end

      def find_most_reverted_author(author_stats)
        return nil if author_stats.empty?

        author_stats.max_by { |_, stats| stats[:reverted_rate] }&.first
      end

      private

      attr_reader :commits_data, :revert_commits, :reverted_commits

      def initialize_author_stats
        Hash.new { |h, k| h[k] = default_author_stats }
      end

      def default_author_stats
        {
          total_commits: 0,
          reverts_made: 0,
          commits_reverted: 0,
          revert_rate: 0.0,
          reverted_rate: 0.0,
          reliability_score: 1.0,
        }
      end

      def populate_commit_counts(stats)
        count_total_commits(stats)
        count_reverts_made(stats)
        count_commits_reverted(stats)
      end

      def count_total_commits(stats)
        commits_data.each do |commit|
          author = commit[:author_name]
          stats[author][:total_commits] += 1
        end
      end

      def count_reverts_made(stats)
        revert_commits.each do |commit|
          author = commit[:author_name]
          stats[author][:reverts_made] += 1
        end
      end

      def count_commits_reverted(stats)
        reverted_commits.each do |commit|
          author = commit[:author_name]
          stats[author][:commits_reverted] += 1
        end
      end

      def calculate_derived_metrics(stats)
        stats.each_value do |data|
          total = data[:total_commits]
          next if total.zero?

          data[:revert_rate] = calculate_rate(data[:reverts_made], total)
          data[:reverted_rate] = calculate_rate(data[:commits_reverted], total)
          data[:reliability_score] = calculate_reliability_score(data[:commits_reverted], total)
        end
      end

      def calculate_rate(count, total)
        return 0.0 if total.zero?

        (count.to_f / total * 100).round(2)
      end

      def calculate_stability_score(reverted_commits, total_commits)
        return 1.0 if total_commits.zero?

        stability = 1.0 - (reverted_commits.to_f / total_commits)
        [stability, 0.0].max.round(3)
      end

      def calculate_reliability_score(reverted_commits, total_commits)
        return 1.0 if total_commits.zero?

        reliability = 1.0 - (reverted_commits.to_f / total_commits)
        [reliability, 0.0].max.round(3)
      end
    end
  end
end
