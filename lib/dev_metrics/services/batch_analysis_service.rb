# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object responsible for batch analysis of multiple repositories
    # Follows Single Responsibility Principle - only handles batch analysis workflow
    class BatchAnalysisService
      def initialize(options = {})
        @options = options
      end

      def analyze_repositories(repositories)
        results = []

        puts "\n#{'=' * 60}"
        puts 'BATCH ANALYSIS REPORT'
        puts '=' * 60
        puts "Total repositories: #{repositories.size}"
        puts "Started at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        puts '=' * 60

        repositories.each_with_index do |repo, index|
          puts "\n[#{index + 1}/#{repositories.size}] Analyzing: #{repo.name}"
          puts '-' * 40

          result = analyze_single_repository(repo)
          results << result

          display_repository_result(result, index + 1, repositories.size)
        end

        results
      end

      private

      attr_reader :options

      def analyze_single_repository(repo)
        repository = Models::Repository.new(repo.path)
        analyzer = create_analyzer(repository)

        categories = extract_git_categories
        analysis_results = analyzer.analyze(options[:metrics], categories)

        SuccessfulAnalysis.new(
          repository: repository,
          analyzer: analyzer,
          results: analysis_results
        )
      rescue StandardError => e
        FailedAnalysis.new(
          repository: repository || Models::Repository.new(repo.path),
          error: e
        )
      end

      def create_analyzer(repository)
        Analyzers::GitAnalyzer.new(repository, options, build_time_period)
      end

      def build_time_period
        if options[:all_time]
          first_commit_date = get_first_commit_date
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

      def get_first_commit_date
        Time.now - (365 * 24 * 60 * 60) # Default to 1 year ago
      end

      def display_repository_result(result, current, total)
        if result.successful?
          puts '✅ Analysis completed successfully'
          puts "   Metrics analyzed: #{result.results.size}"
        else
          puts "❌ Analysis failed: #{result.error.message}"
        end

        puts "   Progress: #{current}/#{total} repositories"
        puts '-' * 40 unless current == total
      end
    end

    # Value object representing a successful analysis result
    class SuccessfulAnalysis
      attr_reader :repository, :analyzer, :results

      def initialize(repository:, analyzer:, results:)
        @repository = repository
        @analyzer = analyzer
        @results = results
      end

      def successful?
        true
      end

      def failed?
        false
      end

      def error
        nil
      end
    end

    # Value object representing a failed analysis result
    class FailedAnalysis
      attr_reader :repository, :error

      def initialize(repository:, error:)
        @repository = repository
        @error = error
      end

      def successful?
        false
      end

      def failed?
        true
      end

      def analyzer
        nil
      end

      def results
        []
      end
    end
  end
end
