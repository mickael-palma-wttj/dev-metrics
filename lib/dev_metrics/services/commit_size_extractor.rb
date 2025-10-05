# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for extracting commit sizes from commit data
    # Follows Single Responsibility Principle - only handles size extraction
    class CommitSizeExtractor
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def extract_sizes
        commits_data.map { |commit| commit[:additions] + commit[:deletions] }
      end

      private

      attr_reader :commits_data
    end
  end
end
