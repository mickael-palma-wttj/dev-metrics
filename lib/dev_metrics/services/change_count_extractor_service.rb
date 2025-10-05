# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for extracting change counts from commit data
    # Handles file pair counting and individual file change tracking
    class ChangeCountExtractorService
      # Extracts co-change and file change counts from commit data
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Array] co-change counts and file commit counts
      def extract_change_counts(commits_data)
        co_change_counts = Hash.new(0)
        file_commit_counts = Hash.new(0)

        commits_data.each do |commit|
          files = extract_and_sort_filenames(commit)
          count_individual_changes(files, file_commit_counts)
          count_pair_changes(files, co_change_counts)
        end

        [co_change_counts, file_commit_counts]
      end

      private

      # Extracts and sorts filenames from commit data
      def extract_and_sort_filenames(commit)
        commit[:files_changed].map { |f| f[:filename] }.sort
      end

      # Counts individual file changes
      def count_individual_changes(files, file_commit_counts)
        files.each { |file| file_commit_counts[file] += 1 }
      end

      # Counts file pair co-changes
      def count_pair_changes(files, co_change_counts)
        files.combination(2).each do |file1, file2|
          pair_key = create_pair_key(file1, file2)
          co_change_counts[pair_key] += 1
        end
      end

      # Creates a consistent pair key for file combinations
      def create_pair_key(file1, file2)
        [file1, file2].sort.join(' <-> ')
      end
    end
  end
end
