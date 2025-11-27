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
          headers = ['Filename', 'Total Churn', 'Additions', 'Deletions', 'Net Changes', 'Commits', 'Authors Count',
                     'Avg Churn/Commit', 'Churn Ratio',]
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
            format_percentage(stats[:churn_ratio]),
          ]
          table_row(cells)
        end
      end
    end
  end
end
