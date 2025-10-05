# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing deployment frequency metrics
    class DeploymentMetrics
      attr_reader :total_deployments, :deployments_per_week, :avg_days_between_deployments,
                  :days_since_last_deployment, :frequency_category, :period_days, :deployment_intervals

      def initialize(total_deployments:, deployments_per_week:, avg_days_between_deployments:,
                     days_since_last_deployment:, frequency_category:, period_days:,
                     deployment_intervals: [])
        @total_deployments = total_deployments
        @deployments_per_week = deployments_per_week
        @avg_days_between_deployments = avg_days_between_deployments
        @days_since_last_deployment = days_since_last_deployment
        @frequency_category = frequency_category
        @period_days = period_days
        @deployment_intervals = deployment_intervals.freeze
        freeze
      end

      def high_frequency?
        %w[high very_high].include?(frequency_category)
      end

      def low_frequency?
        frequency_category == 'low'
      end

      def regular_deployment_schedule?
        return false if deployment_intervals.empty?

        variance = calculate_interval_variance
        variance < avg_days_between_deployments * 0.5
      end

      def deployment_velocity_score
        case frequency_category
        when 'very_high' then 100
        when 'high' then 80
        when 'moderate' then 60
        when 'low' then 30
        else 0
        end
      end

      def stale_deployment?
        days_since_last_deployment > 30
      end

      def to_h
        {
          total_deployments: total_deployments,
          deployments_per_week: deployments_per_week,
          avg_days_between_deployments: avg_days_between_deployments,
          days_since_last_deployment: days_since_last_deployment,
          frequency_category: frequency_category,
          period_days: period_days,
          deployment_intervals: deployment_intervals,
        }
      end

      private

      def calculate_interval_variance
        return 0 if deployment_intervals.empty?

        mean = deployment_intervals.sum.to_f / deployment_intervals.size
        variance_sum = deployment_intervals.sum { |interval| (interval - mean)**2 }
        Math.sqrt(variance_sum / deployment_intervals.size)
      end
    end
  end
end
