# frozen_string_literal: true

module DevMetrics
  module Utils
    module ExecutionStrategies
      # Streaming Git command execution for large outputs
      class StreamingExecutor < BaseExecutor
        def execute(command)
          output_lines = []

          Open3.popen3(env_vars, command, chdir: repository_path) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            collect_output(stdout, output_lines)
            verify_success(stderr, wait_thr, command)
          end

          output_lines.join("\n")
        end

        private

        def collect_output(stdout, output_lines)
          stdout.each_line do |line|
            output_lines << line.strip
          end
        end

        def verify_success(stderr, wait_thr, command)
          return if wait_thr.value.success?

          stderr_output = stderr.read
          exit_status = wait_thr.value.exitstatus
          handle_error(command, stderr_output, exit_status)
        end
      end
    end
  end
end
