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
          metric_details do
            @value.map do |key, val|
              metric_detail(
                DevMetrics::Utils::StringUtils.humanize(key.to_s),
                ValueFormatter.format_generic_value(val)
              )
            end.join
          end
        end

        def render_array_data
          metric_detail('Items', @value.length, 'count')
        end

        def render_simple_data
          metric_detail('Value', ValueFormatter.format_generic_value(@value))
        end
      end
    end
  end
end
