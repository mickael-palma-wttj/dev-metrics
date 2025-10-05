# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object responsible for determining analysis mode
    # Follows Single Responsibility Principle - only handles mode detection logic
    class AnalysisModeDetector
      def initialize(path, options = {})
        @path = path
        @options = options
      end

      def batch_mode?
        recursive_scan_requested? || interactive_mode_requested? || not_direct_git_repository?
      end

      def single_repository_mode?
        !batch_mode?
      end

      def interactive_batch_mode?
        batch_mode? && interactive_mode_requested?
      end

      def non_interactive_batch_mode?
        batch_mode? && !interactive_mode_requested?
      end

      private

      attr_reader :path, :options

      def recursive_scan_requested?
        options[:recursive]
      end

      def interactive_mode_requested?
        options[:interactive]
      end

      def not_direct_git_repository?
        !direct_git_repository?
      end

      def direct_git_repository?
        File.directory?(File.join(path, '.git'))
      end
    end
  end
end
