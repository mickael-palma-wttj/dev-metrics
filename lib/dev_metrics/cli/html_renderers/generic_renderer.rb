# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      class GenericRenderer < Base
        protected

        def render_content
          case @value
          when Hash
            render_hash_data
          when Array
            render_array_data
          else
            render_simple_data
          end
        end

        private

        def render_hash_data
          # If we have many items, use a sortable data table
          if @value.size > 5
            render_hash_as_data_table
          else
            # For smaller datasets, use the simple metric details format
            metric_details do
              @value.map do |key, val|
                metric_detail(
                  Utils::StringUtils.humanize(key.to_s),
                  Utils::ValueFormatter.format_generic_value(val)
                )
              end.join
            end
          end
        end
        
        def render_hash_as_data_table
          data_table(['Metric', 'Value']) do
            @value.map do |key, val|
              table_row([
                Utils::StringUtils.humanize(key.to_s),
                Utils::ValueFormatter.format_generic_value(val)
              ])
            end.join
          end
        end

        def render_array_data
          metric_detail('Items', @value.length, 'count')
        end

        def render_simple_data
          metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
        end
      end
    end
  end
end
