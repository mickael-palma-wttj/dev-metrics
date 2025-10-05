# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Unified command for analyzing single or multiple repositories
      # Refactored to follow Sandi Metz rules and SOLID principles
      class AnalyzeCommand < BaseCommand
        def execute
          mode_detector = create_mode_detector

          if mode_detector.batch_mode?
            execute_batch_analysis(mode_detector)
          else
            execute_single_analysis
          end
        end

        private

        def create_mode_detector
          DevMetrics::ValueObjects::AnalysisModeDetector.new(options[:path], options)
        end

        def execute_batch_analysis(mode_detector)
          scanner = create_scanner
          repositories = find_and_validate_repositories(scanner)

          selected_repos = select_repositories(scanner, repositories, mode_detector)
          run_batch_analysis(selected_repos)
        end

        def execute_single_analysis
          single_analyzer = create_single_analyzer
          single_analyzer.execute
        end

        def create_scanner
          DevMetrics::Services::RepositoryScannerService.new(options[:path], options)
        end

        def find_and_validate_repositories(scanner)
          puts "Scanning for repositories in: #{options[:path]}"
          repositories = scanner.find_repositories
          scanner.validate_repositories(repositories)
        end

        def select_repositories(scanner, repositories, mode_detector)
          if mode_detector.interactive_batch_mode?
            select_interactively(scanner, repositories)
          else
            select_all_repositories(repositories)
          end
        end

        def select_interactively(scanner, repositories)
          selected = scanner.interactive_select(repositories)
          display_selected_repositories(selected)
          selected
        end

        def select_all_repositories(repositories)
          display_found_repositories(repositories)
          repositories
        end

        def display_selected_repositories(repositories)
          puts "\nSelected repositories:"
          repositories.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
          puts "\nRunning analysis on #{repositories.size} selected repositories..."
        end

        def display_found_repositories(repositories)
          puts "Found #{repositories.length} repositories:"
          repositories.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
          puts "\nRunning analysis on all #{repositories.size} repositories..."
        end

        def run_batch_analysis(repositories)
          return unless repositories.any?

          batch_analyzer = create_batch_analyzer
          results = batch_analyzer.analyze_repositories(repositories)

          report_generator = create_report_generator
          report_generator.generate_batch_report(results)
        end

        def create_batch_analyzer
          DevMetrics::Services::BatchAnalysisService.new(options)
        end

        def create_report_generator
          DevMetrics::Services::ReportGeneratorService.new(options)
        end

        def create_single_analyzer
          SingleRepositoryAnalyzer.new(options, repository, analyzer)
        end

        def repository
          @repository ||= Models::Repository.new(options[:path])
        end

        def analyzer
          @analyzer ||= Analyzers::GitAnalyzer.new(repository, options, build_time_period)
        end
      end

      # Service object for single repository analysis
      # Extracted to maintain single responsibility
      class SingleRepositoryAnalyzer
        def initialize(options, repository, analyzer)
          @options = options
          @repository = repository
          @analyzer = analyzer
        end

        def execute
          validate_repository
          display_analysis_info

          results = perform_analysis
          output_results(results)

          display_completion_message(results)
        end

        private

        attr_reader :options, :repository, :analyzer

        def validate_repository
          return if repository.git_repository?

          puts "Error: Not a Git repository: #{options[:path]}"
          exit 1
        end

        def display_analysis_info
          puts "Analyzing repository at: #{options[:path]}"
          puts "Repository: #{repository.name}"
          puts "Time period: #{build_time_period}"
          puts "Metrics: #{options[:metrics]}"
          puts "Format: #{options[:format]}"
          puts ''
        end

        def perform_analysis
          categories = extract_git_categories
          analyzer.analyze(options[:metrics], categories)
        end

        def output_results(results)
          formatter = DevMetrics::CLI::OutputFormatter.new(options[:format])
          output = formatter.format_analysis_results(results, analyzer.summary)
          DevMetrics::Services::OutputWriter.new(options[:output]).write(output)
        end

        def display_completion_message(results)
          puts "\n✅ Analysis complete! Analyzed #{results.size} metrics"
        end

        def build_time_period
          if options[:all_time]
            first_commit_date = get_first_commit_date(repository)
            Models::TimePeriod.new(first_commit_date, Time.now)
          elsif options[:since] || options[:until]
            build_custom_time_period
          else
            Models::TimePeriod.default
          end
        end

        def build_custom_time_period
          start_date = parse_time_option(options[:since]) || 30
          end_date = parse_time_option(options[:until]) || Time.now
          Models::TimePeriod.new(start_date, end_date)
        end

        def extract_git_categories
          return options[:categories] if options[:categories]

          case options[:metrics]
          when 'git' then %i[commit_activity code_churn reliability flow]
          when 'all' then nil
          end
        end

        def parse_time_option(time_option)
          return nil unless time_option

          DevMetrics::Services::TimeParser.new(time_option).parse
        end

        def get_first_commit_date(repository)
          git_command = Utils::GitCommand.new(repository.path)
          first_commit_output = git_command.execute('log --all --reverse --format=%ad --date=iso', allow_pager: true)

          return Time.now - (365 * 24 * 60 * 60) if first_commit_output.empty?

          first_line = first_commit_output.strip.split("\n").first
          require 'time'
          Time.parse(first_line)
        rescue StandardError => e
          puts "Warning: Could not determine first commit date (#{e.message}). Using 1 year ago as fallback."
          Time.now - (365 * 24 * 60 * 60)
        end
      end
    end
  end
end
