# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for aggregating file data from commit history
    # Handles data collection and processing for ownership analysis
    class FileDataAggregatorService
      # Aggregates file data from commit history
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] aggregated file data by filename
      def aggregate_file_data(commits_data)
        file_data = create_empty_file_data_hash

        commits_data.each do |commit|
          process_commit_files(commit, file_data)
        end

        file_data
      end

      private

      # Creates empty file data hash structure
      def create_empty_file_data_hash
        Hash.new do |h, k|
          h[k] = { commits: [], authors: Hash.new(0), total_changes: 0 }
        end
      end

      # Processes all files in a single commit
      def process_commit_files(commit, file_data)
        commit[:files_changed].each do |file_change|
          update_file_data(file_change, commit, file_data)
        end
      end

      # Updates file data with information from a single file change
      def update_file_data(file_change, commit, file_data)
        filename = file_change[:filename]
        changes = file_change[:additions] + file_change[:deletions]
        author = commit[:author_name]

        file_data[filename][:commits] << build_commit_info(commit, changes)
        file_data[filename][:authors][author] += changes
        file_data[filename][:total_changes] += changes
      end

      # Builds commit information hash
      def build_commit_info(commit, changes)
        {
          author: commit[:author_name],
          date: commit[:date],
          changes: changes,
          hash: commit[:hash],
        }
      end
    end
  end
end
