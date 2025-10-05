# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Value object to encapsulate report data and reduce parameter passing
        class ReportData
          attr_reader :results, :metadata, :summary

          def initialize(results:, metadata: {}, summary: {})
            @results = results
            @metadata = metadata
            @summary = summary
          end

          def basic_report?
            !analysis_report?
          end

          def analysis_report?
            !summary.empty?
          end

          def processed_summary
            return {} unless analysis_report?

            DevMetrics::Services::ContributorFilterProcessor.process(summary)
          end

          def repository_info
            summary[:repository_info] || {}
          end

          def contributor_filter_display
            summary[:contributor_filter_display]
          end

          def total_metrics
            summary[:total_metrics] || 0
          end

          def execution_time
            summary[:execution_time]
          end

          def data_coverage
            summary[:data_coverage] || 0
          end

          def repository
            metadata[:repository]
          end

          def time_period
            metadata[:time_period]
          end

          def generated_at
            metadata[:generated_at]
          end
        end
      end
    end
  end
end
