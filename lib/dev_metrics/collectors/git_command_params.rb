# frozen_string_literal: true

module DevMetrics
  module Collectors
    # Value object for building Git command parameters
    #
    # Uses the Builder pattern with a fluent interface to construct
    # parameter hashes for Git commands. Each method returns self
    # to allow method chaining. Provides factory methods for common
    # parameter configurations.
    #
    # @example Direct usage
    #   params = GitCommandParams.new
    #     .with_format('%H|%an')
    #     .with_all
    #     .with_time_period(time_period)
    #     .to_h
    #
    # @example Factory method usage
    #   params = GitCommandParams.for_commits(time_period)
    class GitCommandParams
      COMMIT_FORMAT = '%H|%an|%ae|%ad|%s'
      HASH_FORMAT = '%H'

      # Factory method for commit collection parameters
      #
      # @param time_period [TimePeriod, nil] optional time period filter
      # @return [Hash] parameter hash for git log commit collection
      def self.for_commits(time_period)
        new.with_format(COMMIT_FORMAT)
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      # Factory method for commit statistics parameters
      #
      # @param time_period [TimePeriod, nil] optional time period filter
      # @return [Hash] parameter hash for git log with numstat
      def self.for_commit_stats(time_period)
        new.with_format(COMMIT_FORMAT)
          .with_numstat
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      # Factory method for file changes parameters
      #
      # @param time_period [TimePeriod, nil] optional time period filter
      # @return [Hash] parameter hash for git log with name-only
      def self.for_file_changes(time_period)
        new.with_format(HASH_FORMAT)
          .with_name_only
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      # Factory method for contributor collection parameters
      #
      # @param time_period [TimePeriod, nil] optional time period filter
      # @return [Hash] parameter hash for git shortlog
      def self.for_contributors(time_period)
        new.with_summary
          .with_numbered
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      # Initialize a new parameter builder
      def initialize
        @params = {}
      end

      def with_format(format)
        @params[:format] = format
        self
      end

      def with_numstat
        @params[:numstat] = true
        self
      end

      def with_name_only
        @params[:name_only] = true
        self
      end

      def with_summary
        @params[:summary] = true
        self
      end

      def with_numbered
        @params[:numbered] = true
        self
      end

      def with_all
        @params[:all] = true
        self
      end

      def with_time_period(time_period)
        return self unless time_period

        @params[:since] = time_period.git_since_format
        @params[:until_date] = time_period.git_until_format
        self
      end

      # Returns a duplicate of the parameters hash
      #
      # @return [Hash] the built parameters
      def to_h
        @params.dup
      end
    end
  end
end
