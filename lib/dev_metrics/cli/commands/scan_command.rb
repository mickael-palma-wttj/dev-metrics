# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Legacy alias for analyze command - delegates to AnalyzeCommand
      class ScanCommand < BaseCommand
        def execute
          puts "⚠️  DEPRECATED: 'scan' command is deprecated. Use 'analyze --recursive' or 'analyze --interactive' instead."
          puts ''

          # Force recursive mode for scan command
          options[:recursive] = true unless options[:interactive]

          # Delegate to AnalyzeCommand
          AnalyzeCommand.new(options).execute
        end
      end
    end
  end
end
