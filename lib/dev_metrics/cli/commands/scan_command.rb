# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Command for scanning multiple repositories
      class ScanCommand < BaseCommand
        def execute
          puts "Scanning for repositories in: #{options[:path]}"

          repositories = find_repositories
          handle_empty_results(repositories)
          display_results(repositories)
        end

        private

        def find_repositories
          selector = RepositorySelector.new(options[:path])
          selector.find_repositories(recursive: options[:recursive])
        end

        def handle_empty_results(repositories)
          return unless repositories.empty?

          puts "No Git repositories found in #{options[:path]}"
          exit 0
        end

        def display_results(repositories)
          if options[:interactive]
            display_interactive_results(repositories)
          else
            display_standard_results(repositories)
          end
        end

        def display_interactive_results(repositories)
          selector = RepositorySelector.new(options[:path])
          selected_repos = selector.interactive_select(repositories)

          puts "\nSelected repositories:"
          selected_repos.each { |repo| puts "  - #{repo.name} (#{repo.path})" }

          return unless selected_repos.any?

          puts "\nRunning analysis on #{selected_repos.size} selected repositories..."
          run_batch_analysis(selected_repos)
        end

        def display_standard_results(repositories)
          puts "Found #{repositories.length} repositories:"
          repositories.each { |repo| puts "  - #{repo.name} (#{repo.path})" }

          return unless should_auto_analyze?(repositories)

          puts "\nRunning analysis on all #{repositories.size} repositories..."
          run_batch_analysis(repositories)
        end

        def should_auto_analyze?(repositories)
          # Auto-analyze if --analyze flag is provided or if only 1 repository found
          options[:analyze] || repositories.size == 1
        end

        def run_batch_analysis(repositories)
          all_results = []
          failed_repos = []

          repositories.each_with_index do |repo, index|
            puts "\n[#{index + 1}/#{repositories.size}] Analyzing #{repo.name}..."

            begin
              result = analyze_single_repository(repo)
              all_results << { repository: repo, result: result }
              puts "  ✅ #{repo.name} - Analysis complete (#{result.size} metrics)"
            rescue StandardError => e
              failed_repos << { repository: repo, error: e.message }
              puts "  ❌ #{repo.name} - Analysis failed: #{e.message}"
            end
          end

          generate_batch_report(all_results, failed_repos)
        end

        def analyze_single_repository(repository)
          time_period = build_time_period_for_repository(repository)
          analyzer = Analyzers::GitAnalyzer.new(repository, options, time_period)
          categories = extract_git_categories
          analyzer.analyze(options[:metrics] || 'all', categories)
        end

        def generate_batch_report(results, failed_repos)
          return if results.empty?

          puts "\n" + ('=' * 50)
          puts 'BATCH ANALYSIS SUMMARY'
          puts '=' * 50

          puts "Successful: #{results.size} repositories"
          puts "Failed: #{failed_repos.size} repositories" if failed_repos.any?

          # Generate individual reports for each repository
          results.each do |result_data|
            repo = result_data[:repository]
            result = result_data[:result]

            time_period = build_time_period_for_repository(repo)
            analyzer = Analyzers::GitAnalyzer.new(repo, options, time_period)
            analyzer.instance_variable_set(:@results, result)

            output_path = generate_output_path(repo)
            formatter = OutputFormatter.new(options[:format] || 'text')
            output = formatter.format_analysis_results(result, analyzer.summary)

            Services::OutputWriter.new(output_path).write(output)
            puts "📄 #{repo.name} report: #{output_path}"
          end

          return unless failed_repos.any?

          puts "\nFailed repositories:"
          failed_repos.each do |failure|
            puts "  ❌ #{failure[:repository].name}: #{failure[:error]}"
          end
        end

        def build_time_period_for_repository(repository)
          if options[:all_time]
            first_commit_date = get_first_commit_date(repository)
            Models::TimePeriod.new(first_commit_date, Time.now)
          elsif options[:since] || options[:until]
            build_custom_time_period
          else
            Models::TimePeriod.default
          end
        end

        def generate_output_path(repository)
          timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
          extension = options[:format] == 'json' ? 'json' : 'txt'
          "./report/#{repository.name}_metrics_#{timestamp}.#{extension}"
        end
      end
    end
  end
end
