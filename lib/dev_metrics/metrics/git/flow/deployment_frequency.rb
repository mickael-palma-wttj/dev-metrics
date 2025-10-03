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

            # Identify different types of deployments
            deployments = deployment_identifier(tags_data, commits_data, branches_data).identify_deployments

            # Calculate frequency metrics
            frequency_metrics = frequency_calculator(deployments).calculate_frequency_metrics

            # Analyze deployment patterns
            pattern_analyzer = Services::DeploymentPatternAnalyzer.new(deployments)
            patterns = pattern_analyzer.analyze_deployment_patterns

            # Calculate stability metrics
            stability_analyzer = Services::DeploymentStabilityAnalyzer.new(deployments, commits_data)
            stability = stability_analyzer.calculate_deployment_stability(commits_data)

            {
              overall: frequency_metrics,
              deployments: deployments.first(20),
              patterns: patterns,
              stability: stability,
              trends: pattern_analyzer.analyze_frequency_trends,
              quality_metrics: stability_analyzer.calculate_quality_metrics,
            }
          end

          def build_metadata(data)
            return super if data.empty?

            result = compute_metric(data)
            overall = result[:overall]

            super.merge(
              total_deployments: overall[:total_deployments],
              deployments_per_week: overall[:deployments_per_week],
              avg_days_between: overall[:avg_days_between_deployments],
              deployment_consistency: result[:stability][:consistency_score],
              deployment_velocity: result[:quality_metrics][:deployment_velocity],
              last_deployment_days_ago: overall[:days_since_last_deployment]
            )
          end

          private

          def deployment_identifier(tags_data, commits_data, branches_data)
            Services::DeploymentIdentifier.new(tags_data, commits_data, branches_data)
          end

          def frequency_calculator(deployments)
            Services::FrequencyCalculator.new(deployments, time_period)
          end

          def data_points_description
            'deployments'
          end
        end
      end
    end
  end
end
