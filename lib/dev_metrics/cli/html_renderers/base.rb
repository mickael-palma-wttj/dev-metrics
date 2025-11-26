# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Base class for HTML renderers with common HTML generation methods
      class Base
        def initialize(value)
          @value = value
        end

        def render
          return empty_data_div unless @value

          content_div { render_content }
        end

        protected

        def render_content
          raise NotImplementedError, 'Subclasses must implement render_content'
        end

        def empty_data_div
          '<div class="metric-detail">No data available</div>'
        end

        def content_div
          "<div class=\"nested-data\">#{yield}</div>"
        end

        def section(title, tooltip_text = nil)
          if tooltip_text
            "<h5>#{with_tooltip(title, tooltip_text)}</h5>#{yield}"
          else
            "<h5>#{title}</h5>#{yield}"
          end
        end

        def metric_details
          "<table class=\"metric-summary-table\">#{yield}</table>"
        end

        def metric_detail(label, value, css_class = nil)
          span_class = css_class ? " class=\"#{css_class}\"" : ''
          "<tr><td>#{label}</td><td><span#{span_class}>#{value}</span></td></tr>"
        end

        def data_table(headers, sortable: true)
          sortable_class = sortable ? ' sortable' : ''
          header_row = headers.map { |h| "<th>#{h}</th>" }.join
          <<~HTML
            <div class="data-table-container">
              <table class="data-table#{sortable_class}">
                <thead>
                  <tr>#{header_row}</tr>
                </thead>
                <tbody>
                  #{yield}
                </tbody>
              </table>
            </div>
          HTML
        end

        def table_row(cells)
          cell_content = cells.map { |cell| "<td>#{cell}</td>" }.join
          "<tr>#{cell_content}</tr>"
        end

        def with_tooltip(text, tooltip_text)
          escaped_tooltip = tooltip_text.gsub('"', '&quot;').gsub("'", '&#39;')
          "<span class=\"tooltip\">#{text}<span class=\"tooltip-text\">#{escaped_tooltip}</span></span>"
        end

        def safe_string(value)
          return '' if value.nil?

          value.to_s.gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
        end

        def format_number(value, decimals = 2)
          return '0' if value.nil?
          return value.to_s unless value.is_a?(Numeric)

          format("%.#{decimals}f", value)
        end
      end
    end
  end
end
