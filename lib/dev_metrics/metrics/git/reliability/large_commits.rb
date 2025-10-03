# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes large commits that may indicate risky development practices
        class LargeCommits < BaseMetric
          def metric_name
            'large_commits'
          end

          def description
            'Identifies unusually large commits that may indicate poor development practices'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            size_data = ValueObjects::CommitSizeData.new(commits_data)
            risk_data = ValueObjects::RiskAnalysisData.new(commits_data, size_data)
            stats_calculator = create_statistics_calculator(commits_data, size_data)

            build_metric_result(size_data, risk_data, stats_calculator)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            super.merge(extract_metadata_from_result(result))
          end

          def extract_metadata_from_result(result)
            overall = result[:overall]

            {
              large_commit_ratio: overall[:large_commit_ratio],
              risk_score: overall[:risk_score],
              avg_commit_size: overall[:avg_commit_size],
              high_risk_authors: result[:by_author].count { |_, stats| stats[:risk_score] > 20.0 },
              largest_commit_author: find_largest_commit_author(result[:by_author]),
              size_threshold_large: result[:thresholds][:large],
              size_threshold_huge: result[:thresholds][:huge],
            }
          end

          private

          def create_statistics_calculator(commits_data, size_data)
            Services::CommitStatisticsCalculator.new(commits_data, size_data.commit_sizes)
          end

          def build_metric_result(size_data, risk_data, stats_calculator)
            {
              overall: build_overall_stats(size_data, risk_data, stats_calculator),
              thresholds: size_data.thresholds,
              by_author: stats_calculator.calculate_author_stats(size_data.thresholds),
              largest_commits: size_data.largest_commits,
              size_distribution: stats_calculator.analyze_size_distribution,
              risk_patterns: risk_data.risk_patterns,
            }
          end

          def build_overall_stats(size_data, risk_data, _stats_calculator)
            {
              total_commits: size_data.total_commits,
              large_commits: size_data.large_commits_count,
              huge_commits: size_data.huge_commits_count,
              large_commit_ratio: calculate_ratio(size_data.large_commits_count, size_data.total_commits),
              huge_commit_ratio: calculate_ratio(size_data.huge_commits_count, size_data.total_commits),
              risk_score: risk_data.risk_score,
              avg_commit_size: size_data.average_commit_size,
            }
          end

          def calculate_ratio(count, total)
            return 0.0 if total.zero?

            (count.to_f / total * 100).round(2)
          end

          def find_largest_commit_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:max_commit_size] }&.first
          end

          def data_points_description
            'commits'
          end
        end
      end
    end
  end
end
