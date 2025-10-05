# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for calculating author-specific bugfix statistics
    class AuthorBugfixAnalyzer
      def initialize(commits_data, categorized_commits)
        @commits_data = commits_data
        @categorized_commits = categorized_commits
      end

      def analyze
        stats = initialize_author_stats
        count_commits_by_author(stats)
        calculate_ratios_and_scores(stats)
        sort_by_bugfix_ratio(stats)
      end

      private

      attr_reader :commits_data, :categorized_commits

      def initialize_author_stats
        Hash.new do |h, k|
          h[k] = {
            total_commits: 0,
            bugfix_commits: 0,
            feature_commits: 0,
            maintenance_commits: 0,
            bugfix_ratio: 0.0,
            feature_ratio: 0.0,
            quality_score: 1.0,
          }
        end
      end

      def count_commits_by_author(stats)
        commits_data.each { |commit| stats[commit[:author]][:total_commits] += 1 }

        categorized_commits.each do |category, commits|
          commits.each { |commit| increment_category_count(stats, commit[:author], category) }
        end
      end

      def increment_category_count(stats, author, category)
        case category
        when :bugfix then stats[author][:bugfix_commits] += 1
        when :feature then stats[author][:feature_commits] += 1
        when :maintenance then stats[author][:maintenance_commits] += 1
        end
      end

      def calculate_ratios_and_scores(stats)
        stats.each_value do |data|
          total = data[:total_commits]
          next if total.zero?

          data[:bugfix_ratio] = calculate_ratio(data[:bugfix_commits], total)
          data[:feature_ratio] = calculate_ratio(data[:feature_commits], total)
          data[:quality_score] = calculate_quality_score(data[:bugfix_commits], data[:feature_commits])
        end
      end

      def sort_by_bugfix_ratio(stats)
        stats.sort_by { |_, data| -data[:bugfix_ratio] }.to_h
      end

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
