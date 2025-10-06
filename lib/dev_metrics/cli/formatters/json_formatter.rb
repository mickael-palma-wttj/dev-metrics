# frozen_string_literal: true

require 'json'

module DevMetrics
  module CLI
    module Formatters
      class JsonFormatter < Base
        def format_analysis_results(results, summary)
          data = {
            summary: summary,
            results: transform_analysis_results(results),
          }
          # Sanitize encoding before JSON generation to prevent UTF-8/BINARY warnings
          sanitized_data = sanitize_encoding(data)
          JSON.generate(sanitized_data, quirks_mode: false)
        end

        private

        def transform_analysis_results(results)
          results.transform_values do |data|
            {
              category: data[:metadata][:category],
              metric: data[:metric].to_h,
              execution_time: data[:metadata][:execution_time],
            }
          end
        end

        # Recursively ensures all strings in the data structure are UTF-8 encoded
        # This prevents JSON encoding warnings when git data contains binary strings
        def sanitize_encoding(obj)
          case obj
          when String
            # Force UTF-8 encoding, replacing invalid characters
            obj.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          when Hash
            obj.transform_keys { |k| sanitize_encoding(k) }
              .transform_values { |v| sanitize_encoding(v) }
          when Array
            obj.map { |item| sanitize_encoding(item) }
          else
            obj
          end
        end
      end
    end
  end
end
