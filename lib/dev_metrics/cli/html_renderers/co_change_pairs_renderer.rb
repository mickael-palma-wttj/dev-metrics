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
          render_keyed_hash_table(headers, method(:render_co_change_pair_columns))
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
            format_float_plain(coupling_strength),
            "#{format_percentage_plain(coupling_percentage)}%",
            coupling_category,
          ]
          table_row(cells)
        end
      end
    end
  end
end
