# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes lines added, removed, and net changes by author
        class LinesChanged < BaseMetric
          def metric_name
            'lines_changed'
          end

          def description
            'Lines added, removed, and net changes by developer'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            author_data = Services::AuthorStatsAggregator.new(commits_data).aggregate
            change_metrics = Services::ChangeMetricsCalculator.new(author_data).calculate
            sorted_metrics = Services::AuthorStatsSorter.new(change_metrics).sort_by_total_changes

            sorted_metrics.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            author_data = Services::AuthorStatsAggregator.new(commits_data).aggregate
            change_metrics = Services::ChangeMetricsCalculator.new(author_data).calculate

            super.merge(change_metrics.metadata_hash)
          end
        end
      end
    end
  end
end
