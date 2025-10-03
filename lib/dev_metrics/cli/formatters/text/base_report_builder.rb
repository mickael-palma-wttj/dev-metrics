# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Base class for text report builders following Template Method pattern
        class BaseReportBuilder
          def build(data)
            output = []
            output.concat(build_header)
            output.concat(build_content(data))
            output.join("\n")
          end

          private

          def build_header
            raise NotImplementedError, 'Subclasses must implement build_header'
          end

          def build_content(_data)
            raise NotImplementedError, 'Subclasses must implement build_content'
          end

          def create_separator(char = '=', length = 50)
            char * length
          end

          def add_blank_line(output)
            output << ''
          end
        end
      end
    end
  end
end
