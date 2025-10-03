module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes lines added, removed, and net changes by author
        class LinesChanged < DevMetrics::BaseMetric
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
            
            author_stats = Hash.new { |h, k| h[k] = { additions: 0, deletions: 0, commits: 0 } }
            
            commits_data.each do |commit|
              author_key = commit[:author_email] ? 
                          "#{commit[:author_name]} <#{commit[:author_email]}>" : 
                          commit[:author_name]
              
              author_stats[author_key][:additions] += commit[:additions]
              author_stats[author_key][:deletions] += commit[:deletions]
              author_stats[author_key][:commits] += 1
            end
            
            # Calculate net changes and additional metrics
            result = {}
            author_stats.each do |author, stats|
              net_changes = stats[:additions] - stats[:deletions]
              total_changes = stats[:additions] + stats[:deletions]
              
              result[author] = {
                additions: stats[:additions],
                deletions: stats[:deletions],
                net_changes: net_changes,
                total_changes: total_changes,
                commits: stats[:commits],
                avg_changes_per_commit: stats[:commits] > 0 ? (total_changes.to_f / stats[:commits]).round(2) : 0,
                churn_ratio: total_changes > 0 ? (stats[:deletions].to_f / total_changes * 100).round(1) : 0
              }
            end
            
            # Sort by total changes (most active first)
            result.sort_by { |_, stats| -stats[:total_changes] }.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?
            
            total_additions = commits_data.sum { |c| c[:additions] }
            total_deletions = commits_data.sum { |c| c[:deletions] }
            total_changes = total_additions + total_deletions
            
            authors = commits_data.map { |c| c[:author_name] }.uniq
            
            super.merge(
              total_additions: total_additions,
              total_deletions: total_deletions,
              net_additions: total_additions - total_deletions,
              total_changes: total_changes,
              overall_churn_ratio: total_changes > 0 ? (total_deletions.to_f / total_changes * 100).round(1) : 0,
              contributing_authors: authors.size,
              avg_changes_per_author: authors.size > 0 ? (total_changes.to_f / authors.size).round(2) : 0
            )
          end
        end
      end
    end
  end
end