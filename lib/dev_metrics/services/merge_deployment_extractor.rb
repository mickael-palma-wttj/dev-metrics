# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for identifying merge-based deployments from commit data
    class MergeDeploymentExtractor
      MERGE_PATTERNS = [
        /^Merge pull request/i,
        /^Merge branch/i,
        /^Merge remote-tracking branch/i,
        /^Merged in/i,
      ].freeze

      MAIN_BRANCH_NAMES = %w[main master production prod].freeze

      def initialize(commits_data, branches_data)
        @commits_data = commits_data
        @branches_data = branches_data
      end

      def extract
        merge_commits = identify_merge_commits

        merge_commits.map do |commit|
          {
            type: 'merge_deployment',
            identifier: commit[:hash][0..7],
            date: commit[:date],
            commit_hash: commit[:hash],
            deployment_method: 'merge',
            message: commit[:message],
          }
        end
      end

      private

      attr_reader :commits_data, :branches_data

      def identify_merge_commits
        commits_data.select { |commit| merge_commit?(commit) }
      end

      def merge_commit?(commit)
        message = commit[:message].strip
        MERGE_PATTERNS.any? { |pattern| message.match?(pattern) }
      end
    end
  end
end
