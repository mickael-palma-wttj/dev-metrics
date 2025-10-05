# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for transforming raw contributor data into value objects
    # Follows Single Responsibility Principle - only handles data transformation
    class ContributorTransformer
      def initialize(contributors_data)
        @contributors_data = contributors_data
      end

      def transform
        contributors_data.map do |contributor_data|
          ValueObjects::Contributor.new(
            name: contributor_data[:name],
            email: contributor_data[:email],
            commit_count: contributor_data[:commit_count]
          )
        end
      end

      private

      attr_reader :contributors_data
    end
  end
end
