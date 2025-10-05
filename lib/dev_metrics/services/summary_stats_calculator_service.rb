# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating summary statistics from analysis results
    # Provides aggregated metrics for metadata reporting
    class SummaryStatsCalculatorService
      def initialize
        @thresholds = ValueObjects::CoChangePairThresholds
      end

      # Calculates summary statistics from analysis results
      # @param analysis_result [Hash] results from analyze_co_changes
      # @return [Hash] summary metrics for metadata
      def calculate_summary_stats(analysis_result)
        return default_summary_stats if analysis_result.empty?

        coupling_strengths = extract_coupling_strengths(analysis_result)

        {
          total_file_pairs: analysis_result.size,
          avg_coupling_strength: calculate_average_coupling(coupling_strengths),
          max_coupling_strength: coupling_strengths.max || 0,
          high_coupling_pairs: count_high_coupling_pairs(analysis_result),
          medium_coupling_pairs: count_medium_coupling_pairs(analysis_result),
          low_coupling_pairs: count_low_coupling_pairs(analysis_result),
        }
      end

      private

      attr_reader :thresholds

      # Default summary stats for empty results
      def default_summary_stats
        {
          total_file_pairs: 0,
          avg_coupling_strength: 0,
          max_coupling_strength: 0,
          high_coupling_pairs: 0,
          medium_coupling_pairs: 0,
          low_coupling_pairs: 0,
        }
      end

      # Extracts coupling strengths from analysis results
      def extract_coupling_strengths(analysis_result)
        analysis_result.values.map(&:coupling_strength)
      end

      # Calculates average coupling strength
      def calculate_average_coupling(coupling_strengths)
        return 0 if coupling_strengths.empty?

        (coupling_strengths.sum.to_f / coupling_strengths.size).round(thresholds::COUPLING_PRECISION)
      end

      # Counts pairs with high coupling
      def count_high_coupling_pairs(analysis_result)
        analysis_result.count { |_, stats| stats.high_coupling? }
      end

      # Counts pairs with medium coupling
      def count_medium_coupling_pairs(analysis_result)
        analysis_result.count { |_, stats| stats.medium_coupling? }
      end

      # Counts pairs with low coupling
      def count_low_coupling_pairs(analysis_result)
        analysis_result.count { |_, stats| stats.low_coupling? }
      end
    end
  end
end
