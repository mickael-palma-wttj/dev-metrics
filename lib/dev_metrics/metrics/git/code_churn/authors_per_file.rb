# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Analyzes how many authors have touched each file
        class AuthorsPerFile < BaseMetric
          def initialize(repository, time_period = nil, options = {}, analysis_service: nil)
            super(repository, time_period, options)
            @analysis_service = analysis_service || Services::AuthorAnalysisService.new
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
            @analysis_service.analyze_file_authors(commits_data)
          end

          def build_metadata(commits_data)
            base_metadata = super
            return base_metadata if commits_data.empty?

            result = compute_metadata_from_result(commits_data)
            base_metadata.merge(result)
          end

          def compute_metadata_from_result(commits_data)
            result = compute_metric(commits_data)
            calculate_metadata_from_result(result)
          end

          private

          attr_reader :analysis_service

          def calculate_metadata_from_result(result)
            return default_metadata if result.empty?

            base_metadata = {}
            risk_analysis = analyze_risk_distribution(result)
            author_stats = calculate_author_statistics(result)
            collaboration_score = calculate_collaboration_score(result)

            merge_metadata(base_metadata, risk_analysis, author_stats, collaboration_score)
          end

          def analyze_risk_distribution(result)
            bus_factor_counts = count_bus_factor_risks(result)
            total_files = result.size

            {
              high_risk_files: bus_factor_counts['high'] || 0,
              medium_risk_files: bus_factor_counts['medium'] || 0,
              low_risk_files: bus_factor_counts['low'] || 0,
              total_files: total_files,
            }
          end

          def count_bus_factor_risks(result)
            result.values.group_by { |stats| stats[:bus_factor_risk] }
              .transform_values(&:count)
          end

          def calculate_author_statistics(result)
            return default_author_stats if result.empty?

            author_counts = result.values.map { |stats| stats[:author_count] }

            {
              avg_authors_per_file: (author_counts.sum.to_f / author_counts.size).round(2),
              max_authors_per_file: author_counts.max,
              min_authors_per_file: author_counts.min,
              files_with_single_author: author_counts.count(1),
            }
          end

          def calculate_collaboration_score(result)
            return 0.0 if result.empty?

            total_author_interactions = result.values.sum { |stats| stats[:author_count] }
            total_files = result.size

            (total_author_interactions.to_f / total_files * 10).round(2)
          end

          def default_metadata
            {
              high_risk_files: 0,
              medium_risk_files: 0,
              low_risk_files: 0,
              total_files: 0,
            }.merge(default_author_stats).merge(collaboration_score: 0.0)
          end

          def default_author_stats
            {
              avg_authors_per_file: 0.0,
              max_authors_per_file: 0,
              min_authors_per_file: 0,
              files_with_single_author: 0,
            }
          end

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
