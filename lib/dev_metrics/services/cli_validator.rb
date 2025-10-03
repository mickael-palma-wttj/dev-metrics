# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object responsible for validating CLI options and commands
    class CliValidator
      COMMANDS = %w[analyze scan report config help].freeze
      VALID_FORMATS = %w[text json csv html markdown].freeze

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def validate!
        validate_command!
        validate_path!
        validate_format!
      end

      def validate_command!
        command = options[:command]
        return if command.nil? || COMMANDS.include?(command)

        puts "Unknown command: #{command}"
        exit 1
      end

      def validate_path!
        path = options[:path]
        return if File.exist?(path)

        puts "Error: Path does not exist: #{path}"
        exit 1
      end

      def validate_format!
        format = options[:format]
        return if VALID_FORMATS.include?(format)

        puts "Error: Invalid format '#{format}'. Valid formats: #{VALID_FORMATS.join(', ')}"
        exit 1
      end
    end
  end
end
