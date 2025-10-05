# frozen_string_literal: true

module DevMetrics
  module Services
    # Service class for identifying different types of deployments from git data
    class DeploymentIdentifier
      def initialize(tags_data, commits_data, branches_data)
        @tags_data = tags_data
        @commits_data = commits_data
        @branches_data = branches_data
      end

      def identify_deployments
        production_deployments = extract_production_deployments
        merge_deployments = extract_merge_deployments

        all_deployments = production_deployments + merge_deployments
        unique_deployments = deduplicate_deployments(all_deployments)

        unique_deployments.sort_by { |d| d[:date] }.reverse
      end

      private

      attr_reader :tags_data, :commits_data, :branches_data

      def extract_production_deployments
        ProductionDeploymentExtractor.new(tags_data).extract
      end

      def extract_merge_deployments
        MergeDeploymentExtractor.new(commits_data, branches_data).extract
      end

      def deduplicate_deployments(deployments)
        DeploymentDeduplicator.new(deployments).deduplicate
      end
    end
  end
end
