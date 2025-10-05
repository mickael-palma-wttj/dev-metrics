# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies files with high churn (frequent changes)
        # Orchestrates churn analysis using injected service dependencies
        class FileChurn < BaseMetric
          def initialize(repository, time_period = nil, options = {}, analysis_service: nil)
            super(repository, time_period, options)
            @analysis_service = analysis_service || Services::ChurnAnalysisService.new
          end

          def metric_name
            'file_churn'
          end

          def description
            'Files with highest churn (total lines added + deleted)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            analysis_result = @analysis_service.analyze_churn(commits_data)
            convert_to_hash_format(analysis_result)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            summary_stats = @analysis_service.calculate_summary_stats(commits_data)
            super.merge(summary_stats)
          end

          private

          attr_reader :analysis_service

          # Converts FileChurnStats objects to hash format for backward compatibility
          def convert_to_hash_format(analysis_result)
            analysis_result.transform_values(&:to_h)
          end
        end
      end
    end
  end
end
