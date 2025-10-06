# frozen_string_literal: true

module DevMetrics
  module Collectors
    # Collects data from Git repositories using git log and related commands
    class GitCollector < BaseCollector
      attr_reader :git_command, :parser, :cache_manager

      # Initialize a new GitCollector
      #
      # @param repository [Repository] the repository to collect data from
      # @param options [Hash] configuration options
      # @option options [Boolean] :enable_cache (true) whether to enable command caching
      def initialize(repository, options = {})
        super
        @git_command = Utils::GitCommand.new(repository.path)
        @parser = Services::GitOutputParser.new(repository.name)
        @cache_manager = GitCommandCache.new(options.fetch(:enable_cache, true))
        @command_executor = GitCommandExecutor.new(@git_command, @cache_manager)
      end

      # Collects commit data for the specified time period
      #
      # @param time_period [TimePeriod, nil] the time period to collect commits for, or nil for all time
      # @return [Array<Commit>] array of parsed commit objects
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_commits(time_period = nil)
        collect_and_parse(time_period, :commits)
      end

      # Collects commit statistics including file change counts
      #
      # @param time_period [TimePeriod, nil] the time period to collect stats for, or nil for all time
      # @return [Array<CommitStat>] array of parsed commit statistics
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_commit_stats(time_period = nil)
        collect_and_parse(time_period, :commit_stats)
      end

      # Collects file change information for commits
      #
      # @param time_period [TimePeriod, nil] the time period to collect changes for, or nil for all time
      # @return [Array<FileChange>] array of parsed file changes
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_file_changes(time_period = nil)
        collect_and_parse(time_period, :file_changes)
      end

      # Collects contributor information from git shortlog
      #
      # @param time_period [TimePeriod, nil] the time period to collect contributors for, or nil for all time
      # @return [Array<Contributor>] array of parsed contributors
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_contributors(time_period = nil)
        collect_and_parse(time_period, :contributors)
      end

      # Collects all repository tags
      #
      # @return [Array<Tag>] array of parsed tags with creation dates
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_tags
        tags_output = @command_executor.execute_tags_command
        parser.parse_tags(tags_output)
      end

      # Collects all repository branches
      #
      # @return [Array<String>] array of branch names
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_branches
        git_command.branch_list(all: true)
      end

      protected

      def validate_repository
        return if repository.valid?

        raise CollectionError, build_validation_error_message
      end

      def perform_collection
        collect_commits(@time_period)
      end

      private

      # Template method for collecting and parsing data
      #
      # @param time_period [TimePeriod, nil] the time period for collection
      # @param data_type [Symbol] the type of data to collect (:commits, :commit_stats, etc.)
      # @return [Array] parsed results from the collector
      def collect_and_parse(time_period, data_type)
        setup_collection(time_period)
        output = @command_executor.send("execute_#{data_type}_command", time_period)
        parser.send("parse_#{data_type}", output)
      end

      def build_validation_error_message
        "Invalid Git repository at '#{repository.path}'. " \
          'Ensure the directory exists and contains a .git folder.'
      end
    end
  end
end
