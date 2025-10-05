# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating coupling strength and percentages
    # Uses Jaccard similarity coefficient for coupling strength calculation
    class CouplingCalculatorService
      def initialize
        @thresholds = ValueObjects::CoChangePairThresholds
      end

      # Calculates coupling strength using Jaccard similarity coefficient
      # @param co_changes [Integer] number of times files were changed together
      # @param file1_total [Integer] total changes for first file
      # @param file2_total [Integer] total changes for second file
      # @return [Float] coupling strength between 0.0 and 1.0
      def calculate_coupling_strength(co_changes, file1_total, file2_total)
        return 0.0 if file1_total.zero? || file2_total.zero?

        union = calculate_union(co_changes, file1_total, file2_total)
        return 0.0 if union.zero?

        (co_changes.to_f / union).round(@thresholds::COUPLING_PRECISION)
      end

      # Calculates coupling percentage based on the minimum file change count
      # @param co_changes [Integer] number of times files were changed together
      # @param file1_total [Integer] total changes for first file
      # @param file2_total [Integer] total changes for second file
      # @return [Float] coupling percentage
      def calculate_coupling_percentage(co_changes, file1_total, file2_total)
        min_changes = [file1_total, file2_total].min
        return 0.0 if min_changes.zero?

        (co_changes.to_f / min_changes * 100).round(@thresholds::PERCENTAGE_PRECISION)
      end

      # Creates a FilePairStats object with calculated coupling metrics
      # @param file1 [String] first file name
      # @param file2 [String] second file name
      # @param co_changes [Integer] number of co-changes
      # @param file1_total [Integer] total changes for first file
      # @param file2_total [Integer] total changes for second file
      # @return [ValueObjects::FilePairStats] complete file pair statistics
      def create_file_pair_stats(file1, file2, co_changes, file1_total, file2_total)
        metrics = calculate_coupling_metrics(co_changes, file1_total, file2_total)
        files_data = build_files_data(file1, file2, co_changes, file1_total, file2_total)
        build_file_pair_stats_object(files_data, metrics)
      end

      private

      attr_reader :thresholds

      # Calculates coupling metrics as a hash
      def calculate_coupling_metrics(co_changes, file1_total, file2_total)
        {
          strength: calculate_coupling_strength(co_changes, file1_total, file2_total),
          percentage: calculate_coupling_percentage(co_changes, file1_total, file2_total),
        }
      end

      # Builds FilePairStats object with calculated metrics
      def build_file_pair_stats_object(files_data, metrics)
        attributes = build_stats_attributes(files_data, metrics)
        ValueObjects::FilePairStats.new(attributes)
      end

      # Builds attributes hash for FilePairStats
      def build_stats_attributes(files_data, metrics)
        {
          file1: files_data[:file1],
          file2: files_data[:file2],
          co_changes: files_data[:co_changes],
          file1_total_changes: files_data[:file1_total],
          file2_total_changes: files_data[:file2_total],
          coupling_strength: metrics[:strength],
          coupling_percentage: metrics[:percentage],
          coupling_category: @thresholds.categorize_coupling(metrics[:strength]),
        }
      end

      # Builds files data hash
      def build_files_data(file1, file2, co_changes, file1_total, file2_total)
        {
          file1: file1,
          file2: file2,
          co_changes: co_changes,
          file1_total: file1_total,
          file2_total: file2_total,
        }
      end

      # Calculates the union for Jaccard similarity coefficient
      # @param co_changes [Integer] intersection of file changes
      # @param file1_total [Integer] total changes for first file
      # @param file2_total [Integer] total changes for second file
      # @return [Integer] union size for Jaccard calculation
      def calculate_union(co_changes, file1_total, file2_total)
        file1_total + file2_total - co_changes
      end
    end
  end
end
