module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Calculates commits per developer over a time period
        class CommitsPerDeveloper < DevMetrics::BaseMetric
          def metric_name
            'commits_per_developer'
          end

          def description
            'Number of commits per developer in the specified time period'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_contributors(time_period)
          end

          def compute_metric(contributors_data)
            return {} if contributors_data.empty?
            
            contributors_by_commits = contributors_data.sort_by { |c| -c[:commit_count] }
            
            result = {}
            contributors_by_commits.each do |contributor|
              key = contributor[:email] ? 
                    "#{contributor[:name]} <#{contributor[:email]}>" : 
                    contributor[:name]
              result[key] = contributor[:commit_count]
            end
            
            result
          end

          def build_metadata(contributors_data)
            super.merge(
              total_contributors: contributors_data.size,
              total_commits: contributors_data.sum { |c| c[:commit_count] },
              avg_commits_per_contributor: contributors_data.empty? ? 0 : 
                (contributors_data.sum { |c| c[:commit_count] }.to_f / contributors_data.size).round(2),
              top_contributor: contributors_data.max_by { |c| c[:commit_count] }&.dig(:name)
            )
          end
        end
      end
    end
  end
end