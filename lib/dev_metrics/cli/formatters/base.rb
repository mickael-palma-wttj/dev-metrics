# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      class Base
        attr_reader :template_renderer

        def initialize(template_renderer)
          @template_renderer = template_renderer
        end

        def format_results(results, metadata)
          raise NotImplementedError, 'Subclasses must implement format_results'
        end

        def format_analysis_results(results, summary)
          raise NotImplementedError, 'Subclasses must implement format_analysis_results'
        end

        protected

        def render_template_or_fallback(template_name, data)
          if template_renderer.template_exists?(template_name)
            render_template(template_name, data)
          elsif block_given?
            yield
          end
        end

        def render_template(template_name, data)
          binding_context = create_template_binding(data)
          template_renderer.render(template_name, binding_context)
        end

        # Helper methods available in templates
        def format_execution_time(time_seconds)
          Utils::StringUtils.format_execution_time(time_seconds)
        end

        def humanize_string(str)
          Utils::StringUtils.humanize(str)
        end

        def titleize_string(str)
          Utils::StringUtils.titleize(str)
        end

        def truncate_text(text, length)
          Utils::StringUtils.truncate(text, length)
        end

        private

        def create_template_binding(data)
          template_binding = binding
          data.each { |key, value| template_binding.local_variable_set(key, value) }
          template_binding.local_variable_set(:string_utils, Utils::StringUtils)
          template_binding
        end
      end
    end
  end
end
