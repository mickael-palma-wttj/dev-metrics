# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for analyzing lead time trends and patterns over time
    class TrendAnalyzer
      def initialize(commit_lead_times)
        @commit_lead_times = commit_lead_times
      end

      def analyze_trends
        return {} if commit_lead_times.empty?

        {
          monthly_trends: analyze_monthly_trends,
          performance_distribution: analyze_performance_distribution,
          improvement_opportunities: identify_improvement_opportunities,
          consistency_metrics: calculate_consistency_metrics,
        }
      end

      private

      attr_reader :commit_lead_times

      def analyze_monthly_trends
        monthly_data = group_commits_by_month

        monthly_data.transform_values do |commits|
          calculate_monthly_stats(commits)
        end
      end

      def analyze_performance_distribution
        {
          very_fast: count_by_performance(:very_fast?),
          fast: count_by_performance(:fast?),
          moderate: count_by_performance(:moderate?),
          slow: count_by_performance(:slow?),
          very_slow: count_by_performance(:very_slow?),
        }
      end

      def identify_improvement_opportunities
        {
          high_variance_authors: find_high_variance_authors,
          recurring_slow_patterns: find_recurring_slow_patterns,
          optimization_targets: find_optimization_targets,
        }
      end

      def calculate_consistency_metrics
        lead_times = commit_lead_times.map(&:lead_time_hours)

        {
          standard_deviation: calculate_standard_deviation(lead_times),
          coefficient_variation: calculate_coefficient_variation(lead_times),
          consistency_score: calculate_consistency_score(lead_times),
        }
      end

      def group_commits_by_month
        commit_lead_times.group_by do |commit|
          commit.date.strftime('%Y-%m')
        end
      end

      def calculate_monthly_stats(commits)
        lead_times = commits.map(&:lead_time_hours)

        {
          commit_count: commits.size,
          avg_lead_time: (lead_times.sum.to_f / lead_times.size).round(2),
          median_lead_time: calculate_median(lead_times),
          min_lead_time: lead_times.min,
          max_lead_time: lead_times.max,
        }
      end

      def count_by_performance(performance_method)
        commit_lead_times.count(&performance_method)
      end

      def find_high_variance_authors
        author_variances = calculate_author_variances
        threshold = calculate_variance_threshold(author_variances.values)

        author_variances.select { |_, variance| variance > threshold }.keys
      end

      def find_recurring_slow_patterns
        slow_commits = commit_lead_times.select(&:slow?)
        patterns = analyze_commit_patterns(slow_commits)

        patterns.select { |_, count| count >= 3 }
      end

      def find_optimization_targets
        bottleneck_files = identify_bottleneck_files
        bottleneck_times = identify_bottleneck_times

        {
          files: bottleneck_files,
          time_periods: bottleneck_times,
        }
      end

      def calculate_author_variances
        author_commits = commit_lead_times.group_by(&:author)

        author_commits.transform_values do |commits|
          lead_times = commits.map(&:lead_time_hours)
          calculate_variance(lead_times)
        end
      end

      def calculate_variance_threshold(variances)
        return 0.0 if variances.empty?

        avg_variance = variances.sum.to_f / variances.size
        avg_variance * 1.5
      end

      def analyze_commit_patterns(commits)
        patterns = {}

        commits.each do |commit|
          pattern_key = "#{commit.weekend_commit? ? 'weekend' : 'weekday'}_#{commit.large_message? ? 'complex' : 'normal'}"
          patterns[pattern_key] = (patterns[pattern_key] || 0) + 1
        end

        patterns
      end

      def identify_bottleneck_files
        # This would need file path information from commits
        # Placeholder for file-based bottleneck analysis
        []
      end

      def identify_bottleneck_times
        time_buckets = group_commits_by_hour
        avg_lead_time = calculate_overall_average

        time_buckets.select do |_, commits|
          bucket_avg = commits.map(&:lead_time_hours).sum.to_f / commits.size
          bucket_avg > avg_lead_time * 1.5
        end.keys
      end

      def group_commits_by_hour
        commit_lead_times.group_by do |commit|
          commit.date.hour
        end
      end

      def calculate_overall_average
        lead_times = commit_lead_times.map(&:lead_time_hours)
        lead_times.sum.to_f / lead_times.size
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

      def calculate_variance(values)
        return 0.0 if values.size < 2

        mean = values.sum.to_f / values.size
        sum_squares = values.sum { |v| (v - mean)**2 }
        sum_squares / (values.size - 1)
      end

      def calculate_standard_deviation(values)
        Math.sqrt(calculate_variance(values))
      end

      def calculate_coefficient_variation(values)
        return 0.0 if values.empty?

        mean = values.sum.to_f / values.size
        return 0.0 if mean.zero?

        std_dev = calculate_standard_deviation(values)
        (std_dev / mean * 100).round(2)
      end

      def calculate_consistency_score(values)
        return 100.0 if values.size < 2

        cv = calculate_coefficient_variation(values)
        [100 - cv, 0].max.round(2)
      end
    end
  end
end
