# frozen_string_literal: true

require 'open3'

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

        stdout, stderr, status = Open3.capture3(full_command, chdir: repository_path)

        handle_error(command, stderr, status.exitstatus) unless status.success?

        stdout.strip
      end

      def execute_lines(command, options = {})
        output = execute(command, options)
        return [] if output.empty?

        output.split("\n").map(&:strip)
      end

      def git_log(format: nil, since: nil, until_date: nil, author: nil, grep: nil, file: nil, **options)
        command_parts = ['log']

        command_parts << "--format='#{format}'" if format
        command_parts << "--since='#{since}'" if since
        command_parts << "--until='#{until_date}'" if until_date
        command_parts << "--author='#{author}'" if author
        command_parts << "--grep='#{grep}'" if grep
        command_parts << '--numstat' if options[:numstat]
        command_parts << '--name-only' if options[:name_only]
        command_parts << '--oneline' if options[:oneline]
        command_parts << '--all' if options[:all]
        command_parts << "'#{file}'" if file

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

      def build_command(command, options)
        base_command = "git #{command}"

        # Add common options
        base_command += ' --no-pager' unless options[:allow_pager]

        base_command
      end

      def handle_error(command, stderr, exit_code)
        error_message = "Git command failed: #{command}\n"
        error_message += "Exit code: #{exit_code}\n"
        error_message += "Error: #{stderr}" unless stderr.empty?

        raise GitError, error_message
      end
    end
  end
end
