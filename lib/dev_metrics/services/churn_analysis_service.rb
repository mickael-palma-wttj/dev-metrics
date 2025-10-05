# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing file churn patterns and generating summary statistics
    # Handles sorting, categorization, and metadata calculation
    class ChurnAnalysisService
      def initialize(file_stats_calculator: FileStatsCalculatorService.new)
        @file_stats_calculator = file_stats_calculator
        @thresholds = ValueObjects::FileChurnThresholds
      end

      # Analyzes commit data to produce sorted file churn statistics
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] sorted hash of filename to FileChurnStats objects
      def analyze_churn(commits_data)
        file_stats = @file_stats_calculator.calculate_file_stats(commits_data)
        sort_by_total_churn(file_stats)
      end

      # Calculates summary statistics for metadata
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] summary metrics for metadata
      def calculate_summary_stats(commits_data)
        return default_summary_stats if commits_data.empty?

        file_stats = analyze_churn(commits_data)
        basic_stats = calculate_basic_file_stats(commits_data)
        churn_categories = count_churn_categories(file_stats)

        basic_stats.merge(churn_categories).merge(
          hotspot_percentage: calculate_hotspot_percentage(file_stats, basic_stats[:total_files_changed])
        )
      end

      private

      attr_reader :file_stats_calculator, :thresholds

      # Sorts file statistics by total churn in descending order
      def sort_by_total_churn(file_stats)
        file_stats.sort_by { |_, stats| -stats.total_churn }.to_h
      end

      # Calculates basic file and change statistics
      def calculate_basic_file_stats(commits_data)
        all_files = extract_unique_filenames(commits_data)
        total_file_changes = count_total_file_changes(commits_data)

        {
          total_files_changed: all_files.size,
          total_file_changes: total_file_changes,
          avg_changes_per_file: calculate_avg_changes_per_file(total_file_changes, all_files.size),
        }
      end

      # Extracts unique filenames from commit data
      def extract_unique_filenames(commits_data)
        commits_data.flat_map { |c| c[:files_changed].map { |f| f[:filename] } }.uniq
      end

      # Counts total file changes across all commits
      def count_total_file_changes(commits_data)
        commits_data.sum { |c| c[:files_changed].size }
      end

      # Calculates average changes per file
      def calculate_avg_changes_per_file(total_changes, total_files)
        return 0 if total_files.zero?

        (total_changes.to_f / total_files).round(thresholds::CHURN_PRECISION)
      end

      # Counts files in each churn category
      def count_churn_categories(file_stats)
        {
          high_churn_files: count_files_by_category(file_stats, :high_churn?),
          medium_churn_files: count_files_by_category(file_stats, :medium_churn?),
          low_churn_files: count_files_by_category(file_stats, :low_churn?),
        }
      end

      # Counts files matching a specific churn category
      def count_files_by_category(file_stats, category_method)
        file_stats.count { |_, stats| stats.send(category_method) }
      end

      # Calculates hotspot percentage
      def calculate_hotspot_percentage(file_stats, total_files)
        return 0 if total_files.zero?

        high_churn_count = count_files_by_category(file_stats, :high_churn?)
        (high_churn_count.to_f / total_files * 100).round(thresholds::PERCENTAGE_PRECISION)
      end

      # Default summary stats for empty data
      def default_summary_stats
        {
          total_files_changed: 0,
          total_file_changes: 0,
          avg_changes_per_file: 0,
          high_churn_files: 0,
          medium_churn_files: 0,
          low_churn_files: 0,
          hotspot_percentage: 0,
        }
      end
    end
  end
end
