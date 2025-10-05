# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating commit metadata (lines changed, files, etc.)
    # Follows Single Responsibility Principle - only handles metadata calculations
    class CommitMetadataCalculator
      def initialize(commits_data)
        @commits_data = commits_data
      end

      def calculate
        return build_empty_metadata if commits_data.empty?

        ValueObjects::CommitSizeMetadata.new(
          total_lines_changed: calculate_total_lines_changed,
          total_additions: calculate_total_additions,
          total_deletions: calculate_total_deletions,
          net_lines: calculate_net_lines,
          files_per_commit: calculate_files_per_commit
        )
      end

      private

      attr_reader :commits_data

      def calculate_total_lines_changed
        commits_data.sum { |commit| commit[:additions] + commit[:deletions] }
      end

      def calculate_total_additions
        commits_data.sum { |commit| commit[:additions] }
      end

      def calculate_total_deletions
        commits_data.sum { |commit| commit[:deletions] }
      end

      def calculate_net_lines
        calculate_total_additions - calculate_total_deletions
      end

      def calculate_files_per_commit
        total_files = commits_data.sum { |commit| commit[:files_changed].size }
        (total_files.to_f / commits_data.size).round(2)
      end

      def build_empty_metadata
        ValueObjects::CommitSizeMetadata.new(
          total_lines_changed: 0,
          total_additions: 0,
          total_deletions: 0,
          net_lines: 0,
          files_per_commit: 0.0
        )
      end
    end
  end
end
