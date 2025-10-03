# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing commit risk factors and patterns
    class CommitRiskAnalyzer
      def initialize(commits_data, commit_sizes, thresholds)
        @commits_data = commits_data
        @commit_sizes = commit_sizes
        @thresholds = thresholds
      end

      def identify_patterns
        large_commits = collect_large_commits

        {
          risky_commits: large_commits.sort_by { |c| -c[:size] }.first(20),
          common_risk_factors: aggregate_risk_factors(large_commits),
          time_patterns: analyze_timing_patterns(large_commits),
        }
      end

      def calculate_risk_score(large_commits, huge_commits, total_commits)
        return 0.0 if total_commits.zero?

        risk_points = (large_commits * 1) + (huge_commits * 3)
        max_risk_points = total_commits * 3

        (risk_points.to_f / max_risk_points * 100).round(2)
      end

      private

      attr_reader :commits_data, :commit_sizes, :thresholds

      def collect_large_commits
        large_commits = []

        commits_data.each_with_index do |commit, index|
          large_commits.concat(process_commit_if_large(commit, index))
        end

        large_commits
      end

      def process_commit_if_large(commit, index)
        size = commit_sizes[index]
        return [] unless size >= thresholds[:large]

        [{
          commit: commit,
          size: size,
          risk_factors: analyze_commit_risk_factors(commit, size),
        }]
      end

      def analyze_commit_risk_factors(commit, size)
        risk_factors = []

        risk_factors.concat(size_risk_factors(size))
        risk_factors.concat(file_risk_factors(commit))
        risk_factors.concat(message_risk_factors(commit))
        risk_factors.concat(timing_risk_factors(commit))

        risk_factors
      end

      def size_risk_factors(size)
        factors = []
        factors << 'HUGE_SIZE' if size >= thresholds[:huge]
        factors << 'LARGE_SIZE' if size >= thresholds[:large]
        factors
      end

      def file_risk_factors(commit)
        files_count = commit[:files_changed]&.size || 0
        factors = []
        factors << 'MANY_FILES' if files_count > 20
        factors << 'EXCESSIVE_FILES' if files_count > 50
        factors
      end

      def message_risk_factors(commit)
        message = (commit[:message] || commit[:subject] || '').downcase
        factors = []

        factors << 'MERGE_COMMIT' if message.include?('merge')
        factors << 'VAGUE_MESSAGE' if message.length < 10
        factors << 'MULTIPLE_CONCERNS' if multiple_concerns?(message)

        factors
      end

      def timing_risk_factors(commit)
        time = commit[:date]
        factors = []

        factors << 'OFF_HOURS' if off_hours?(time)
        factors << 'WEEKEND' if weekend?(time)

        factors
      end

      def multiple_concerns?(message)
        message.include?('and') && message.scan(/\band\b/).size > 1
      end

      def off_hours?(time)
        time.hour < 9 || time.hour > 18
      end

      def weekend?(time)
        time.saturday? || time.sunday?
      end

      def aggregate_risk_factors(large_commits)
        factor_counts = Hash.new(0)

        large_commits.each do |commit_data|
          commit_data[:risk_factors].each { |factor| factor_counts[factor] += 1 }
        end

        factor_counts.sort_by { |_, count| -count }.to_h
      end

      def analyze_timing_patterns(large_commits)
        return {} if large_commits.empty?

        by_hour, by_day = timing_distribution(large_commits)

        {
          by_hour_of_day: by_hour,
          by_day_of_week: by_day,
          peak_hour: by_hour.max_by { |_, count| count }&.first,
          peak_day: by_day.max_by { |_, count| count }&.first,
        }
      end

      def timing_distribution(large_commits)
        by_hour = Hash.new(0)
        by_day = Hash.new(0)

        large_commits.each do |commit_data|
          time = commit_data[:commit][:date]
          by_hour[time.hour] += 1
          by_day[time.strftime('%A')] += 1
        end

        [by_hour, by_day]
      end
    end
  end
end
