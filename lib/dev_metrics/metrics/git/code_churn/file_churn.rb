module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies files with high churn (frequent changes)
        class FileChurn < DevMetrics::BaseMetric
          def metric_name
            'file_churn'
          end

          def description
            'Files with highest churn (total lines added + deleted)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            file_stats = Hash.new { |h, k| h[k] = { additions: 0, deletions: 0, commits: 0, authors: Set.new } }

            commits_data.each do |commit|
              commit[:files_changed].each do |file_change|
                filename = file_change[:filename]
                file_stats[filename][:additions] += file_change[:additions]
                file_stats[filename][:deletions] += file_change[:deletions]
                file_stats[filename][:commits] += 1
                file_stats[filename][:authors] << commit[:author_name]
              end
            end

            # Calculate churn and additional metrics
            result = {}
            file_stats.each do |filename, stats|
              total_churn = stats[:additions] + stats[:deletions]

              result[filename] = {
                total_churn: total_churn,
                additions: stats[:additions],
                deletions: stats[:deletions],
                net_changes: stats[:additions] - stats[:deletions],
                commits: stats[:commits],
                authors_count: stats[:authors].size,
                authors: stats[:authors].to_a,
                avg_churn_per_commit: stats[:commits] > 0 ? (total_churn.to_f / stats[:commits]).round(2) : 0,
                churn_ratio: total_churn > 0 ? (stats[:deletions].to_f / total_churn * 100).round(1) : 0
              }
            end

            # Sort by total churn (highest first)
            result.sort_by { |_, stats| -stats[:total_churn] }.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            all_files = commits_data.flat_map { |c| c[:files_changed].map { |f| f[:filename] } }.uniq
            total_file_changes = commits_data.sum { |c| c[:files_changed].size }

            # Calculate hotspot categories
            result = compute_metric(commits_data)
            high_churn_files = result.select { |_, s| s[:total_churn] > 1000 }.size
            medium_churn_files = result.select { |_, s| s[:total_churn] > 100 && s[:total_churn] <= 1000 }.size
            low_churn_files = result.select { |_, s| s[:total_churn] <= 100 }.size

            super.merge(
              total_files_changed: all_files.size,
              total_file_changes: total_file_changes,
              avg_changes_per_file: all_files.size > 0 ? (total_file_changes.to_f / all_files.size).round(2) : 0,
              high_churn_files: high_churn_files,
              medium_churn_files: medium_churn_files,
              low_churn_files: low_churn_files,
              hotspot_percentage: all_files.size > 0 ? (high_churn_files.to_f / all_files.size * 100).round(1) : 0
            )
          end
        end
      end
    end
  end
end
