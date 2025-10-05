# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing complete deployment analysis summary
    class DeploymentSummary
      attr_reader :frequency_metrics, :deployments, :patterns, :stability, :trends, :quality_metrics

      def initialize(frequency_metrics:, deployments:, patterns:, stability:, trends:, quality_metrics:)
        @frequency_metrics = frequency_metrics
        @deployments = deployments.freeze
        @patterns = patterns.freeze
        @stability = stability.freeze
        @trends = trends.freeze
        @quality_metrics = quality_metrics.freeze
        freeze
      end

      def deployment_count
        deployments.size
      end

      def production_releases
        deployments.select(&:production_release?)
      end

      def merge_deployments
        deployments.select(&:merge_deployment?)
      end

      def latest_deployment
        deployments.first
      end

      def deployment_health_score
        frequency_score = frequency_metrics.deployment_velocity_score
        stability_score = (stability[:consistency_score] || 0) * 100
        quality_score = (quality_metrics[:deployment_velocity] || 0) * 100

        (frequency_score + stability_score + quality_score) / 3.0
      end

      def deployment_maturity_level
        health_score = deployment_health_score

        case health_score
        when 80..100 then 'excellent'
        when 60..79 then 'good'
        when 40..59 then 'moderate'
        when 20..39 then 'poor'
        else 'needs_improvement'
        end
      end

      def to_h
        {
          overall: frequency_metrics.to_h,
          deployments: deployments.first(20).map(&:to_h),
          patterns: patterns,
          stability: stability,
          trends: trends,
          quality_metrics: quality_metrics,
        }
      end

      def metadata_hash
        {
          total_deployments: frequency_metrics.total_deployments,
          deployments_per_week: frequency_metrics.deployments_per_week,
          avg_days_between: frequency_metrics.avg_days_between_deployments,
          deployment_consistency: stability[:consistency_score],
          deployment_velocity: quality_metrics[:deployment_velocity],
          last_deployment_days_ago: frequency_metrics.days_since_last_deployment,
        }
      end
    end
  end
end
