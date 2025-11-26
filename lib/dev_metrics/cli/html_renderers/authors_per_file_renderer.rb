# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Authors Per File metric showing file ownership distribution
      class AuthorsPerFileRenderer < Base
        def render_content
          case @value
          when Hash
            render_authors_per_file_stats_table
          else
            render_simple_data
          end
        end

        private

        def render_authors_per_file_stats_table
          headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
          data_table(headers) do
            @value.map do |filename, stats|
              if stats.is_a?(Hash)
                render_file_author_stats_columns(filename, stats)
              else
                # Fallback for unexpected data format
                table_row([filename, safe_value_format(stats)])
              end
            end.join
          end
        end

        def render_file_author_stats_columns(filename, stats)
          safe_filename = safe_string(filename)
          authors = stats[:authors].is_a?(Array) ? stats[:authors].join(', ') : stats[:authors].to_s
          safe_authors = safe_string(authors)
          bus_factor = stats[:bus_factor_risk].to_s
          ownership = stats[:ownership_type].to_s

          cells = [
            safe_filename,
            format_number(stats[:author_count]),
            safe_authors,
            bus_factor,
            ownership,
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
