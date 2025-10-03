module DevMetrics
  module CLI
    module Services
      # Service for template rendering operations
      class TemplateRenderingService
        def initialize(template_renderer, formatter_instance)
          @template_renderer = template_renderer
          @formatter_instance = formatter_instance
        end

        def render_with_fallback(template_name, data)
          if @template_renderer.template_exists?(template_name)
            render_template(template_name, data)
          elsif block_given?
            yield
          end
        end

        def render_template(template_name, data)
          binding_context = create_binding_context(data)
          @template_renderer.render(template_name, binding_context)
        end

        private

        def create_binding_context(data)
          template_binding = @formatter_instance.send(:binding)
          data.each { |key, value| template_binding.local_variable_set(key, value) }
          template_binding.local_variable_set(:string_utils, StringUtils)
          template_binding
        end
      end
    end
  end
end
