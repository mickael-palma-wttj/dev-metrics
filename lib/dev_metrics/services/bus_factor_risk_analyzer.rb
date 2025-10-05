# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing bus factor risk and file categorization
    class BusFactorRiskAnalyzer
      def initialize
        @thresholds = ValueObjects::AuthorsPerFileThresholds
      end

      def analyze_risk_distribution(file_analysis_result)
        return build_empty_analysis if file_analysis_result.empty?

        {
          total_files_analyzed: file_analysis_result.size,
          single_author_files: count_single_author_files(file_analysis_result),
          shared_files: count_shared_files(file_analysis_result),
          highly_shared_files: count_highly_shared_files(file_analysis_result),
          bus_factor_risk_percentage: calculate_risk_percentage(file_analysis_result),
        }
      end

      def calculate_author_statistics(file_analysis_result)
        return build_empty_statistics if file_analysis_result.empty?

        author_counts = extract_author_counts(file_analysis_result)

        {
          avg_authors_per_file: calculate_average(author_counts),
          max_authors_per_file: author_counts.max,
          min_authors_per_file: author_counts.min,
        }
      end

      private

      attr_reader :thresholds

      def build_empty_analysis
        {
          total_files_analyzed: 0,
          single_author_files: 0,
          shared_files: 0,
          highly_shared_files: 0,
          bus_factor_risk_percentage: 0,
        }
      end

      def build_empty_statistics
        {
          avg_authors_per_file: 0,
          max_authors_per_file: 0,
          min_authors_per_file: 0,
        }
      end

      def count_single_author_files(result)
        result.count { |_, stats| thresholds.single_author?(stats[:author_count]) }
      end

      def count_shared_files(result)
        result.count { |_, stats| thresholds.shared?(stats[:author_count]) }
      end

      def count_highly_shared_files(result)
        result.count { |_, stats| thresholds.highly_shared?(stats[:author_count]) }
      end

      def calculate_risk_percentage(result)
        total_files = result.size
        return 0 unless total_files.positive?

        single_author_files = count_single_author_files(result)
        (single_author_files.to_f / total_files * 100).round(1)
      end

      def extract_author_counts(result)
        result.values.map { |stats| stats[:author_count] }
      end

      def calculate_average(author_counts)
        return 0 if author_counts.empty?

        (author_counts.sum.to_f / author_counts.size).round(2)
      end
    end
  end
end
