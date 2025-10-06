# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object for Git command execution options
    class GitCommandOptions
      attr_reader :allow_pager

      def initialize(allow_pager: false)
        @allow_pager = allow_pager
      end

      def self.default
        new
      end

      def self.with_pager
        new(allow_pager: true)
      end
    end
  end
end
