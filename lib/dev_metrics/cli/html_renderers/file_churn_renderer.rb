# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for File Churn metric showing file statistics
      class FileChurnRenderer < Base
        def render_content
          case @value
          when Hash
            render_file_churn_stats_table
          else
            render_simple_data
          end
        end

        private

        def render_file_churn_stats_table
          headers = %w[Filename Total\ Churn Additions Deletions Net\ Changes Commits Authors\ Count Avg\ Churn/Commit Churn\ Ratio]
          data_table(headers) do
            @value.map do |filename, stats|
              if stats.is_a?(Hash)
                render_file_stats_columns(filename, stats)
              else
                # Fallback for unexpected data format
                table_row([filename, safe_value_format(stats)])
              end
            end.join
          end
        end

        def render_file_stats_columns(filename, stats)
          safe_filename = safe_string(filename)
          cells = [
            safe_filename,
            format_number(stats[:total_churn]),
            format_number(stats[:additions]),
            format_number(stats[:deletions]),
            format_number(stats[:net_changes]),
            format_number(stats[:commits]),
            format_number(stats[:authors_count]),
            format_float(stats[:avg_churn_per_commit]),
            "#{format_float(stats[:churn_ratio])}%",
          ]
          table_row(cells)
        end

        def format_number(value)
          return '' if value.nil?

          "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
        end

        def format_float(value)
          return '' if value.nil?

          "<span class=\"percentage\">#{format('%.2f', value)}</span>"
        end

        def number_with_delimiter(num)
          num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
        end

        def safe_value_format(value)
          case value
          when Numeric
            value.is_a?(Float) ? format('%.2f', value) : value.to_s
          when Hash
            "#{value.keys.length} items"
          when Array
            "#{value.length} items"
          else
            value.to_s
          end
        end

        def render_simple_data
          metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
        end

        def safe_string(value)
          str = value.to_s
          return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

          str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
          value.to_s.force_encoding('UTF-8').scrub('?')
        end
      end
    end
  end
end
