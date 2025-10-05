# frozen_string_literal: true

module DevMetrics
  module CLI
    # Factory for creating and executing CLI commands
    class CommandFactory
      COMMAND_MAPPING = {
        'analyze' => Commands::AnalyzeCommand,
        'scan' => Commands::ScanCommand,
        'config' => Commands::ConfigCommand,
        'help' => Commands::HelpCommand,
        nil => Commands::HelpCommand,
      }.freeze

      def self.create(command_name, options)
        command_class = COMMAND_MAPPING[command_name]

        if command_class
          command_class.new(options)
        else
          Commands::HelpCommand.new(options)
        end
      end
    end
  end
end
