# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for File Ownership metric showing ownership concentration and distribution
      class FileOwnershipRenderer < Base
        def render_content
          case @value
          when Hash
            render_file_ownership_stats_table
          else
            render_simple_data
          end
        end

        private

        def render_file_ownership_stats_table
          headers = ['Filename', 'Primary Owner', 'Owner %', 'Contributors', 'Concentration', 'Type']
          data_table(headers) do
            @value.map do |filename, stats|
              if stats.is_a?(Hash)
                render_file_ownership_columns(filename, stats)
              else
                # Fallback for unexpected data format
                table_row([filename, safe_value_format(stats)])
              end
            end.join
          end
        end

        def render_file_ownership_columns(filename, stats)
          safe_filename = safe_string(filename)
          primary_owner = safe_string(stats[:primary_owner].to_s)
          owner_percentage = stats[:primary_owner_percentage].to_f
          contributor_count = stats[:contributor_count].to_i
          concentration = stats[:ownership_concentration].to_f
          ownership_type = stats[:ownership_type].to_s

          cells = [
            safe_filename,
            primary_owner,
            "#{format_percentage_plain(owner_percentage)}%",
            format_number(contributor_count),
            "#{format_percentage_plain(concentration)}%",
            ownership_type,
          ]
          table_row(cells)
        end
      end
    end
  end
end
