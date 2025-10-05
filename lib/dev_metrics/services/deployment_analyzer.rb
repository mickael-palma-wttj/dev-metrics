# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for orchestrating comprehensive deployment analysis
    class DeploymentAnalyzer
      def initialize(tags_data, commits_data, branches_data, time_period)
        @tags_data = tags_data
        @commits_data = commits_data
        @branches_data = branches_data
        @time_period = time_period
      end

      def analyze
        deployments = identify_deployments
        frequency_metrics = calculate_frequency_metrics(deployments)

        ValueObjects::DeploymentSummary.new(
          frequency_metrics: frequency_metrics,
          deployments: deployments,
          patterns: analyze_patterns(deployments),
          stability: analyze_stability(deployments),
          trends: analyze_trends(deployments),
          quality_metrics: calculate_quality_metrics(deployments)
        )
      end

      private

      attr_reader :tags_data, :commits_data, :branches_data, :time_period

      def identify_deployments
        identifier = Services::DeploymentIdentifier.new(tags_data, commits_data, branches_data)
        deployment_hashes = identifier.identify_deployments

        deployment_hashes.map { |hash| create_deployment_value_object(hash) }
      end

      def create_deployment_value_object(deployment_hash)
        ValueObjects::Deployment.new(
          type: deployment_hash[:type],
          identifier: deployment_hash[:identifier],
          date: deployment_hash[:date],
          commit_hash: deployment_hash[:commit_hash],
          deployment_method: deployment_hash[:deployment_method],
          message: deployment_hash[:message]
        )
      end

      def calculate_frequency_metrics(deployments)
        calculator = Services::FrequencyCalculator.new(deployments, time_period)
        metrics_hash = calculator.calculate_frequency_metrics

        ValueObjects::DeploymentMetrics.new(
          total_deployments: metrics_hash[:total_deployments],
          deployments_per_week: metrics_hash[:deployments_per_week],
          avg_days_between_deployments: metrics_hash[:avg_days_between_deployments],
          days_since_last_deployment: metrics_hash[:days_since_last_deployment],
          frequency_category: metrics_hash[:frequency_category],
          period_days: metrics_hash[:period_days],
          deployment_intervals: metrics_hash[:deployment_intervals]
        )
      end

      def analyze_patterns(deployments)
        pattern_analyzer = Services::DeploymentPatternAnalyzer.new(deployments)
        pattern_analyzer.analyze_deployment_patterns
      end

      def analyze_stability(deployments)
        stability_analyzer = Services::DeploymentStabilityAnalyzer.new(deployments, commits_data)
        stability_analyzer.calculate_deployment_stability(commits_data)
      end

      def analyze_trends(deployments)
        pattern_analyzer = Services::DeploymentPatternAnalyzer.new(deployments)
        pattern_analyzer.analyze_frequency_trends
      end

      def calculate_quality_metrics(deployments)
        stability_analyzer = Services::DeploymentStabilityAnalyzer.new(deployments, commits_data)
        stability_analyzer.calculate_quality_metrics
      end
    end
  end
end
