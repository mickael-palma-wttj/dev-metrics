# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Strategy for basic report formatting
        class BasicReportStrategy < BaseReportBuilder
          def initialize(results, metadata)
            super()
            @results = results
            @metadata = metadata
          end

          private

          attr_reader :results, :metadata

          def build_header
            [
              'Developer Metrics Report',
              create_separator,
              '',
            ]
          end

          def build_content(_data)
            output = []
            output.concat(MetadataBuilder.build(metadata))
            output.concat(ResultsBuilder.build_basic(results))
            output
          end
        end
      end
    end
  end
end
