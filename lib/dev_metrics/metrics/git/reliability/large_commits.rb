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

            analyzer = Services::LargeCommitsAnalyzer.new(commits_data)
            analyzer.analyze
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            super.merge(extract_metadata_from_result(result))
          end

          private

          def extract_metadata_from_result(result)
            return {} if result.empty? || !result[:overall]

            overall = result[:overall]
            by_author = result[:by_author] || {}
            thresholds = result[:thresholds] || {}

            {
              large_commit_ratio: overall[:large_commit_ratio] || 0.0,
              risk_score: overall[:risk_score] || 0.0,
              avg_commit_size: overall[:avg_commit_size] || 0.0,
              high_risk_authors: count_high_risk_authors(by_author),
              largest_commit_author: find_largest_commit_author(by_author),
              size_threshold_large: thresholds[:large] || 0,
              size_threshold_huge: thresholds[:huge] || 0
            }
          end

          def count_high_risk_authors(by_author)
            by_author.count { |_, stats| (stats[:risk_score] || 0) > 20.0 }
          end

          def find_largest_commit_author(by_author)
            return nil if by_author.empty?

            by_author.max_by { |_, stats| stats[:max_commit_size] || 0 }&.first
          end

          def data_points_description
            'commits'
          end
        end
      end
    end
  end
end
