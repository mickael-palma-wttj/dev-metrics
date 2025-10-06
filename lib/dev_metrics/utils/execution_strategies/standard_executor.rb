# frozen_string_literal: true

module DevMetrics
  module Utils
    module ExecutionStrategies
      # Standard synchronous Git command execution
      class StandardExecutor < BaseExecutor
        def execute(command)
          stdout, stderr, status = Open3.capture3(
            env_vars,
            command,
            execution_options
          )

          handle_error(command, stderr, status.exitstatus) unless status.success?

          stdout.strip
        end
      end
    end
  end
end
