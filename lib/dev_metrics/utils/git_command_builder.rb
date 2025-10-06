# frozen_string_literal: true

module DevMetrics
  module Utils
    # Builder class for constructing Git commands with proper options
    class GitCommandBuilder
      PAGER_EXEMPT_COMMANDS = %w[--version --help].freeze

      def initialize
        @env_vars = build_default_env_vars
      end

      def build(command, options = ValueObjects::GitCommandOptions.default)
        options = normalize_options(options)
        add_pager_option(command, options)
      end

      def build_git_log(options)
        command_parts = ['log']
        add_format_options(command_parts, options)
        add_filter_options(command_parts, options)
        add_output_options(command_parts, options)
        command_parts.join(' ')
      end

      def build_shortlog(summary: false, numbered: false, all: false, since: nil, until_date: nil)
        command_parts = ['shortlog']
        command_parts << '-s' if summary
        command_parts << '-n' if numbered
        command_parts << '--all' if all
        command_parts << "--since='#{since}'" if since
        command_parts << "--until='#{until_date}'" if until_date
        command_parts.join(' ')
      end

      def build_tag_list(sort_by_date: false, list: false)
        command_parts = ['tag']
        command_parts << '--sort=-creatordate' if sort_by_date
        command_parts << '-l' if list
        command_parts.join(' ')
      end

      def build_branch_list(all: false, remote: false)
        command_parts = ['branch']
        command_parts << '-a' if all
        command_parts << '-r' if remote
        command_parts.join(' ')
      end

      def build_commit_count(since: nil, until_date: nil)
        command_parts = ['rev-list', '--count', 'HEAD']
        command_parts << "--since='#{since}'" if since
        command_parts << "--until='#{until_date}'" if until_date
        command_parts.join(' ')
      end

      def env_vars
        @env_vars.dup
      end

      private

      def build_default_env_vars
        {
          'LC_ALL' => 'C.UTF-8',
          'LANG' => 'C.UTF-8',
          'GIT_TERMINAL_PROMPT' => '0',
        }
      end

      def normalize_options(options)
        return ValueObjects::GitCommandOptions.default if options.nil?
        return options if options.is_a?(ValueObjects::GitCommandOptions)
        return ValueObjects::GitCommandOptions.new(**options) if options.is_a?(Hash)

        ValueObjects::GitCommandOptions.default
      end

      def add_pager_option(command, options)
        return "git #{command}" if options.allow_pager || pager_exempt?(command)

        "git --no-pager #{command}"
      end

      def pager_exempt?(command)
        PAGER_EXEMPT_COMMANDS.any? { |cmd| command.start_with?(cmd) }
      end

      def add_format_options(parts, options)
        parts << "--format='#{options.format}'" if options.format
      end

      def add_filter_options(parts, options)
        parts << "--since='#{options.since}'" if options.since
        parts << "--until='#{options.until_date}'" if options.until_date
        parts << "--author='#{options.author}'" if options.author
        parts << "--grep='#{options.grep}'" if options.grep
        parts << "'#{options.file}'" if options.file
      end

      def add_output_options(parts, options)
        parts << '--numstat' if options.numstat
        parts << '--name-only' if options.name_only
        parts << '--oneline' if options.oneline
        parts << '--all' if options.all
      end
    end
  end
end
