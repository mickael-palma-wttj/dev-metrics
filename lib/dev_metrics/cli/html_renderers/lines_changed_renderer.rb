# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Lines Changed metric showing author change statistics
      class LinesChangedRenderer < Base
        def render_content
          case @value
          when Hash
            render_author_change_stats_table
          else
            render_simple_data
          end
        end

        private

        def render_author_change_stats_table
          headers = ['Author', 'Additions', 'Deletions', 'Net Changes', 'Total Changes', 'Commits',
                     'Avg Changes/Commit', 'Churn Ratio',]
          data_table(headers) do
            @value.map do |author_name, stats|
              if stats.is_a?(Hash)
                render_author_stats_columns(author_name, stats)
              else
                # Fallback for unexpected data format
                table_row([author_name, safe_value_format(stats)])
              end
            end.join
          end
        end

        def render_author_stats_columns(author_name, stats)
          safe_author_name = safe_string(author_name)
          cells = [
            safe_author_name,
            format_number(stats[:additions]),
            format_number(stats[:deletions]),
            format_number(stats[:net_changes]),
            format_number(stats[:total_changes]),
            format_number(stats[:commits]),
            format_float(stats[:avg_changes_per_commit]),
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
