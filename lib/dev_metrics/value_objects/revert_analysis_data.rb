# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing revert analysis data
    class RevertAnalysisData
      attr_reader :revert_commits, :reverted_commits, :overall_stats, :author_stats

      def initialize(commits_data)
        @commits_data = commits_data
        calculate_revert_data
      end

      def revert_details
        @revert_details ||= pattern_analyzer.build_revert_details
      end

      def time_patterns
        @time_patterns ||= pattern_analyzer.analyze_time_patterns
      end

      def revert_frequency
        @revert_frequency ||= pattern_analyzer.calculate_revert_frequency
      end

      def high_risk_authors_count
        stats_calculator.count_high_risk_authors(author_stats)
      end

      def most_reverted_author
        stats_calculator.find_most_reverted_author(author_stats)
      end

      private

      attr_reader :commits_data

      def calculate_revert_data
        identifier = create_identifier
        @revert_commits = identifier.identify_revert_commits
        @reverted_commits = identifier.identify_reverted_commits(revert_commits)

        @overall_stats = stats_calculator.calculate_overall_stats
        @author_stats = stats_calculator.calculate_author_stats
      end

      def create_identifier
        Services::RevertCommitIdentifier.new(commits_data)
      end

      def stats_calculator
        @stats_calculator ||= Services::RevertStatisticsCalculator.new(
          commits_data,
          revert_commits,
          reverted_commits
        )
      end

      def pattern_analyzer
        @pattern_analyzer ||= Services::RevertPatternAnalyzer.new(
          revert_commits,
          reverted_commits
        )
      end
    end
  end
end
