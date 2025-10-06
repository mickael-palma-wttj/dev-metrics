# frozen_string_literal: true

module DevMetrics
  module Utils
    # Wrapper for executing Git commands safely with proper error handling
    class GitCommand
      class GitError < StandardError; end

      attr_reader :repository_path, :command_builder

      def initialize(repository_path)
        @repository_path = File.expand_path(repository_path)
        @command_builder = GitCommandBuilder.new
        validate_git_repository
      end

      def execute(command, options = {})
        full_command = command_builder.build(command, options)
        standard_executor.execute(full_command)
      end

      def execute_lines(command, options = {})
        output = execute(command, options)
        return [] if output.empty?

        output.split("\n").map(&:strip)
      end

      def execute_with_timeout(command, timeout_seconds = 30, options = {})
        full_command = command_builder.build(command, options)
        timeout_executor(timeout_seconds).execute(full_command)
      end

      def execute_streaming(command, options = {})
        full_command = command_builder.build(command, options)
        streaming_executor.execute(full_command)
      end

      def git_log(params = {})
        log_options = ValueObjects::GitLogOptions.from_hash(params)
        command = command_builder.build_git_log(log_options)
        execute(command, allow_pager: true)
      end

      def shortlog(options = {})
        command = command_builder.build_shortlog(**options)
        execute(command, allow_pager: true)
      end

      def tag_list(options = {})
        command = command_builder.build_tag_list(**options)
        execute_lines(command, allow_pager: true)
      end

      def branch_list(options = {})
        command = command_builder.build_branch_list(**options)
        execute_lines(command, allow_pager: true)
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
        command = command_builder.build_commit_count(since: since, until_date: until_date)
        execute(command).to_i
      end

      private

      def validate_git_repository
        return if File.directory?(File.join(repository_path, '.git'))

        raise GitError, "Not a Git repository: #{repository_path}"
      end

      def standard_executor
        @standard_executor ||= ExecutionStrategies::StandardExecutor.new(
          repository_path,
          command_builder.env_vars
        )
      end

      def timeout_executor(timeout_seconds)
        ExecutionStrategies::TimeoutExecutor.new(
          repository_path,
          command_builder.env_vars,
          timeout_seconds: timeout_seconds
        )
      end

      def streaming_executor
        @streaming_executor ||= ExecutionStrategies::StreamingExecutor.new(
          repository_path,
          command_builder.env_vars
        )
      end
    end
  end
end
