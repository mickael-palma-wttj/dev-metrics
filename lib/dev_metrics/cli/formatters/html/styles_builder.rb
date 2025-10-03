# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Builder for CSS styles with extracted style definitions
        class StylesBuilder
          STYLES = {
            base: 'body { font-family: Arial, sans-serif; margin: 40px; }',
            heading: 'h1 { color: #333; border-bottom: 2px solid #ddd; }',
            subheading: 'h2 { color: #666; margin-top: 30px; }',
            metric: '.metric { margin: 10px 0; padding: 10px; background: #f5f5f5; }',
            success: '.success { border-left: 4px solid #4CAF50; }',
            error: '.error { border-left: 4px solid #f44336; }',
            metadata: '.metadata { background: #e3f2fd; padding: 15px; margin-bottom: 20px; }',
          }.freeze

          def self.build_css
            new.build_css
          end

          def build_css
            [
              '<style>',
              *STYLES.values,
              '</style>',
            ].join("\n")
          end
        end
      end
    end
  end
end
