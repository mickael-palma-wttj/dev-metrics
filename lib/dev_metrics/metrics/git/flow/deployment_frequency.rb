# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Flow
        # Analyzes deployment frequency and release patterns
        class DeploymentFrequency < BaseMetric
          def metric_name
            'deployment_frequency'
          end

          def description
            'Measures deployment frequency and release cadence patterns'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            {
              tags: collector.collect_tags,
              commits: collector.collect_commits(time_period),
              branches: collector.collect_branches,
            }
          end

          def compute_metric(data)
            tags_data = data[:tags] || []
            commits_data = data[:commits] || []
            branches_data = data[:branches] || []

            return {} if tags_data.empty? && commits_data.empty?

            analyzer = Services::DeploymentAnalyzer.new(tags_data, commits_data, branches_data, time_period)
            deployment_summary = analyzer.analyze

            deployment_summary.to_h
          end

          def build_metadata(data)
            return super if data.empty?

            tags_data = data[:tags] || []
            commits_data = data[:commits] || []
            branches_data = data[:branches] || []

            analyzer = Services::DeploymentAnalyzer.new(tags_data, commits_data, branches_data, time_period)
            deployment_summary = analyzer.analyze

            super.merge(deployment_summary.metadata_hash)
          end

          private

          def data_points_description
            'deployments'
          end
        end
      end
    end
  end
end
