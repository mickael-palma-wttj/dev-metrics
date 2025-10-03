# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing commit size analysis data
    class CommitSizeData
      attr_reader :commit_sizes, :thresholds, :categorized_commits

      def initialize(commits_data)
        @commits_data = commits_data
        calculate_size_data
      end

      def large_commits_count
        categorized_commits[:large].size
      end

      def huge_commits_count
        categorized_commits[:huge].size
      end

      def total_commits
        commits_data.size
      end

      def average_commit_size
        return 0 if commit_sizes.empty?

        (commit_sizes.sum.to_f / commit_sizes.size).round(1)
      end

      def largest_commits
        categorized_commits[:huge] + categorized_commits[:large]
      end

      private

      attr_reader :commits_data

      def calculate_size_data
        size_calculator = Services::CommitSizeCalculator.new(commits_data)
        @commit_sizes = size_calculator.calculate_sizes
        @thresholds = size_calculator.calculate_thresholds(commit_sizes)

        categorizer = Services::CommitCategorizer.new(commits_data, commit_sizes, thresholds)
        @categorized_commits = categorizer.categorize_by_size
      end
    end

    # Value object representing risk analysis results
    class RiskAnalysisData
      attr_reader :risk_patterns, :risk_score

      def initialize(commits_data, size_data)
        @commits_data = commits_data
        @size_data = size_data
        calculate_risk_data
      end

      def high_risk_commits
        risk_patterns[:risky_commits]
      end

      def common_risk_factors
        risk_patterns[:common_risk_factors]
      end

      def time_patterns
        risk_patterns[:time_patterns]
      end

      private

      attr_reader :commits_data, :size_data

      def calculate_risk_data
        risk_analyzer = create_risk_analyzer
        assign_risk_data(risk_analyzer)
      end

      def create_risk_analyzer
        Services::CommitRiskAnalyzer.new(
          commits_data,
          size_data.commit_sizes,
          size_data.thresholds
        )
      end

      def assign_risk_data(risk_analyzer)
        @risk_patterns = risk_analyzer.identify_patterns
        @risk_score = calculate_overall_risk_score(risk_analyzer)
      end

      def calculate_overall_risk_score(risk_analyzer)
        risk_analyzer.calculate_risk_score(
          size_data.large_commits_count,
          size_data.huge_commits_count,
          size_data.total_commits
        )
      end
    end
  end
end
