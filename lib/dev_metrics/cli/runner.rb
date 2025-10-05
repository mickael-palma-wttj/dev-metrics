# frozen_string_literal: true

module DevMetrics
  module CLI
    # Main CLI runner that orchestrates option parsing, validation, and command execution
    class Runner
      attr_reader :args, :options

      def initialize(args)
        @args = args
        @options = parse_and_validate_options
      end

      def run
        command = create_command
        execute_command(command)
      end

      private

      def parse_and_validate_options
        parser = DevMetrics::Services::CliOptionParser.new(args)
        options = parser.parse

        DevMetrics::Services::CliValidator.new(options).validate!
        options
      end

      def create_command
        CommandFactory.create(options[:command], options)
      end

      def execute_command(command)
        command.execute
      rescue ArgumentError => e
        puts "Error: #{e.message}"
        exit 1
      rescue StandardError => e
        puts "Unexpected error: #{e.message}"
        puts 'Please check your repository and try again.'
        exit 1
      end
    end
  end
end
