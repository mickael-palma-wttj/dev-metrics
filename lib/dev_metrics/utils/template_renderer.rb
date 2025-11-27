# frozen_string_literal: true

require 'erb'

module DevMetrics
  module Utils
    # Handles ERB template rendering for output formatting
    class TemplateRenderer
      attr_reader :templates_dir

      def initialize(templates_dir = nil)
        @templates_dir = templates_dir || File.join(__dir__, '..', 'templates')
      end

      def render(template_name, binding_context)
        template_path = File.join(templates_dir, "#{template_name}.erb")

        raise ArgumentError, "Template not found: #{template_path}" unless File.exist?(template_path)

        template_content = File.read(template_path, encoding: 'UTF-8')
        erb = ERB.new(template_content, trim_mode: '-')
        result = erb.result(binding_context)

        # Ensure the result is UTF-8 encoded
        ensure_utf8_encoding(result)
      end

      def template_exists?(template_name)
        template_path = File.join(templates_dir, "#{template_name}.erb")
        File.exist?(template_path)
      end

      def available_templates
        Dir.glob(File.join(templates_dir, '*.erb')).map do |path|
          File.basename(path, '.erb')
        end
      end

      private

      def ensure_utf8_encoding(str)
        return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

        str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        str.force_encoding('UTF-8').scrub('?')
      end
    end
  end
end
