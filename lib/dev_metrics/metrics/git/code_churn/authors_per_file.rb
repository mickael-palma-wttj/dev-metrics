# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Analyzes how many authors have touched each file
        class AuthorsPerFile < BaseMetric
          def initialize(repository, options = {})
            super
            @author_analyzer = Services::AuthorAnalysisService.new
            @risk_analyzer = Services::BusFactorRiskAnalyzer.new
            @score_calculator = Services::CollaborationScoreCalculator.new
          end

          def metric_name
            'authors_per_file'
          end

          def description
            'Number of distinct authors who have modified each file (bus factor analysis)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            author_analyzer.analyze_file_authors(commits_data)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)

            base_metadata = super
            risk_analysis = risk_analyzer.analyze_risk_distribution(result)
            author_stats = risk_analyzer.calculate_author_statistics(result)
            collaboration_score = score_calculator.calculate_score(result)

            merge_metadata(base_metadata, risk_analysis, author_stats, collaboration_score)
          end

          private

          attr_reader :author_analyzer, :risk_analyzer, :score_calculator

          def merge_metadata(base, risk_analysis, author_stats, collaboration_score)
            base.merge(risk_analysis)
              .merge(author_stats)
              .merge(collaboration_score: collaboration_score)
          end
        end
      end
    end
  end
end
