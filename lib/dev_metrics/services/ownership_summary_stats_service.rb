# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating ownership summary statistics
    # Handles metadata calculation and aggregation
    class OwnershipSummaryStatsService
      # Calculates summary statistics from ownership stats
      # @param ownership_stats [Hash] hash of filename to FileOwnershipStats
      # @return [Hash] summary metrics for metadata
      def calculate_summary_stats(ownership_stats)
        return default_summary_stats if ownership_stats.empty?

        concentrations = extract_concentrations(ownership_stats)

        {
          total_files_analyzed: ownership_stats.size,
          avg_ownership_concentration: calculate_average_concentration(concentrations),
          highly_concentrated_files: count_files_by_concentration(ownership_stats, :high_concentration?),
          moderately_concentrated_files: count_files_by_concentration(ownership_stats, :moderate_concentration?),
          distributed_ownership_files: count_files_by_concentration(ownership_stats, :distributed_ownership?),
          single_owner_files: count_files_by_method(ownership_stats, :single_owner?),
        }
      end

      private

      # Extracts concentration values from ownership stats
      def extract_concentrations(ownership_stats)
        ownership_stats.values.map(&:ownership_concentration)
      end

      # Calculates average concentration
      def calculate_average_concentration(concentrations)
        return 0.0 if concentrations.empty?

        concentrations.sum.to_f / concentrations.size
      end

      # Counts files matching a specific concentration method
      def count_files_by_concentration(ownership_stats, method)
        ownership_stats.count { |_, stats| stats.send(method) }
      end

      # Counts files matching a specific method
      def count_files_by_method(ownership_stats, method)
        ownership_stats.count { |_, stats| stats.send(method) }
      end

      # Default summary stats for empty data
      def default_summary_stats
        {
          total_files_analyzed: 0,
          avg_ownership_concentration: 0.0,
          highly_concentrated_files: 0,
          moderately_concentrated_files: 0,
          distributed_ownership_files: 0,
          single_owner_files: 0,
        }
      end
    end
  end
end
