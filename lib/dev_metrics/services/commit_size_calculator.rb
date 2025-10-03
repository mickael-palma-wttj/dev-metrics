# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating commit sizes and determining size thresholds
    class CommitSizeCalculator
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate_sizes
        return [] if commits_data.empty?

        commits_data.map { |commit| calculate_single_commit_size(commit) }
      end

      def calculate_thresholds(commit_sizes = nil)
        sizes = commit_sizes || calculate_sizes
        return default_thresholds if sizes.empty?

        sorted_sizes = sizes.sort
        statistical_thresholds(sorted_sizes)
      end

      private

      attr_reader :commits_data

      def calculate_single_commit_size(commit)
        line_changes = calculate_line_changes(commit)
        file_weight = calculate_file_weight(commit)

        line_changes + file_weight
      end

      def calculate_line_changes(commit)
        additions = commit[:additions] || 0
        deletions = commit[:deletions] || 0
        additions + deletions
      end

      def calculate_file_weight(commit)
        files_changed = commit[:files_changed]&.size || 0
        files_changed * 10 # Files changed have additional weight
      end

      def default_thresholds
        { small: 50, medium: 200, large: 500, huge: 1000 }
      end

      def statistical_thresholds(sorted_sizes)
        {
          small: calculate_percentile(sorted_sizes, 25),
          medium: calculate_percentile(sorted_sizes, 50),
          large: calculate_percentile(sorted_sizes, 75),
          huge: calculate_percentile(sorted_sizes, 90),
        }
      end

      def calculate_percentile(sorted_array, percentile)
        return 0 if sorted_array.empty?

        index = (percentile / 100.0 * (sorted_array.length - 1)).round
        sorted_array[index]
      end
    end
  end
end
