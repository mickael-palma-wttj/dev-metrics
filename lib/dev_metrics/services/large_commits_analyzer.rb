# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for analyzing large commits and identifying risky development patterns
    class LargeCommitsAnalyzer
      # Size thresholds for commit categorization (lines changed)
      SMALL_COMMIT_THRESHOLD = 50
      MEDIUM_COMMIT_THRESHOLD = 200
      LARGE_COMMIT_THRESHOLD = 500
      HUGE_COMMIT_THRESHOLD = 1000

      def initialize(commits_data)
        @commits_data = commits_data
      end

      def analyze
        return build_empty_result if commits_data.empty?

        commit_sizes = extract_commit_sizes
        thresholds = build_thresholds

        {
          overall: build_overall_stats(commit_sizes, thresholds),
          thresholds: thresholds,
          by_author: build_author_stats(commit_sizes),
          largest_commits: find_largest_commits(commit_sizes),
          size_distribution: analyze_size_distribution(commit_sizes),
          risk_patterns: analyze_risk_patterns(commit_sizes),
        }
      end

      private

      attr_reader :commits_data

      def build_empty_result
        {
          overall: {
            total_commits: 0,
            large_commits: 0,
            huge_commits: 0,
            large_commit_ratio: 0.0,
            huge_commit_ratio: 0.0,
            risk_score: 0.0,
            avg_commit_size: 0.0,
          },
          thresholds: build_thresholds,
          by_author: {},
          largest_commits: [],
          size_distribution: {},
          risk_patterns: {},
        }
      end

      def extract_commit_sizes
        commits_data.map do |commit|
          size = (commit[:additions] || 0) + (commit[:deletions] || 0)
          {
            size: size,
            author: commit[:author_name],
            hash: commit[:hash],
            message: commit[:message] || commit[:subject],
            date: commit[:date],
          }
        end
      end

      def build_thresholds
        {
          small: SMALL_COMMIT_THRESHOLD,
          medium: MEDIUM_COMMIT_THRESHOLD,
          large: LARGE_COMMIT_THRESHOLD,
          huge: HUGE_COMMIT_THRESHOLD,
        }
      end

      def build_overall_stats(commit_sizes, thresholds)
        total_commits = commit_sizes.size
        large_commits = commit_sizes.count { |c| c[:size] >= thresholds[:large] }
        huge_commits = commit_sizes.count { |c| c[:size] >= thresholds[:huge] }

        total_size = commit_sizes.sum { |c| c[:size] }
        avg_size = total_commits.positive? ? (total_size.to_f / total_commits).round(2) : 0.0

        {
          total_commits: total_commits,
          large_commits: large_commits,
          huge_commits: huge_commits,
          large_commit_ratio: calculate_ratio(large_commits, total_commits),
          huge_commit_ratio: calculate_ratio(huge_commits, total_commits),
          risk_score: calculate_risk_score(large_commits, huge_commits, total_commits),
          avg_commit_size: avg_size,
        }
      end

      def calculate_ratio(count, total)
        return 0.0 if total.zero?

        (count.to_f / total * 100).round(2)
      end

      def calculate_risk_score(large_commits, huge_commits, total_commits)
        return 0.0 if total_commits.zero?

        # Risk score based on proportion of large commits
        large_weight = 1.0
        huge_weight = 3.0

        risk = ((large_commits * large_weight) + (huge_commits * huge_weight)) / total_commits.to_f
        (risk * 10).round(2) # Scale to 0-100
      end

      def build_author_stats(commit_sizes)
        author_commits = commit_sizes.group_by { |c| c[:author] }

        author_commits.transform_values do |commits|
          sizes = commits.map { |c| c[:size] }
          large_count = commits.count { |c| c[:size] >= LARGE_COMMIT_THRESHOLD }
          huge_count = commits.count { |c| c[:size] >= HUGE_COMMIT_THRESHOLD }

          {
            total_commits: commits.size,
            large_commits: large_count,
            huge_commits: huge_count,
            max_commit_size: sizes.max,
            avg_commit_size: sizes.sum.to_f / sizes.size,
            risk_score: calculate_risk_score(large_count, huge_count, commits.size),
          }
        end
      end

      def find_largest_commits(commit_sizes)
        commit_sizes.sort_by { |c| -c[:size] }.first(10).map do |commit|
          {
            calculated_size: commit[:size],
            author_name: commit[:author_name],
            hash: commit[:hash][0..7],
            subject: commit[:message]&.slice(0, 100),
            date: commit[:date],
          }
        end
      end

      def analyze_size_distribution(commit_sizes)
        return {} if commit_sizes.empty?

        sizes = commit_sizes.map { |c| c[:size] }
        thresholds = build_thresholds

        {
          small: sizes.count { |s| s < thresholds[:small] },
          medium: sizes.count { |s| s >= thresholds[:small] && s < thresholds[:large] },
          large: sizes.count { |s| s >= thresholds[:large] && s < thresholds[:huge] },
          huge: sizes.count { |s| s >= thresholds[:huge] },
        }
      end

      def analyze_risk_patterns(commit_sizes)
        return {} if commit_sizes.empty?

        large_commits = commit_sizes.select { |c| c[:size] >= LARGE_COMMIT_THRESHOLD }

        # Analyze patterns in large commits
        {
          frequent_large_commit_authors: find_frequent_large_commit_authors(large_commits),
          large_commit_frequency: calculate_large_commit_frequency(large_commits),
          avg_large_commit_size: large_commits.empty? ? 0 : large_commits.sum { |c| c[:size] } / large_commits.size,
        }
      end

      def find_frequent_large_commit_authors(large_commits)
        author_counts = large_commits.group_by { |c| c[:author] }
          .transform_values(&:size)

        # Authors with more than 2 large commits
        author_counts.select { |_, count| count > 2 }
          .sort_by { |_, count| -count }
          .first(5)
          .to_h
      end

      def calculate_large_commit_frequency(large_commits)
        return 0.0 if large_commits.empty? || commits_data.empty?

        (large_commits.size.to_f / commits_data.size * 100).round(2)
      end
    end
  end
end
