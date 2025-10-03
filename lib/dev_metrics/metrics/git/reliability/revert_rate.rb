# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes the rate of reverted commits and problematic changes
        class RevertRate < BaseMetric
          def metric_name
            'revert_rate'
          end

          def description
            'Analyzes commit revert patterns to identify code quality issues'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commits(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            revert_data = ValueObjects::RevertAnalysisData.new(commits_data)

            {
              overall: revert_data.overall_stats,
              by_author: revert_data.author_stats,
              revert_details: revert_data.revert_details,
              time_patterns: revert_data.time_patterns,
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            revert_data = ValueObjects::RevertAnalysisData.new(commits_data)
            super.merge(extract_metadata_from_revert_data(revert_data))
          end

          def extract_metadata_from_revert_data(revert_data)
            overall = revert_data.overall_stats

            {
              total_commits: overall[:total_commits],
              revert_rate: overall[:revert_rate],
              stability_score: overall[:stability_score],
              high_risk_authors: revert_data.high_risk_authors_count,
              most_reverted_author: revert_data.most_reverted_author,
              revert_frequency: revert_data.revert_frequency,
            }
          end

          private

          def data_points_description
            'commits'
          end
        end
      end
    end
  end
end
