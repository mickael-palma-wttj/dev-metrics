# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for statistical calculations on commit data
    class CommitStatisticsCalculator
      def initialize(commits_data, commit_sizes)
        @commits_data = commits_data
        @commit_sizes = commit_sizes
      end

      def analyze_size_distribution
        return {} if commit_sizes.empty?

        sorted_sizes = commit_sizes.sort
        build_distribution_hash(sorted_sizes)
      end

      def build_distribution_hash(sorted_sizes)
        {
          min: sorted_sizes.first,
          max: sorted_sizes.last,
          median: calculate_percentile(sorted_sizes, 50),
          p75: calculate_percentile(sorted_sizes, 75),
          p90: calculate_percentile(sorted_sizes, 90),
          p95: calculate_percentile(sorted_sizes, 95),
          p99: calculate_percentile(sorted_sizes, 99),
          std_deviation: calculate_standard_deviation(commit_sizes),
        }
      end

      def calculate_author_stats(thresholds)
        stats = initialize_author_stats

        populate_author_commit_counts(stats, thresholds)
        calculate_derived_author_metrics(stats)

        stats.sort_by { |_, data| -data[:risk_score] }.to_h
      end

      def calculate_ratio(count, total)
        return 0.0 if total.zero?

        (count.to_f / total * 100).round(2)
      end

      def count_high_risk_authors(author_stats)
        author_stats.count { |_, stats| stats[:risk_score] > 20.0 }
      end

      def find_largest_commit_author(author_stats)
        return nil if author_stats.empty?

        author_stats.max_by { |_, stats| stats[:max_commit_size] }&.first
      end

      private

      attr_reader :commits_data, :commit_sizes

      def calculate_percentile(sorted_array, percentile)
        return 0 if sorted_array.empty?

        index = (percentile / 100.0 * (sorted_array.length - 1)).round
        sorted_array[index]
      end

      def calculate_standard_deviation(values)
        return 0 if values.empty?

        mean = values.sum.to_f / values.size
        variance = values.sum { |v| (v - mean)**2 } / values.size
        Math.sqrt(variance).round(2)
      end

      def initialize_author_stats
        Hash.new { |h, k| h[k] = default_author_stats }
      end

      def default_author_stats
        {
          total_commits: 0,
          large_commits: 0,
          huge_commits: 0,
          avg_commit_size: 0.0,
          max_commit_size: 0,
          large_commit_ratio: 0.0,
          risk_score: 0.0,
        }
      end

      def populate_author_commit_counts(stats, thresholds)
        commits_data.each_with_index do |commit, index|
          author = commit[:author] || commit[:author_name]
          size = commit_sizes[index]

          update_author_stats(stats[author], size, thresholds)
        end
      end

      def update_author_stats(author_stats, size, thresholds)
        author_stats[:total_commits] += 1
        author_stats[:max_commit_size] = [author_stats[:max_commit_size], size].max

        if size >= thresholds[:huge]
          author_stats[:huge_commits] += 1
          author_stats[:large_commits] += 1
        elsif size >= thresholds[:large]
          author_stats[:large_commits] += 1
        end
      end

      def calculate_derived_author_metrics(stats)
        stats.each do |author, data|
          author_sizes = calculate_author_sizes(author)

          data[:avg_commit_size] = calculate_average(author_sizes)
          data[:large_commit_ratio] = calculate_ratio(data[:large_commits], data[:total_commits])
          data[:risk_score] = calculate_author_risk_score(data)
        end
      end

      def calculate_author_sizes(author)
        author_commits = commits_data.select { |c| (c[:author] || c[:author_name]) == author }

        author_commits.map do |commit|
          index = commits_data.index(commit)
          commit_sizes[index]
        end
      end

      def calculate_average(values)
        return 0 if values.empty?

        (values.sum.to_f / values.size).round(1)
      end

      def calculate_author_risk_score(author_data)
        return 0.0 if author_data[:total_commits].zero?

        risk_points = (author_data[:large_commits] * 1) + (author_data[:huge_commits] * 3)
        max_risk_points = author_data[:total_commits] * 3

        (risk_points.to_f / max_risk_points * 100).round(2)
      end
    end
  end
end
