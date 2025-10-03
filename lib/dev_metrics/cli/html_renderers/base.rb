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

        def section(title)
          "<h5>#{title}</h5>#{yield}"
        end

        def metric_details
          "<div class=\"metric-details\">#{yield}</div>"
        end

        def metric_detail(label, value, css_class = nil)
          span_class = css_class ? " class=\"#{css_class}\"" : ''
          "<div class=\"metric-detail\"><strong>#{label}:</strong> <span#{span_class}>#{value}</span></div>"
        end

        def data_table(headers, &block)
          header_row = headers.map { |h| "<th>#{h}</th>" }.join
          "<table class=\"data-table\"><tr>#{header_row}</tr>#{yield}</table>"
        end

        def table_row(cells)
          cell_content = cells.map { |cell| "<td>#{cell}</td>" }.join
          "<tr>#{cell_content}</tr>"
        end
      end
    end
  end
end
