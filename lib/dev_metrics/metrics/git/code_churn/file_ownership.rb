# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies the primary owner (last significant contributor) of each file
        # Orchestrates ownership analysis using injected service dependencies
        class FileOwnership < BaseMetric
          def initialize(repository, time_period = nil, options = {}, analysis_service: nil)
            super(repository, time_period, options)
            @analysis_service = analysis_service || Services::OwnershipAnalysisService.new
          end

          def metric_name
            'file_ownership'
          end

          def description
            'Primary ownership and contribution distribution for each file'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            analysis_result = @analysis_service.analyze_ownership(commits_data)
            convert_to_hash_format(analysis_result)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            summary_stats = @analysis_service.calculate_summary_stats(commits_data)
            super.merge(summary_stats)
          end

          private

          attr_reader :analysis_service

          # Converts FileOwnershipStats objects to hash format for backward compatibility
          def convert_to_hash_format(analysis_result)
            analysis_result.transform_values(&:to_h)
          end
        end
      end
    end
  end
end
