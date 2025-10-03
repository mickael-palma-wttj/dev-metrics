# frozen_string_literal: true

require 'time'

module DevMetrics
  module Services
    # Service object responsible for parsing CLI arguments and options
    class CliOptionParser
      COMMANDS = %w[analyze scan report config help].freeze
      VALID_FORMATS = %w[text json csv html markdown].freeze

      attr_reader :args

      def initialize(args)
        @args = args
      end

      def parse
        build_options_hash
      end

      def build_options_hash
        basic_options.merge(flag_options)
      end

      def basic_options
        command_options.merge(time_options)
      end

      def command_options
        {
          command: extract_command,
          path: extract_path,
          metrics: extract_metrics,
          categories: extract_categories,
          format: extract_option('--format', 'text'),
          output: extract_output_path,
        }
      end

      def time_options
        {
          since: extract_option('--since'),
          until: extract_option('--until'),
          contributors: extract_contributors,
        }
      end

      def flag_options
        {
          interactive: flag?('--interactive'),
          recursive: flag?('--recursive'),
          exclude_bots: flag?('--exclude-bots'),
          include_merge_commits: !flag?('--exclude-merges'),
          no_progress: flag?('--no-progress'),
          all_time: flag?('--all-time'),
        }
      end

      def extract_command
        return nil if args.empty?

        first_arg = args.first
        COMMANDS.include?(first_arg) ? first_arg : 'analyze'
      end

      private

      def extract_path
        command = extract_command
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

      def extract_output_path
        custom_output = extract_option('--output')
        return custom_output if custom_output

        # Default to ./report folder with auto-generated filename
        OutputPathGenerator.new(extract_path, extract_option('--format', 'text')).generate
      end

      def extract_option(flag, default = nil)
        index = find_flag_index(flag)
        return default unless index

        extract_value_from_flag(index, default)
      end

      def find_flag_index(flag)
        args.find_index { |arg| arg.start_with?(flag) }
      end

      def extract_value_from_flag(index, default)
        arg = args[index]
        return extract_equals_value(arg) if arg.include?('=')
        return extract_next_arg_value(index, default) if next_value?(index)

        default
      end

      def extract_equals_value(arg)
        arg.split('=', 2)[1]
      end

      def extract_next_arg_value(index, default)
        return args[index + 1] if index + 1 < args.length

        default
      end

      def next_value?(index)
        index + 1 < args.length && !args[index + 1].start_with?('--')
      end

      def flag?(flag)
        args.any? { |arg| arg == flag }
      end
    end

    # Helper service for generating output file paths
    class OutputPathGenerator
      def initialize(repository_path, format)
        @repository_path = repository_path
        @format = format
      end

      def generate
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        repository_name = File.basename(@repository_path)
        extension = format_extension(@format)

        "./report/#{repository_name}_metrics_#{timestamp}.#{extension}"
      end

      private

      def format_extension(format)
        case format
        when 'json' then 'json'
        when 'csv' then 'csv'
        when 'html' then 'html'
        when 'markdown' then 'md'
        else 'txt'
        end
      end
    end
  end
end
