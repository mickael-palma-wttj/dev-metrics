# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Command for analyzing a single repository
      class AnalyzeCommand < BaseCommand
        def execute
          display_analysis_info
          validate_repository

          results = perform_analysis
          output_results(results)

          puts "\n✅ Analysis complete! Analyzed #{results.size} metrics"
        end

        private

        def display_analysis_info
          puts "Analyzing repository at: #{options[:path]}"
          puts "Repository: #{repository.name}"
          puts "Time period: #{build_time_period}"
          puts "Metrics: #{options[:metrics]}"
          puts "Format: #{options[:format]}"
          puts ''
        end

        def validate_repository
          return if repository.git_repository?

          puts "Error: Not a Git repository: #{options[:path]}"
          exit 1
        end

        def perform_analysis
          categories = extract_git_categories
          analyzer.analyze(options[:metrics], categories)
        end

        def output_results(results)
          formatter = OutputFormatter.new(options[:format])
          output = formatter.format_analysis_results(results, analyzer.summary)

          Services::OutputWriter.new(options[:output]).write(output)
        end

        def repository
          @repository ||= Models::Repository.new(options[:path])
        end

        def analyzer
          @analyzer ||= Analyzers::GitAnalyzer.new(repository, options, build_time_period)
        end
      end
    end
  end
end
