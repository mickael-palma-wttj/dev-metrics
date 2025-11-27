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


      end
    end
  end
end
