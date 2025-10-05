# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for aggregating author statistics from commit data
    class AuthorStatsAggregator
      def initialize(commits)
        @commits = commits
      end

      def aggregate
        authors = Hash.new { |h, k| h[k] = { additions: 0, deletions: 0, commits: 0 } }

        @commits.each do |commit|
          author_key = extract_author_key(commit)
          update_author_data(authors[author_key], commit)
        end

        authors.map { |name, data| data.merge(name: name) }
      end

      private

      def extract_author_key(commit)
        if commit[:author_email]
          "#{commit[:author_name]} <#{commit[:author_email]}>"
        else
          commit[:author_name] || commit[:author] || 'Unknown'
        end
      end

      def update_author_data(author_data, commit)
        author_data[:additions] += commit[:additions] || 0
        author_data[:deletions] += commit[:deletions] || 0
        author_data[:commits] += 1
      end
    end
  end
end
