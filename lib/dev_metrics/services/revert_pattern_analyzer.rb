# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing revert patterns and reasons
    class RevertPatternAnalyzer
      def initialize(revert_commits, reverted_commits)
        @revert_commits = revert_commits
        @reverted_commits = reverted_commits
      end

      def build_revert_details
        {
          recent_reverts: revert_commits.first(10),
          recent_reverted: reverted_commits.first(10),
          revert_reasons: categorize_revert_reasons,
        }
      end

      def analyze_time_patterns
        return {} if revert_commits.empty?

        by_hour, by_day = calculate_time_distribution

        {
          by_hour_of_day: by_hour,
          by_day_of_week: by_day,
          peak_revert_hour: find_peak_time(by_hour),
          peak_revert_day: find_peak_time(by_day),
        }
      end

      def calculate_revert_frequency
        return 0 if revert_commits.empty?

        dates = extract_sorted_dates
        return 0 if dates.size < 2

        calculate_average_interval(dates)
      end

      private

      attr_reader :revert_commits, :reverted_commits

      def categorize_revert_reasons
        categories = Hash.new(0)

        revert_commits.each do |commit|
          category = determine_revert_category(commit[:message])
          categories[category] += 1
        end

        categories
      end

      def determine_revert_category(message)
        normalized_message = message.downcase

        category_patterns.each do |category, pattern|
          return category if normalized_message.match?(pattern)
        end

        'Other'
      end

      def category_patterns
        {
          'Bug fixes' => /bug|error|fix|issue|problem/,
          'Test issues' => /test|spec|failing/,
          'Breaking changes' => /break|broken|regression/,
          'Performance issues' => /performance|slow|timeout/,
          'Security concerns' => /security|vulnerability/,
        }
      end

      def calculate_time_distribution
        by_hour = Hash.new(0)
        by_day = Hash.new(0)

        revert_commits.each do |commit|
          time = commit[:date]
          by_hour[time.hour] += 1
          by_day[time.strftime('%A')] += 1
        end

        [by_hour, by_day]
      end

      def find_peak_time(time_distribution)
        time_distribution.max_by { |_, count| count }&.first
      end

      def extract_sorted_dates
        revert_commits.map { |commit| commit[:date] }.sort
      end

      def calculate_average_interval(dates)
        intervals = dates.each_cons(2).map { |a, b| (b - a) / 86_400 } # days
        (intervals.sum / intervals.size).round(1)
      end
    end
  end
end
