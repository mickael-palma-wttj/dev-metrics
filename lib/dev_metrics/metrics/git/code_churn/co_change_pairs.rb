# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies files that are frequently changed together
        # Orchestrates co-change analysis using injected service dependencies
        class CoChangePairs < BaseMetric
          def initialize(repository, options = {}, analysis_service: nil)
            super(repository, options)
            @analysis_service = analysis_service || Services::CoChangeAnalysisService.new
          end

          def metric_name
            'co_change_pairs'
          end

          def description
            'Files that are frequently modified together, indicating coupling'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            analysis_result = @analysis_service.analyze_co_changes(commits_data)
            convert_to_hash_format(analysis_result)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            analysis_result = @analysis_service.analyze_co_changes(commits_data)
            summary_stats = @analysis_service.calculate_summary_stats(analysis_result)
            hotspots = @analysis_service.identify_architectural_hotspots(analysis_result)

            super.merge(
              summary_stats.merge(architectural_hotspots: hotspots)
            )
          end

          private

          attr_reader :analysis_service

          # Converts FilePairStats objects to hash format for backward compatibility
          def convert_to_hash_format(analysis_result)
            analysis_result.transform_values(&:to_h)
          end
        end
      end
    end
  end
end
