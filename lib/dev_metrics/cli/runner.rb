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
          format: extract_option('--format', 'text'),
          output: extract_option('--output'),
          since: extract_option('--since'),
          until: extract_option('--until'),
          contributors: extract_contributors,
          interactive: has_flag?('--interactive'),
          recursive: has_flag?('--recursive'),
          exclude_bots: has_flag?('--exclude-bots'),
          no_progress: has_flag?('--no-progress')
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
        valid_formats = %w[text json csv html]
        return if valid_formats.include?(options[:format])

        puts "Error: Invalid format '#{options[:format]}'. Valid formats: #{valid_formats.join(', ')}"
        exit 1
      end

      def run_analyze
        puts "Analyzing repository at: #{options[:path]}"

        begin
          repository = DevMetrics::Models::Repository.new(options[:path])
          time_period = build_time_period

          puts "Repository: #{repository.name}"
          puts "Time period: #{time_period}"
          puts "Metrics: #{options[:metrics]}"
          puts "Format: #{options[:format]}"

          # For now, just show what would be analyzed
          # In Phase 2, we'll implement actual metric collection
          puts "\n[Phase 1 Complete] Analysis structure ready!"
          puts 'Next: Implement Git metrics collection in Phase 2'
        rescue ArgumentError => e
          puts "Error: #{e.message}"
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
        if options[:since] || options[:until]
          start_date = options[:since] ? Time.parse(options[:since]) : 30
          end_date = options[:until] ? Time.parse(options[:until]) : Time.now
          DevMetrics::Models::TimePeriod.new(start_date, end_date)
        else
          DevMetrics::Models::TimePeriod.default
        end
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
                              Available: git,pr_throughput,team_health,all
            --format=FORMAT    Output format: text,json,csv,html (default: text)
            --output=FILE      Output file path (default: stdout)
            --since=DATE       Start date (YYYY-MM-DD or relative like 30d)
            --until=DATE       End date (YYYY-MM-DD)
            --contributors=X   Focus on specific contributors (comma-separated)
            --interactive      Interactive repository selection
            --recursive        Scan subdirectories for repositories
            --exclude-bots     Exclude bot accounts from analysis
            --no-progress      Disable progress indicators

          EXAMPLES:
            dev-metrics analyze .
            dev-metrics analyze /path/to/repo --format=json --output=metrics.json
            dev-metrics scan /workspace --interactive --metrics=git,pr_throughput
            dev-metrics analyze . --since=2024-01-01 --contributors=john.doe

          For more information, visit: https://github.com/your-username/dev-metrics-new
        HELP
      end
    end
  end
end
