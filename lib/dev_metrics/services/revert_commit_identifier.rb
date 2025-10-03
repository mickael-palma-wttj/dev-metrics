# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for identifying revert and reverted commits
    class RevertCommitIdentifier
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def identify_revert_commits
        commits_data.select { |commit| revert_commit?(commit) }
      end

      def identify_reverted_commits(revert_commits)
        reverted_hashes = extract_reverted_hashes(revert_commits)

        commits_data.select do |commit|
          commit_matches_hash?(commit, reverted_hashes)
        end
      end

      private

      attr_reader :commits_data

      def revert_commit?(commit)
        message = commit[:message].strip
        revert_patterns.any? { |pattern| message.match?(pattern) }
      end

      def revert_patterns
        [
          /^Revert\s+/i,
          /^This reverts commit/i,
          /reverts?\s+commit/i,
          /^Rollback/i,
          /^Undo\s+/i,
        ]
      end

      def extract_reverted_hashes(revert_commits)
        reverted_hashes = Set.new

        revert_commits.each do |revert_commit|
          hash_match = revert_commit[:message].match(/([a-f0-9]{7,40})/i)
          reverted_hashes.add(hash_match[1].downcase) if hash_match
        end

        reverted_hashes
      end

      def commit_matches_hash?(commit, reverted_hashes)
        short_hash = commit[:hash][0..6].downcase
        full_hash = commit[:hash].downcase

        reverted_hashes.include?(short_hash) || reverted_hashes.include?(full_hash)
      end
    end
  end
end
