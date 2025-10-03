module DevMetrics
  module Metrics
    # Registry for Git-based metrics, providing discovery and organization
    class GitMetricsRegistry
      METRIC_CATEGORIES = {
        commit_activity: {
          name: 'Commit Activity',
          description: 'Developer activity and commit patterns',
          metrics: {
            commits_per_developer: 'DevMetrics::Metrics::Git::CommitActivity::CommitsPerDeveloper',
            commit_size: 'DevMetrics::Metrics::Git::CommitActivity::CommitSize',
            commit_frequency: 'DevMetrics::Metrics::Git::CommitActivity::CommitFrequency',
            lines_changed: 'DevMetrics::Metrics::Git::CommitActivity::LinesChanged'
          }
        },
        code_churn: {
          name: 'Code Churn',
          description: 'File change patterns and ownership analysis',
          metrics: {
            file_churn: 'DevMetrics::Metrics::Git::CodeChurn::FileChurn',
            authors_per_file: 'DevMetrics::Metrics::Git::CodeChurn::AuthorsPerFile',
            file_ownership: 'DevMetrics::Metrics::Git::CodeChurn::FileOwnership',
            co_change_pairs: 'DevMetrics::Metrics::Git::CodeChurn::CoChangePairs'
          }
        },
        reliability: {
          name: 'Reliability',
          description: 'Code quality and stability indicators',
          metrics: {
            revert_rate: 'DevMetrics::Metrics::Git::Reliability::RevertRate',
            bugfix_ratio: 'DevMetrics::Metrics::Git::Reliability::BugfixRatio',
            large_commits: 'DevMetrics::Metrics::Git::Reliability::LargeCommits'
          }
        },
        flow: {
          name: 'Flow',
          description: 'Development flow and deployment metrics',
          metrics: {
            lead_time: 'DevMetrics::Metrics::Git::Flow::LeadTime',
            deployment_frequency: 'DevMetrics::Metrics::Git::Flow::DeploymentFrequency'
          }
        }
      }.freeze

      class << self
        def all_categories
          METRIC_CATEGORIES.keys
        end

        def category_info(category)
          METRIC_CATEGORIES[category&.to_sym]
        end

        def all_metrics
          @all_metrics ||= METRIC_CATEGORIES.flat_map do |category, info|
            info[:metrics].keys
          end
        end

        def metrics_for_category(category)
          category_info = category_info(category)
          return [] unless category_info

          category_info[:metrics].keys
        end

        def metric_class(metric_name)
          METRIC_CATEGORIES.each do |_, category_info|
            class_name = category_info[:metrics][metric_name.to_sym]
            return constantize_metric(class_name) if class_name
          end
          nil
        end

        def create_metric(metric_name, repository, options = {})
          metric_class = metric_class(metric_name)
          return nil unless metric_class

          time_period = options.delete(:time_period)
          metric_class.new(repository, time_period, options)
        end

        def filter_metrics(requested_metrics, categories = nil)
          return all_metrics if requested_metrics == 'all' && categories.nil?

          result = []

          # Add metrics by categories
          if categories
            Array(categories).each do |category|
              result.concat(metrics_for_category(category))
            end
          end

          # Add specific metrics
          if requested_metrics != 'all'
            requested_list = Array(requested_metrics).map(&:to_sym)
            result.concat(requested_list.select { |m| all_metrics.include?(m) })
          elsif categories.nil?
            result = all_metrics
          end

          result.uniq
        end

        def metrics_summary
          summary = {}
          METRIC_CATEGORIES.each do |category, info|
            summary[category] = {
              name: info[:name],
              description: info[:description],
              count: info[:metrics].size,
              metrics: info[:metrics].keys
            }
          end
          summary
        end

        private

        def constantize_metric(class_name)
          # Safely constantize the metric class with Zeitwerk autoloading
          Object.const_get(class_name)
        rescue NameError
          # Try manual path resolution to trigger autoloading
          begin
            class_name.split('::').reduce(Object) do |constant, name|
              constant.const_get(name)
            end
          rescue NameError => e
            puts "Failed to load metric class: #{class_name} - #{e.message}"
            nil
          end
        end
      end
    end
  end
end
