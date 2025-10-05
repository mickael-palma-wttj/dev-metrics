# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating file statistics from commit data
    # Handles aggregation of additions, deletions, commits, and authors per file
    class FileStatsCalculatorService
      def initialize
        @thresholds = ValueObjects::FileChurnThresholds
      end

      # Processes commit data to calculate file statistics
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] hash of filename to FileChurnStats objects
      def calculate_file_stats(commits_data)
        return {} if commits_data.empty?

        raw_stats = aggregate_file_changes(commits_data)
        build_file_churn_stats(raw_stats)
      end

      private

      attr_reader :thresholds

      # Aggregates file changes from all commits
      def aggregate_file_changes(commits_data)
        file_stats = create_empty_stats_hash

        commits_data.each do |commit|
          process_commit_files(commit, file_stats)
        end

        file_stats
      end

      # Creates empty statistics hash with default values
      def create_empty_stats_hash
        Hash.new do |h, k|
          h[k] = { additions: 0, deletions: 0, commits: 0, authors: Set.new }
        end
      end

      # Processes all files in a single commit
      def process_commit_files(commit, file_stats)
        commit[:files_changed].each do |file_change|
          update_file_stats(file_change, commit[:author_name], file_stats)
        end
      end

      # Updates statistics for a single file
      def update_file_stats(file_change, author_name, file_stats)
        filename = file_change[:filename]
        stats = file_stats[filename]

        stats[:additions] += file_change[:additions]
        stats[:deletions] += file_change[:deletions]
        stats[:commits] += 1
        stats[:authors] << author_name
      end

      # Builds FileChurnStats objects from raw statistics
      def build_file_churn_stats(raw_stats)
        result = {}

        raw_stats.each do |filename, stats|
          result[filename] = create_file_churn_stats(filename, stats)
        end

        result
      end

      # Creates a FileChurnStats object for a single file
      def create_file_churn_stats(filename, stats)
        total_churn = stats[:additions] + stats[:deletions]
        attributes = build_churn_stats_attributes(filename, stats, total_churn)
        ValueObjects::FileChurnStats.new(attributes)
      end

      # Builds attributes hash for FileChurnStats object
      def build_churn_stats_attributes(filename, stats, total_churn)
        basic_attributes(filename, stats, total_churn).merge(
          calculated_attributes(stats, total_churn)
        )
      end

      # Basic file attributes
      def basic_attributes(filename, stats, total_churn)
        {
          filename: filename,
          total_churn: total_churn,
          additions: stats[:additions],
          deletions: stats[:deletions],
          net_changes: stats[:additions] - stats[:deletions],
          commits: stats[:commits],
        }
      end

      # Calculated file attributes
      def calculated_attributes(stats, total_churn)
        {
          authors_count: stats[:authors].size,
          authors: stats[:authors].to_a,
          avg_churn_per_commit: calculate_avg_churn_per_commit(total_churn, stats[:commits]),
          churn_ratio: calculate_churn_ratio(stats[:deletions], total_churn),
        }
      end

      # Calculates average churn per commit
      def calculate_avg_churn_per_commit(total_churn, commits)
        return 0 if commits.zero?

        (total_churn.to_f / commits).round(thresholds::CHURN_PRECISION)
      end

      # Calculates churn ratio (percentage of deletions)
      def calculate_churn_ratio(deletions, total_churn)
        return 0 if total_churn.zero?

        (deletions.to_f / total_churn * 100).round(thresholds::PERCENTAGE_PRECISION)
      end
    end
  end
end
