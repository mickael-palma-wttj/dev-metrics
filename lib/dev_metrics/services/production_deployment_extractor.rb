# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for identifying production deployments from tag data
    class ProductionDeploymentExtractor
      def initialize(tags_data)
        @tags_data = tags_data
      end

      def extract
        production_tags = Utils::ProductionTagPatterns.filter_production_tags(tags_data)

        production_tags.map do |tag|
          {
            type: 'production_release',
            identifier: tag[:name] || tag[:tag_name],
            date: tag[:date],
            commit_hash: tag[:commit_hash],
            deployment_method: 'tag',
          }
        end
      end

      private

      attr_reader :tags_data
    end
  end
end
