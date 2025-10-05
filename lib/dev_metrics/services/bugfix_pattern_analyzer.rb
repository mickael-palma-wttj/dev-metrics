# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for analyzing temporal patterns in bugfix commits
    class BugfixPatternAnalyzer
      URGENT_KEYWORDS = %w[urgent critical hotfix emergency immediate asap].freeze
      SEVERITY_KEYWORDS = %w[critical major minor trivial blocker].freeze

      def initialize(bugfix_commits)
        @bugfix_commits = bugfix_commits
      end

      def analyze
        return {} if bugfix_commits.empty?

        {
          by_hour_of_day: analyze_by_hour,
          by_day_of_week: analyze_by_day,
          by_month: analyze_by_month,
          peak_bugfix_hour: find_peak_hour,
          peak_bugfix_day: find_peak_day,
          urgency_indicators: analyze_urgency_patterns,
        }
      end

      private

      attr_reader :bugfix_commits

      def analyze_by_hour
        group_by_time_unit { |commit| commit[:date].hour }
      end

      def analyze_by_day
        group_by_time_unit { |commit| commit[:date].strftime('%A') }
      end

      def analyze_by_month
        group_by_time_unit { |commit| commit[:date].strftime('%Y-%m') }
      end

      def group_by_time_unit(&block)
        counts = Hash.new(0)
        bugfix_commits.each { |commit| counts[block.call(commit)] += 1 }
        counts
      end

      def find_peak_hour
        analyze_by_hour.max_by { |_, count| count }&.first
      end

      def find_peak_day
        analyze_by_day.max_by { |_, count| count }&.first
      end

      def analyze_urgency_patterns
        urgency_counts = count_keywords(URGENT_KEYWORDS)
        severity_counts = count_keywords(SEVERITY_KEYWORDS)
        urgent_total = urgency_counts.values.sum

        {
          urgency_keywords: urgency_counts,
          severity_keywords: severity_counts,
          urgent_fixes: urgent_total,
          urgent_ratio: calculate_ratio(urgent_total, bugfix_commits.size),
        }
      end

      def count_keywords(keywords)
        counts = Hash.new(0)

        bugfix_commits.each do |commit|
          message = commit[:message].downcase
          keywords.each { |keyword| counts[keyword] += 1 if message.include?(keyword) }
        end

        counts
      end

      def calculate_ratio(count, total)
        return 0.0 if total.zero?

        (count.to_f / total * 100).round(2)
      end
    end
  end
end
