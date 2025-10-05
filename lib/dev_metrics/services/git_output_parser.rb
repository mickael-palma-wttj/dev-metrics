# frozen_string_literal: true

require_relative 'git_commit_parser'
require_relative 'git_metadata_parser'

module DevMetrics
  module Services
    # Service responsible for parsing various Git command outputs
    class GitOutputParser
      def initialize(repository_name)
        @repository_name = repository_name
        @commit_parser = GitCommitParser.new(repository_name)
        @metadata_parser = GitMetadataParser.new(repository_name)
      end

      def parse_commits(output)
        commit_parser.parse_commits(output)
      end

      def parse_commit_stats(output)
        commit_parser.parse_commit_stats(output)
      end

      def parse_file_changes(output)
        metadata_parser.parse_file_changes(output)
      end

      def parse_contributors(output)
        metadata_parser.parse_contributors(output)
      end

      def parse_tags(output)
        metadata_parser.parse_tags(output)
      end

      private

      attr_reader :repository_name, :commit_parser, :metadata_parser
    end
  end
end
