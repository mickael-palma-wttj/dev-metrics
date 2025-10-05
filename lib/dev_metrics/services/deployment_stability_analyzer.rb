# frozen_string_literal: true

module DevMetrics
  module Services
    # Service class for calculating deployment stability and quality metrics
    class DeploymentStabilityAnalyzer
      def initialize(deployments, commits_data)
        @deployments = deployments
        @commits_data = commits_data
      end

      def calculate_deployment_stability(_commits_data)
        return default_stability_metrics if deployments.empty?

        deployment_dates = deployments.map { |d| extract_date(d) }.sort
        intervals = calculate_intervals(deployment_dates)

        return default_stability_metrics if intervals.empty?

        # Calculate consistency metrics
        avg_interval = intervals.sum.to_f / intervals.size
        variance = intervals.sum { |interval| (interval - avg_interval)**2 } / intervals.size
        std_deviation = Math.sqrt(variance)
        coefficient_of_variation = avg_interval.positive? ? (std_deviation / avg_interval) : 1.0

        # Lower coefficient of variation means more consistent
        consistency_score = [1.0 - coefficient_of_variation, 0.0].max
        predictability = categorize_predictability(consistency_score)

        {
          consistency_score: consistency_score.round(3),
          predictability: predictability,
          avg_interval_days: avg_interval.round(2),
          std_deviation_days: std_deviation.round(2),
          coefficient_of_variation: coefficient_of_variation.round(3),
        }
      end

      def calculate_quality_metrics
        return {} if deployments.empty? || commits_data.empty?

        # Calculate commits per deployment
        deployment_hashes = deployments.map { |d| extract_commit_hash(d) }.compact
        related_commits = commits_data.select { |c| deployment_hashes.include?(c[:hash]) }

        commits_per_deployment = deployments.empty? ? 0 : (related_commits.size.to_f / deployments.size)

        {
          deployment_velocity: categorize_velocity(commits_per_deployment),
          batch_size_category: categorize_batch_size(commits_per_deployment),
          commits_per_deployment: commits_per_deployment.round(2),
          deployment_efficiency: calculate_deployment_efficiency,
        }
      end

      private

      attr_reader :deployments, :commits_data

      def calculate_intervals(sorted_dates)
        return [] if sorted_dates.size < 2

        intervals = []
        (1...sorted_dates.size).each do |i|
          interval_days = (sorted_dates[i] - sorted_dates[i - 1]).to_i
          intervals << interval_days
        end
        intervals
      end

      def default_stability_metrics
        {
          consistency_score: 0.0,
          predictability: 'unknown',
          avg_interval_days: 0.0,
          std_deviation_days: 0.0,
          coefficient_of_variation: 1.0,
        }
      end

      def categorize_predictability(consistency_score)
        case consistency_score
        when 0.8..1.0
          'very_predictable'
        when 0.6...0.8
          'predictable'
        when 0.4...0.6
          'somewhat_predictable'
        else
          'unpredictable'
        end
      end

      def categorize_velocity(commits_per_deployment)
        case commits_per_deployment
        when 0...5
          'fast'
        when 5...15
          'moderate'
        when 15...30
          'slow'
        else
          'very_slow'
        end
      end

      def categorize_batch_size(commits_per_deployment)
        case commits_per_deployment
        when 0...5
          'small'
        when 5...15
          'medium'
        when 15...30
          'large'
        else
          'very_large'
        end
      end

      def calculate_deployment_efficiency
        return 0.0 if deployments.empty?

        # Simple efficiency based on deployment frequency and consistency
        total_deployments = deployments.size

        # More deployments with better consistency = higher efficiency
        stability = calculate_deployment_stability(commits_data)
        consistency = stability[:consistency_score]

        # Normalize efficiency score (0-100)
        base_efficiency = [total_deployments * 10, 100].min
        consistency_bonus = consistency * 20

        (base_efficiency + consistency_bonus).round(1)
      end

      def extract_date(deployment)
        # Handle both hash and value object formats
        deployment.respond_to?(:date) ? deployment.date : deployment[:date]
      end

      def extract_commit_hash(deployment)
        # Handle both hash and value object formats
        deployment.respond_to?(:commit_hash) ? deployment.commit_hash : deployment[:commit_hash]
      end
    end
  end
end
