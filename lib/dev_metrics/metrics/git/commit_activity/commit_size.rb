module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes commit size based on lines added and deleted
        class CommitSize < DevMetrics::BaseMetric
          def metric_name
            'commit_size'
          end

          def description
            'Distribution of commit sizes by lines changed (added + deleted)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            sizes = commits_data.map { |commit| commit[:additions] + commit[:deletions] }

            {
              total_commits: commits_data.size,
              average_size: (sizes.sum.to_f / sizes.size).round(2),
              median_size: calculate_median(sizes),
              min_size: sizes.min,
              max_size: sizes.max,
              small_commits: sizes.count { |s| s <= 10 },
              medium_commits: sizes.count { |s| s > 10 && s <= 100 },
              large_commits: sizes.count { |s| s > 100 && s <= 500 },
              huge_commits: sizes.count { |s| s > 500 },
              distribution_percentages: calculate_distribution_percentages(sizes)
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            total_changes = commits_data.sum { |c| c[:additions] + c[:deletions] }
            total_additions = commits_data.sum { |c| c[:additions] }
            total_deletions = commits_data.sum { |c| c[:deletions] }

            super.merge(
              total_lines_changed: total_changes,
              total_additions: total_additions,
              total_deletions: total_deletions,
              net_lines: total_additions - total_deletions,
              files_per_commit: (commits_data.sum { |c| c[:files_changed].size }.to_f / commits_data.size).round(2)
            )
          end

          private

          def calculate_median(sizes)
            sorted = sizes.sort
            mid = sorted.length / 2

            if sorted.length.odd?
              sorted[mid]
            else
              ((sorted[mid - 1] + sorted[mid]) / 2.0).round(2)
            end
          end

          def calculate_distribution_percentages(sizes)
            return {} if sizes.empty?

            total = sizes.size
            {
              small_percent: ((sizes.count { |s| s <= 10 }.to_f / total) * 100).round(1),
              medium_percent: ((sizes.count { |s| s > 10 && s <= 100 }.to_f / total) * 100).round(1),
              large_percent: ((sizes.count { |s| s > 100 && s <= 500 }.to_f / total) * 100).round(1),
              huge_percent: ((sizes.count { |s| s > 500 }.to_f / total) * 100).round(1)
            }
          end
        end
      end
    end
  end
end
