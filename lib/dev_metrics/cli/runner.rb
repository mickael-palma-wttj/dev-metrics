require 'time'

module DevMetrics
  module CLI
    # Main CLI runner that handles command parsing and orchestrates the application
    class Runner
      COMMANDS = %w[analyze scan report config help].freeze

      attr_reader :args, :command, :options

      def initialize(args)
        @args = args
        @command = extract_command
        @options = parse_options
      end

      def run
        validate_command

        case command
        when 'analyze'
          run_analyze
        when 'scan'
          run_scan
        when 'report'
          run_report
        when 'config'
          run_config
        when 'help', nil
          show_help
        else
          show_help
          exit 1
        end
      end

      private

      def extract_command
        return nil if args.empty?

        first_arg = args.first
        COMMANDS.include?(first_arg) ? first_arg : 'analyze'
      end

      def parse_options
        options = {
          path: extract_path,
          metrics: extract_metrics,
          categories: extract_categories,
          format: extract_option('--format', 'text'),
          output: extract_option('--output'),
          since: extract_option('--since'),
          until: extract_option('--until'),
          contributors: extract_contributors,
          interactive: has_flag?('--interactive'),
          recursive: has_flag?('--recursive'),
          exclude_bots: has_flag?('--exclude-bots'),
          include_merge_commits: !has_flag?('--exclude-merges'),
          no_progress: has_flag?('--no-progress'),
          all_time: has_flag?('--all-time')
        }

        validate_options(options)
        options
      end

      def extract_path
        path_arg = command == 'analyze' && args.length > 1 ? args[1] : nil
        path_arg ||= args.find { |arg| !arg.start_with?('--') && arg != command }
        File.expand_path(path_arg || '.')
      end

      def extract_metrics
        metrics_value = extract_option('--metrics', 'all')
        return 'all' if metrics_value == 'all'

        metrics_value.split(',').map(&:strip)
      end

      def extract_contributors
        contributors_value = extract_option('--contributors')
        return [] unless contributors_value

        contributors_value.split(',').map(&:strip)
      end

      def extract_categories
        categories_value = extract_option('--categories')
        return nil unless categories_value

        categories_value.split(',').map(&:strip).map(&:to_sym)
      end

      def extract_git_categories
        # Map CLI category names to Git metric categories
        return options[:categories] if options[:categories]

        case options[:metrics]
        when 'git' then %i[commit_activity code_churn reliability flow]
        when 'all' then nil # All categories
        else nil
        end
      end

      def write_output(content)
        if options[:output]
          File.write(options[:output], content)
          puts "Results written to: #{options[:output]}"
        else
          puts content
        end
      end

      def extract_option(flag, default = nil)
        index = args.find_index { |arg| arg.start_with?(flag) }
        return default unless index

        arg = args[index]
        if arg.include?('=')
          arg.split('=', 2)[1]
        elsif index + 1 < args.length && !args[index + 1].start_with?('--')
          args[index + 1]
        else
          default
        end
      end

      def has_flag?(flag)
        args.any? { |arg| arg == flag }
      end

      def validate_command
        return if command.nil? || COMMANDS.include?(command)

        puts "Unknown command: #{command}"
        show_help
        exit 1
      end

      def validate_options(options)
        # Validate path exists
        unless File.exist?(options[:path])
          puts "Error: Path does not exist: #{options[:path]}"
          exit 1
        end

        # Validate output format
        valid_formats = %w[text json csv html markdown]
        return if valid_formats.include?(options[:format])

        puts "Error: Invalid format '#{options[:format]}'. Valid formats: #{valid_formats.join(', ')}"
        exit 1
      end

      def run_analyze
        puts "Analyzing repository at: #{options[:path]}"

        begin
          repository = DevMetrics::Models::Repository.new(options[:path])

          # Validate repository has Git data
          unless repository.git_repository?
            puts "Error: Not a Git repository: #{options[:path]}"
            exit 1
          end

          puts "Repository: #{repository.name}"
          puts "Time period: #{build_time_period}"
          puts "Metrics: #{options[:metrics]}"
          puts "Format: #{options[:format]}"
          puts ''

          # Run Git metrics analysis
          analyzer = DevMetrics::Analyzers::GitAnalyzer.new(repository, options)

          categories = extract_git_categories
          results = analyzer.analyze(options[:metrics], categories)

          # Format and output results
          formatter = DevMetrics::CLI::OutputFormatter.new(options[:format])
          output = formatter.format_analysis_results(results, analyzer.summary)

          write_output(output)

          puts "\n✅ Analysis complete! Analyzed #{results.size} metrics"
        rescue ArgumentError => e
          puts "Error: #{e.message}"
          exit 1
        rescue StandardError => e
          puts "Unexpected error: #{e.message}"
          puts 'Please check your repository and try again.'
          exit 1
        end
      end

      def run_scan
        puts "Scanning for repositories in: #{options[:path]}"

        selector = DevMetrics::CLI::RepositorySelector.new(options[:path])
        repositories = selector.find_repositories(recursive: options[:recursive])

        if repositories.empty?
          puts "No Git repositories found in #{options[:path]}"
          exit 0
        end

        if options[:interactive]
          selected_repos = selector.interactive_select(repositories)
          puts "\nSelected repositories:"
          selected_repos.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
        else
          puts "Found #{repositories.length} repositories:"
          repositories.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
        end
      end

      def run_report
        puts 'Generating report...'
        puts '[Phase 1 Complete] Report generation structure ready!'
      end

      def run_config
        puts 'Configuration management...'
        puts '[Phase 1 Complete] Config management structure ready!'
      end

      def build_time_period
        if options[:all_time]
          # Create repository to get first commit date
          repository = DevMetrics::Models::Repository.new(options[:path])
          first_commit_date = get_first_commit_date(repository)
          DevMetrics::Models::TimePeriod.new(first_commit_date, Time.now)
        elsif options[:since] || options[:until]
          start_date = parse_time_option(options[:since]) || 30
          end_date = parse_time_option(options[:until]) || Time.now
          DevMetrics::Models::TimePeriod.new(start_date, end_date)
        else
          DevMetrics::Models::TimePeriod.default
        end
      end

      def parse_time_option(time_option)
        return nil unless time_option

        if time_option.is_a?(String) && time_option.match?(/^\d+[dwmy]$/)
          # Relative time format (30d, 2w, 1m, 1y)
          number = time_option.to_i
          unit = time_option[-1]

          case unit
          when 'd' then Time.now - (number * 24 * 60 * 60)
          when 'w' then Time.now - (number * 7 * 24 * 60 * 60)
          when 'm' then Time.now - (number * 30 * 24 * 60 * 60)
          when 'y' then Time.now - (number * 365 * 24 * 60 * 60)
          end
        else
          Time.parse(time_option.to_s)
        end
      rescue ArgumentError
        raise ArgumentError, "Invalid time format: #{time_option}"
      end

      def get_first_commit_date(repository)
        # Use GitCommand to get the first commit date
        git_command = DevMetrics::Utils::GitCommand.new(repository.path)

        # Get the oldest commit directly using log with reverse order
        # Use --all to include all branches and limit to first result
        first_commit_output = git_command.execute('log --all --reverse --format=%ad --date=iso', allow_pager: true)

        return Time.now - (365 * 24 * 60 * 60) if first_commit_output.empty? # Fallback to 1 year ago

        # Get the first line (oldest commit)
        first_line = first_commit_output.strip.split("\n").first
        Time.parse(first_line)
      rescue StandardError => e
        puts "Warning: Could not determine first commit date (#{e.message}). Using 1 year ago as fallback."
        Time.now - (365 * 24 * 60 * 60) # Fallback to 1 year ago
      end

      def show_help
        puts <<~HELP
          Developer Metrics CLI

          USAGE:
            dev-metrics <command> [path] [options]

          COMMANDS:
            analyze [path]     Analyze a single repository (default)
            scan [path]        Scan for multiple repositories#{'  '}
            report             Generate detailed reports
            config             Manage configuration
            help               Show this help message

          OPTIONS:
            --metrics=CATS     Comma-separated metric categories (default: all)
                              Available: git,all or specific metric names
            --categories=CATS  Git metric categories: commit_activity,code_churn,reliability,flow
            --format=FORMAT    Output format: text,json,csv,html,markdown (default: text)
            --output=FILE      Output file path (default: stdout)
            --since=DATE       Start date (YYYY-MM-DD or relative like 30d)
            --until=DATE       End date (YYYY-MM-DD)
            --all-time         Analyze since the first commit in the repository
            --contributors=X   Focus on specific contributors (comma-separated)
            --interactive      Interactive repository selection
            --recursive        Scan subdirectories for repositories
            --exclude-bots     Exclude bot accounts from analysis
            --exclude-merges   Exclude merge commits from analysis
            --no-progress      Disable progress indicators

          EXAMPLES:
            dev-metrics analyze .
            dev-metrics analyze /path/to/repo --format=json --output=metrics.json
            dev-metrics analyze . --all-time --format=text
            dev-metrics scan /workspace --interactive --metrics=git,pr_throughput
            dev-metrics analyze . --since=2024-01-01 --contributors=john.doe

          For more information, visit: https://github.com/your-username/dev-metrics-new
        HELP
      end
    end
  end
end
