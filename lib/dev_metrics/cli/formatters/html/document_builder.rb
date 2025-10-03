# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Builder for HTML document structure following Single Responsibility Principle
        class DocumentBuilder
          def self.build_document(body_content)
            new.build_document(body_content)
          end

          def build_document(body_content)
            html = build_document_start
            html.concat(body_content)
            html << '</body></html>'
            html.join("\n")
          end

          private

          def build_document_start
            [
              '<!DOCTYPE html>',
              '<html><head><title>Developer Metrics Report</title>',
              StylesBuilder.build_css,
              '</head><body>',
              '<h1>Developer Metrics Report</h1>',
            ]
          end
        end
      end
    end
  end
end
