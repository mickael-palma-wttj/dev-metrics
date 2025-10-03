# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Base class for CLI commands
      class BaseCommand
        attr_reader :options

        def initialize(options)
          @options = options
        end

        def execute
          raise NotImplementedError, 'Subclasses must implement #execute'
        end

        protected

        def build_time_period
          if options[:all_time]
            build_all_time_period
          elsif options[:since] || options[:until]
            build_custom_time_period
          else
            Models::TimePeriod.default
          end
        end

        private

        def build_all_time_period
          repository = Models::Repository.new(options[:path])
          first_commit_date = get_first_commit_date(repository)
          Models::TimePeriod.new(first_commit_date, Time.now)
        end

        def build_custom_time_period
          start_date = parse_time_option(options[:since]) || 30
          end_date = parse_time_option(options[:until]) || Time.now
          Models::TimePeriod.new(start_date, end_date)
        end

        def parse_time_option(time_option)
          return nil unless time_option

          Services::TimeParser.new(time_option).parse
        end

        def get_first_commit_date(repository)
          git_command = Utils::GitCommand.new(repository.path)
          first_commit_output = git_command.execute('log --all --reverse --format=%ad --date=iso', allow_pager: true)

          return default_fallback_date if first_commit_output.empty?

          parse_first_commit_date(first_commit_output)
        rescue StandardError => e
          handle_commit_date_error(e)
        end

        def default_fallback_date
          Time.now - (365 * 24 * 60 * 60)
        end

        def parse_first_commit_date(output)
          first_line = output.strip.split("\n").first
          Time.parse(first_line)
        end

        def handle_commit_date_error(error)
          puts "Warning: Could not determine first commit date (#{error.message}). Using 1 year ago as fallback."
          default_fallback_date
        end

        def extract_git_categories
          return options[:categories] if options[:categories]

          case options[:metrics]
          when 'git' then %i[commit_activity code_churn reliability flow]
          when 'all' then nil
          end
        end
      end
    end
  end
end
