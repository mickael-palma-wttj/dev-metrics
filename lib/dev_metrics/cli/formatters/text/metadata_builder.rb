# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Builder for metadata sections following Single Responsibility Principle
        class MetadataBuilder
          def self.build(metadata)
            new(metadata).build
          end

          def initialize(metadata)
            @metadata = metadata
          end

          def build
            output = []
            add_repository_info(output)
            add_time_period(output)
            add_generated_at(output)
            add_blank_line(output)
            output
          end

          private

          attr_reader :metadata

          def add_repository_info(output)
            return unless metadata[:repository]

            output << "Repository: #{metadata[:repository]}"
          end

          def add_time_period(output)
            return unless metadata[:time_period]

            output << "Time Period: #{metadata[:time_period]}"
          end

          def add_generated_at(output)
            return unless metadata[:generated_at]

            output << "Generated: #{metadata[:generated_at]}"
          end

          def add_blank_line(output)
            output << ''
          end
        end
      end
    end
  end
end
