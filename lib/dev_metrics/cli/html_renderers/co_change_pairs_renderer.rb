# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Co Change Pairs metric showing file coupling and co-change statistics
      class CoChangePairsRenderer < Base
        def render_content
          case @value
          when Hash
            render_co_change_pairs_table
          else
            render_simple_data
          end
        end

        private

        def render_co_change_pairs_table
          headers = ['File Pair', 'File 1 Changes', 'File 2 Changes', 'Co-changes', 'Coupling Strength', 'Coupling %',
                     'Category',]
          data_table(headers) do
            @value.map do |pair_key, stats|
              if stats.is_a?(Hash)
                render_co_change_pair_columns(pair_key, stats)
              else
                # Fallback for unexpected data format
                table_row([pair_key, safe_value_format(stats)])
              end
            end.join
          end
        end

        def render_co_change_pair_columns(pair_key, stats)
          pair_display = safe_string(pair_key)
          file1_changes = stats[:file1_total_changes].to_i
          file2_changes = stats[:file2_total_changes].to_i
          co_changes = stats[:co_changes].to_i
          coupling_strength = stats[:coupling_strength].to_f
          coupling_percentage = stats[:coupling_percentage].to_f
          coupling_category = stats[:coupling_category].to_s

          cells = [
            pair_display,
            format_number(file1_changes),
            format_number(file2_changes),
            format_number(co_changes),
            format('%.2f', coupling_strength),
            "#{format('%.1f', coupling_percentage)}%",
            coupling_category,
          ]
          table_row(cells)
        end

        def format_number(value)
          return '' if value.nil?

          "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
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
