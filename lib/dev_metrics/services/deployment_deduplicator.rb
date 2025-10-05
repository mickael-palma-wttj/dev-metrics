# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for removing duplicate deployments from the same day
    class DeploymentDeduplicator
      def initialize(deployments)
        @deployments = deployments
      end

      def deduplicate
        deployments_by_date = group_by_date

        deployments_by_date.map do |_date, day_deployments|
          select_best_deployment(day_deployments)
        end.compact
      end

      private

      attr_reader :deployments

      def group_by_date
        deployments.group_by { |deployment| deployment[:date].strftime('%Y-%m-%d') }
      end

      def select_best_deployment(day_deployments)
        production_release = find_production_release(day_deployments)
        return production_release if production_release

        find_latest_merge(day_deployments)
      end

      def find_production_release(day_deployments)
        day_deployments.find { |deployment| deployment[:type] == 'production_release' }
      end

      def find_latest_merge(day_deployments)
        merge_deployments = day_deployments.select { |d| d[:type] == 'merge_deployment' }
        merge_deployments.max_by { |deployment| deployment[:date] }
      end
    end
  end
end
