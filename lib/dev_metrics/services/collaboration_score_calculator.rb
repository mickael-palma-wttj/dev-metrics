# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating collaboration scores based on author distribution
    class CollaborationScoreCalculator
      def initialize
        @thresholds = ValueObjects::AuthorsPerFileThresholds
        @weights = @thresholds::COLLABORATION_WEIGHTS
      end

      def calculate_score(file_analysis_result)
        return 0 if file_analysis_result.empty?

        file_counts = categorize_files(file_analysis_result)
        raw_score = calculate_weighted_score(file_counts)

        normalize_score(raw_score)
      end

      private

      attr_reader :thresholds, :weights

      def categorize_files(result)
        {
          total_files: result.size,
          single_owner: count_single_owner_files(result),
          shared: count_shared_files(result),
          collaborative: count_collaborative_files(result),
        }
      end

      def count_single_owner_files(result)
        result.count { |_, stats| stats[:author_count] == 1 }
      end

      def count_shared_files(result)
        result.count { |_, stats| stats[:author_count] > 1 && stats[:author_count] <= 3 }
      end

      def count_collaborative_files(result)
        result.count { |_, stats| stats[:author_count] > 3 }
      end

      def calculate_weighted_score(file_counts)
        total_score = calculate_total_weighted_points(file_counts)
        total_score.to_f / file_counts[:total_files]
      end

      def calculate_total_weighted_points(file_counts)
        single_penalty = file_counts[:single_owner] * weights[:single_owner_penalty]
        shared_points = file_counts[:shared] * weights[:shared_points]
        collaborative_points = file_counts[:collaborative] * weights[:collaborative_points]

        single_penalty + shared_points + collaborative_points
      end

      def normalize_score(raw_score)
        raw_score.clamp(0, weights[:max_score]).round(1)
      end
    end
  end
end
