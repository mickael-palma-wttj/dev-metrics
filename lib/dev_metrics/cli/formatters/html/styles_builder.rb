# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Builder for CSS styles with extracted style definitions
        class StylesBuilder
          STYLES = {
            base: 'body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; margin: 40px; color: #333; line-height: 1.6; }',
            heading: 'h1 { color: #1a1a1a; border-bottom: 3px solid #0066cc; padding-bottom: 15px; font-size: 28px; }',
            subheading: 'h2 { color: #404040; margin-top: 30px; font-size: 22px; border-bottom: 1px solid #ddd; padding-bottom: 10px; }',
            section_heading: 'h5 { color: #555; margin-top: 20px; margin-bottom: 12px; font-size: 16px; font-weight: 600; }',
            metric: '.metric { margin: 20px 0; padding: 15px; background: #f9f9f9; border: 1px solid #e0e0e0; border-radius: 8px; }',
            metric_header: '.metric-header { background: #f0f0f0; padding: 12px; border-bottom: 2px solid #ddd; border-radius: 6px 6px 0 0; }',
            metric_name: '.metric-name { font-size: 18px; font-weight: 700; color: #0066cc; }',
            metric_body: '.metric-body { padding: 15px; background: white; border-radius: 0 0 6px 6px; }',
            success: '.success { color: #4CAF50; font-weight: 600; }',
            error: '.error { color: #f44336; font-weight: 600; }',
            metadata: '.metadata { background: #e3f2fd; padding: 15px; margin-bottom: 20px; border-left: 4px solid #0066cc; border-radius: 4px; }',

            # Table styles
            metric_summary_table: '.metric-summary-table { width: 100%; border-collapse: collapse; margin: 10px 0; font-size: 14px; }',
            metric_summary_table_td: '.metric-summary-table td { padding: 10px; border-bottom: 1px solid #e0e0e0; }',
            metric_summary_table_odd: '.metric-summary-table tr:nth-child(odd) { background: #f9f9f9; }',
            metric_summary_table_even: '.metric-summary-table tr:nth-child(even) { background: white; }',
            metric_summary_table_hover: '.metric-summary-table tr:hover { background: #f0f5ff; }',
            metric_summary_table_first: '.metric-summary-table td:first-child { font-weight: 600; color: #555; width: 30%; }',

            data_table_container: '.data-table-container { margin: 15px 0; overflow-x: auto; border-radius: 4px; }',
            data_table: '.data-table { width: 100%; border-collapse: collapse; font-size: 13px; }',
            data_table_head: '.data-table thead { background: #f5f5f5; }',
            data_table_th: '.data-table th { padding: 12px; text-align: left; font-weight: 600; color: #333; border-bottom: 2px solid #ddd; cursor: pointer; user-select: none; }',
            data_table_th_hover: '.data-table th:hover { background: #efefef; }',
            data_table_td: '.data-table td { padding: 10px; border-bottom: 1px solid #f0f0f0; }',
            data_table_odd: '.data-table tbody tr:nth-child(odd) { background: white; }',
            data_table_even: '.data-table tbody tr:nth-child(even) { background: #f9f9f9; }',
            data_table_hover: '.data-table tbody tr:hover { background: #f0f5ff; }',
            data_table_sortable: '.data-table.sortable th { position: relative; }',
            data_table_sortable_icon: '.data-table.sortable th::after { content: " ⇅"; color: #999; font-size: 11px; }',

            # Value formatting
            count: '.count { background: #e8f4f8; color: #0066cc; padding: 2px 6px; border-radius: 3px; font-weight: 600; }',
            percentage: '.percentage { background: #fff3e0; color: #f57c00; padding: 2px 6px; border-radius: 3px; font-weight: 600; }',
            risk_low: '.risk-low { background: #e8f5e9; color: #2e7d32; padding: 2px 6px; border-radius: 3px; font-weight: 600; }',
            risk_medium: '.risk-medium { background: #fff3e0; color: #e65100; padding: 2px 6px; border-radius: 3px; font-weight: 600; }',
            risk_high: '.risk-high { background: #ffebee; color: #c62828; padding: 2px 6px; border-radius: 3px; font-weight: 600; }',

            # Toggle sections
            toggle_section: '.toggle-section { margin: 15px 0; border: 1px solid #ddd; border-radius: 4px; }',
            toggle_header: '.toggle-header { padding: 12px; background: #f9f9f9; cursor: pointer; display: flex; justify-content: space-between; align-items: center; user-select: none; }',
            toggle_header_hover: '.toggle-header:hover { background: #f0f0f0; }',
            toggle_left: '.toggle-left { display: flex; align-items: center; gap: 8px; flex-grow: 1; }',
            toggle_right: '.toggle-right { display: flex; align-items: center; }',
            section_icon: '.section-icon { font-size: 16px; }',
            section_title: '.section-title { font-weight: 600; color: #333; }',
            toggle_icon: '.toggle-icon { transition: transform 0.2s ease; color: #666; }',
            toggle_content: '.toggle-content { max-height: 0; overflow: hidden; transition: max-height 0.3s ease; }',
            toggle_content_expanded: '.toggle-content.expanded { max-height: 5000px; }',
            toggle_content_inner: '.toggle-content-inner { padding: 15px; }',
            toggle_section_expanded: '.toggle-section.expanded .toggle-icon { transform: rotate(90deg); }',

            # Heatmap styles
            commit_heatmap: '.commit-heatmap { margin: 15px 0; }',
            heatmap_legend: '.heatmap-legend { display: flex; align-items: center; gap: 15px; margin-bottom: 15px; padding: 10px; background: #f9f9f9; border-radius: 4px; }',
            legend_label: '.legend-label { font-weight: 600; color: #555; }',
            legend_scale: '.legend-scale { display: flex; gap: 10px; }',
            legend_item: '.legend-item { display: flex; align-items: center; gap: 5px; font-size: 12px; }',
            legend_box: '.legend-box { width: 20px; height: 20px; border: 1px solid #999; border-radius: 3px; }',
            legend_none: '.legend-none { background: #f5f5f5; }',
            legend_low: '.legend-low { background: #c8e6c9; }',
            legend_medium: '.legend-medium { background: #81c784; }',
            legend_high: '.legend-high { background: #2e7d32; }',

            heatmap_grid: '.heatmap-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(50px, 1fr)); gap: 5px; margin-bottom: 15px; }',
            heatmap_cell: '.heatmap-cell { padding: 8px; text-align: center; border: 1px solid #ddd; border-radius: 3px; cursor: pointer; transition: transform 0.2s ease; }',
            heatmap_cell_hover: '.heatmap-cell:hover { transform: scale(1.05); }',
            cell_hour: '.cell-hour { font-size: 11px; font-weight: 600; }',
            cell_count: '.cell-count { font-size: 13px; color: #333; }',

            intensity_none: '.intensity-none { background: #f5f5f5; color: #999; }',
            intensity_low: '.intensity-low { background: #c8e6c9; color: #1b5e20; }',
            intensity_medium: '.intensity-medium { background: #81c784; color: #1b5e20; }',
            intensity_high: '.intensity-high { background: #2e7d32; color: white; }',

            heatmap_summary: '.heatmap-summary { display: flex; gap: 20px; padding: 10px; background: #f9f9f9; border-radius: 4px; }',
            summary_stat: '.summary-stat { display: flex; gap: 8px; }',
            stat_label: '.stat-label { font-weight: 600; color: #555; }',
            stat_value: '.stat-value { color: #0066cc; font-weight: 600; }',

            # Nested data
            nested_data: '.nested-data { background: #f9f9f9; padding: 15px; border-radius: 4px; margin-bottom: 15px; }',

            # Tooltips
            tooltip: '.tooltip { position: relative; display: inline-block; cursor: help; border-bottom: 1px dotted #0066cc; }',
            tooltip_text: '.tooltip .tooltip-text { visibility: hidden; background-color: #333; color: #fff; text-align: center; border-radius: 6px; padding: 10px 12px; position: absolute; z-index: 1000; bottom: 125%; left: 50%; margin-left: -75px; opacity: 0; transition: opacity 0.3s; width: 150px; font-size: 12px; font-weight: normal; box-shadow: 0 2px 8px rgba(0,0,0,0.2); line-height: 1.4; }',
            tooltip_arrow: '.tooltip .tooltip-text::after { content: ""; position: absolute; top: 100%; left: 50%; margin-left: -5px; border-width: 5px; border-style: solid; border-color: #333 transparent transparent transparent; }',
            tooltip_show: '.tooltip:hover .tooltip-text { visibility: visible; opacity: 1; }',
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
