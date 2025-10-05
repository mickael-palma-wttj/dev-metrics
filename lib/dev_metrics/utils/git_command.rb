# frozen_string_literal: true

require 'open3'
require 'timeout'

module DevMetrics
  module Utils
    # Wrapper for executing Git commands safely with proper error handling
    class GitCommand
      class GitError < StandardError; end

      attr_reader :repository_path

      def initialize(repository_path)
        @repository_path = File.expand_path(repository_path)
        validate_git_repository
      end

      def execute(command, options = {})
        full_command = build_command(command, options)

        # Use Open3.capture3 with explicit environment and options
        stdout, stderr, status = Open3.capture3(
          build_env_vars,
          full_command,
          chdir: repository_path,
          stdin_data: '',
          binmode: true
        )

        handle_error(command, stderr, status.exitstatus) unless status.success?

        stdout.strip
      end

      def execute_lines(command, options = {})
        output = execute(command, options)
        return [] if output.empty?

        output.split("\n").map(&:strip)
      end

      def execute_with_timeout(command, timeout_seconds = 30, options = {})
        full_command = build_command(command, options)
        stdout, stderr, status = execute_with_capture3_timeout(full_command, timeout_seconds)

        handle_error(command, stderr, status.exitstatus) unless status.success?
        stdout.strip
      rescue Timeout::Error
        raise GitError, "Git command timed out after #{timeout_seconds} seconds: #{command}"
      end

      def execute_streaming(command, options = {})
        full_command = build_command(command, options)
        execute_with_popen3_streaming(full_command, command)
      end

      def git_log(params = {})
        command_parts = build_git_log_command(params)
        execute(command_parts.join(' '), allow_pager: true)
      end

      def shortlog(options = {})
        command_parts = ['shortlog']

        command_parts << '-s' if options[:summary]
        command_parts << '-n' if options[:numbered]
        command_parts << '--all' if options[:all]
        command_parts << "--since='#{options[:since]}'" if options[:since]
        command_parts << "--until='#{options[:until_date]}'" if options[:until_date]

        execute(command_parts.join(' '), allow_pager: true)
      end

      def tag_list(options = {})
        command_parts = ['tag']

        command_parts << '--sort=-creatordate' if options[:sort_by_date]
        command_parts << '-l' if options[:list]

        execute_lines(command_parts.join(' '), allow_pager: true)
      end

      def branch_list(options = {})
        command_parts = ['branch']

        command_parts << '-a' if options[:all]
        command_parts << '-r' if options[:remote]

        execute_lines(command_parts.join(' '), allow_pager: true)
      end

      def config(key)
        execute("config #{key}")
      rescue GitError
        nil
      end

      def remote_url(remote = 'origin')
        config("remote.#{remote}.url")
      end

      def current_branch
        execute('rev-parse --abbrev-ref HEAD')
      rescue GitError
        'main' # fallback
      end

      def commit_count(since: nil, until_date: nil)
        command_parts = ['rev-list', '--count', 'HEAD']

        command_parts << "--since='#{since}'" if since
        command_parts << "--until='#{until_date}'" if until_date

        execute(command_parts.join(' ')).to_i
      end

      private

      def validate_git_repository
        return if File.directory?(File.join(repository_path, '.git'))

        raise GitError, "Not a Git repository: #{repository_path}"
      end

      def build_env_vars
        {
          'LC_ALL' => 'C.UTF-8',
          'LANG' => 'C.UTF-8',
          'GIT_TERMINAL_PROMPT' => '0',
        }
      end

      def build_command(command, options)
        # Add --no-pager as a global git option (before the subcommand) unless explicitly allowing pager
        if options[:allow_pager] || command_doesnt_support_pager?(command)
          "git #{command}"
        else
          "git --no-pager #{command}"
        end
      end

      def command_doesnt_support_pager?(command)
        # Commands that don't need pager control
        no_pager_commands = %w[--version --help]
        no_pager_commands.any? { |cmd| command.start_with?(cmd) }
      end

      def handle_error(command, stderr, exit_code)
        error_message = "Git command failed: #{command}\n"
        error_message += "Exit code: #{exit_code}\n"
        error_message += "Error: #{stderr}" unless stderr.empty?
        error_message += "Repository: #{repository_path}"

        raise GitError, error_message
      end

      def execute_with_capture3_timeout(full_command, timeout_seconds)
        Timeout.timeout(timeout_seconds) do
          Open3.capture3(
            build_env_vars,
            full_command,
            chdir: repository_path,
            stdin_data: '',
            binmode: true
          )
        end
      end

      def execute_with_popen3_streaming(full_command, original_command)
        output_lines = []

        Open3.popen3(build_env_vars, full_command, chdir: repository_path) do |stdin, stdout, stderr, wait_thr|
          stdin.close
          collect_streaming_output(stdout, output_lines)
          handle_streaming_result(stderr, wait_thr, original_command)
        end

        output_lines.join("\n")
      end

      def collect_streaming_output(stdout, output_lines)
        stdout.each_line do |line|
          output_lines << line.strip
        end
      end

      def handle_streaming_result(stderr, wait_thr, original_command)
        stderr_output = stderr.read
        exit_status = wait_thr.value.exitstatus
        handle_error(original_command, stderr_output, exit_status) unless wait_thr.value.success?
      end

      def build_git_log_command(params)
        command_parts = ['log']
        add_log_format_options(command_parts, params)
        add_log_filter_options(command_parts, params)
        add_log_output_options(command_parts, params)
        command_parts
      end

      def add_log_format_options(command_parts, params)
        command_parts << "--format='#{params[:format]}'" if params[:format]
      end

      def add_log_filter_options(command_parts, params)
        command_parts << "--since='#{params[:since]}'" if params[:since]
        command_parts << "--until='#{params[:until_date]}'" if params[:until_date]
        command_parts << "--author='#{params[:author]}'" if params[:author]
        command_parts << "--grep='#{params[:grep]}'" if params[:grep]
        command_parts << "'#{params[:file]}'" if params[:file]
      end

      def add_log_output_options(command_parts, params)
        command_parts << '--numstat' if params[:numstat]
        command_parts << '--name-only' if params[:name_only]
        command_parts << '--oneline' if params[:oneline]
        command_parts << '--all' if params[:all]
      end
    end
  end
end
