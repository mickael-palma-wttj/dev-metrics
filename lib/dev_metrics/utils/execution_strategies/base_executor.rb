# frozen_string_literal: true

require 'open3'

module DevMetrics
  module Utils
    module ExecutionStrategies
      # Base class for Git command execution strategies
      class BaseExecutor
        attr_reader :repository_path, :env_vars

        def initialize(repository_path, env_vars)
          @repository_path = repository_path
          @env_vars = env_vars
        end

        def execute(command)
          raise NotImplementedError, "#{self.class} must implement #execute"
        end

        protected

        def execution_options
          {
            chdir: repository_path,
            stdin_data: '',
            binmode: true,
          }
        end

        def handle_error(command, stderr, exit_code)
          error_message = build_error_message(command, stderr, exit_code)
          raise GitCommand::GitError, error_message
        end

        def build_error_message(command, stderr, exit_code)
          message_parts = [
            "Git command failed: #{command}",
            "Exit code: #{exit_code}",
            ("Error: #{stderr}" unless stderr.empty?),
            "Repository: #{repository_path}",
          ].compact

          message_parts.join("\n")
        end
      end
    end
  end
end
