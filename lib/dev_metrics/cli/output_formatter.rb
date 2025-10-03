require 'json'

module DevMetrics
  module CLI
    # Handles formatting and output of metric results using Strategy pattern
    class OutputFormatter
      FORMATTERS = {
        'text' => Formatters::TextFormatter,
        'json' => Formatters::JsonFormatter,
        'csv' => Formatters::CsvFormatter,
        'html' => Formatters::HtmlFormatter,
        'markdown' => Formatters::MarkdownFormatter
      }.freeze

      attr_reader :format, :output_file, :template_renderer

      def initialize(format = 'text', output_file = nil)
        @format = format.to_s.downcase
        @output_file = output_file
        @template_renderer = Utils::TemplateRenderer.new

        validate_format
      end

      def format_results(results, metadata = {})
        formatter.format_results(results, metadata)
      end

      def format_analysis_results(results, summary = {})
        formatter.format_analysis_results(results, summary)
      end

      def output(content)
        if output_file
          File.write(output_file, content)
          puts "Results written to: #{output_file}"
        else
          puts content
        end
      end

      private

      def formatter
        @formatter ||= create_formatter
      end

      def create_formatter
        formatter_class = FORMATTERS[format]
        raise ArgumentError, "Unsupported format: #{format}" unless formatter_class

        formatter_class.new(template_renderer)
      end

      def validate_format
        return if FORMATTERS.key?(format)

        raise ArgumentError, "Invalid format '#{format}'. Valid formats: #{FORMATTERS.keys.join(', ')}"
      end
    end
  end
end
