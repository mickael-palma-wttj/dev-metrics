# frozen_string_literal: true

require 'fileutils'

module DevMetrics
  module Services
    # Service object responsible for writing output to files or console
    class OutputWriter
      attr_reader :output_path

      def initialize(output_path = nil)
        @output_path = output_path
      end

      def write(content)
        if output_path
          write_to_file(content)
        else
          write_to_console(content)
        end
      end

      private

      def write_to_file(content)
        ensure_directory_exists
        File.write(output_path, content)
        puts "Results written to: #{output_path}"
      end

      def write_to_console(content)
        puts content
      end

      def ensure_directory_exists
        output_dir = File.dirname(output_path)
        FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
      end
    end
  end
end
