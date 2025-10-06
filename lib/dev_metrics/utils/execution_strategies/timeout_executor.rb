# frozen_string_literal: true

require 'timeout'

module DevMetrics
  module Utils
    module ExecutionStrategies
      # Git command execution with timeout protection
      class TimeoutExecutor < BaseExecutor
        DEFAULT_TIMEOUT = 30

        attr_reader :timeout_seconds

        def initialize(repository_path, env_vars, timeout_seconds: DEFAULT_TIMEOUT)
          super(repository_path, env_vars)
          @timeout_seconds = timeout_seconds
        end

        def execute(command)
          stdout, stderr, status = execute_with_timeout(command)

          handle_error(command, stderr, status.exitstatus) unless status.success?

          stdout.strip
        rescue Timeout::Error
          raise GitCommand::GitError, "Git command timed out after #{timeout_seconds} seconds: #{command}"
        end

        private

        def execute_with_timeout(command)
          Timeout.timeout(timeout_seconds) do
            Open3.capture3(env_vars, command, execution_options)
          end
        end
      end
    end
  end
end
