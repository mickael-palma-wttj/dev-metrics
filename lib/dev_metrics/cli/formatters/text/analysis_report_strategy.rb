# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Strategy for analysis report formatting
        class AnalysisReportStrategy < BaseReportBuilder
          def initialize(results, summary)
            super()
            @results = results
            @summary = summary
          end

          private

          attr_reader :results, :summary

          def build_header
            [
              'Git Metrics Analysis Report',
              create_separator,
              '',
            ]
          end

          def build_content(_data)
            output = []
            output.concat(SummaryBuilder.build(summary))
            output.concat(ResultsBuilder.build_analysis(results))
            output
          end
        end
      end
    end
  end
end
