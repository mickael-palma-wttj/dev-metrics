# frozen_string_literal: true

require 'time'
require 'digest'

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
        setup_collection(time_period)
        commits_output = @command_executor.execute_commits_command(time_period)
        parser.parse_commits(commits_output)
      end

      # Collects commit statistics including file change counts
      #
      # @param time_period [TimePeriod, nil] the time period to collect stats for, or nil for all time
      # @return [Array<CommitStat>] array of parsed commit statistics
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_commit_stats(time_period = nil)
        setup_collection(time_period)
        stats_output = @command_executor.execute_commit_stats_command(time_period)
        parser.parse_commit_stats(stats_output)
      end

      # Collects file change information for commits
      #
      # @param time_period [TimePeriod, nil] the time period to collect changes for, or nil for all time
      # @return [Array<FileChange>] array of parsed file changes
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_file_changes(time_period = nil)
        setup_collection(time_period)
        changes_output = @command_executor.execute_file_changes_command(time_period)
        parser.parse_file_changes(changes_output)
      end

      # Collects contributor information from git shortlog
      #
      # @param time_period [TimePeriod, nil] the time period to collect contributors for, or nil for all time
      # @return [Array<Contributor>] array of parsed contributors
      # @raise [CollectionError] if repository is invalid or collection fails
      def collect_contributors(time_period = nil)
        setup_collection(time_period)
        shortlog_output = @command_executor.execute_contributors_command(time_period)
        parser.parse_contributors(shortlog_output)
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

      # Cache management delegation

      # Clears all cached command results and resets statistics
      #
      # @return [void]
      def clear_cache
        @cache_manager.clear
      end

      # Returns cache statistics
      #
      # @return [Hash] statistics hash with keys:
      #   - :size [Integer] number of cached entries
      #   - :enabled [Boolean] whether caching is enabled
      #   - :hit_rate [Float] cache hit rate as percentage
      #   - :hits [Integer] number of cache hits
      #   - :misses [Integer] number of cache misses
      def cache_stats
        @cache_manager.stats
      end

      # Enables command caching
      #
      # @return [void]
      def enable_cache
        @cache_manager.enable
      end

      # Disables command caching and clears existing cache
      #
      # @return [void]
      def disable_cache
        @cache_manager.disable
      end

      protected

      def validate_repository
        return if repository.valid?

        raise CollectionError, "Invalid Git repository: #{repository.path}"
      end

      def perform_collection
        collect_commits(@time_period)
      end
    end

    # Handles Git command execution with caching support
    #
    # This class encapsulates the logic for executing Git commands through
    # the cache manager, building appropriate parameters, and delegating
    # to the underlying git_command wrapper.
    class GitCommandExecutor
      COMMIT_FORMAT = '%H|%an|%ae|%ad|%s'
      HASH_FORMAT = '%H'
      TAG_LIST_COMMAND = "tag -l --sort=-creatordate --format='%(refname:short)|%(creatordate)'"

      # Initialize a new GitCommandExecutor
      #
      # @param git_command [Utils::GitCommand] the Git command wrapper
      # @param cache_manager [GitCommandCache] the cache manager for command results
      def initialize(git_command, cache_manager)
        @git_command = git_command
        @cache_manager = cache_manager
      end

      def execute_commits_command(time_period)
        params = build_commits_params(time_period)
        execute_cached_git_log(params, :commits)
      end

      def execute_commit_stats_command(time_period)
        params = build_commit_stats_params(time_period)
        execute_cached_git_log(params, :commit_stats)
      end

      def execute_file_changes_command(time_period)
        params = build_file_changes_params(time_period)
        execute_cached_git_log(params, :file_changes)
      end

      def execute_contributors_command(time_period)
        params = build_contributors_params(time_period)
        execute_cached_shortlog(params, :contributors)
      end

      def execute_tags_command
        @cache_manager.execute_with_cache(TAG_LIST_COMMAND, :tags) do
          @git_command.execute(TAG_LIST_COMMAND, allow_pager: true)
        end
      end

      private

      def execute_cached_git_log(params, cache_key)
        @cache_manager.execute_with_cache_key(cache_key, params) do
          @git_command.git_log(params)
        end
      end

      def execute_cached_shortlog(params, cache_key)
        @cache_manager.execute_with_cache_key(cache_key, params) do
          @git_command.shortlog(params)
        end
      end

      def build_commits_params(time_period)
        GitCommandParams.new
          .with_format(COMMIT_FORMAT)
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      def build_commit_stats_params(time_period)
        GitCommandParams.new
          .with_format(COMMIT_FORMAT)
          .with_numstat
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      def build_file_changes_params(time_period)
        GitCommandParams.new
          .with_format(HASH_FORMAT)
          .with_name_only
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      def build_contributors_params(time_period)
        GitCommandParams.new
          .with_summary
          .with_numbered
          .with_all
          .with_time_period(time_period)
          .to_h
      end
    end

    # Value object for building Git command parameters
    #
    # Uses the Builder pattern with a fluent interface to construct
    # parameter hashes for Git commands. Each method returns self
    # to allow method chaining.
    #
    # @example
    #   params = GitCommandParams.new
    #     .with_format('%H|%an')
    #     .with_all
    #     .with_time_period(time_period)
    #     .to_h
    class GitCommandParams
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

    # Manages Git command caching with statistics
    #
    # This class provides an in-memory cache for Git command results
    # with hit/miss tracking and configurable enable/disable functionality.
    # Uses a CacheKeyBuilder to generate consistent cache keys.
    class GitCommandCache
      attr_reader :cache, :enabled

      # Initialize a new cache manager
      #
      # @param enabled [Boolean] whether caching is enabled by default
      def initialize(enabled = true)
        @cache = {}
        @enabled = enabled
        @hits = 0
        @misses = 0
        @key_builder = CacheKeyBuilder.new
      end

      # Execute a command with caching based on command string
      #
      # @param command [String] the Git command to execute
      # @param suffix [Symbol] the cache key suffix/identifier
      # @yield the block to execute if cache miss occurs
      # @return [String] the command output (cached or fresh)
      def execute_with_cache(command, suffix, &block)
        return block.call unless @enabled

        cache_key = @key_builder.build_command_key(command, suffix)
        fetch_or_execute(cache_key, &block)
      end

      # Execute a command with caching based on parameter hash
      #
      # @param suffix [Symbol] the cache key suffix/identifier
      # @param params [Hash] the command parameters
      # @yield the block to execute if cache miss occurs
      # @return [String] the command output (cached or fresh)
      def execute_with_cache_key(suffix, params, &block)
        return block.call unless @enabled

        cache_key = @key_builder.build_params_key(suffix, params)
        fetch_or_execute(cache_key, &block)
      end

      # Clears the cache and resets statistics
      #
      # @return [void]
      def clear
        @cache.clear
        reset_stats
      end

      def enable
        @enabled = true
      end

      def disable
        @enabled = false
        clear
      end

      def stats
        {
          size: @cache.size,
          enabled: @enabled,
          hit_rate: calculate_hit_rate,
          hits: @hits,
          misses: @misses,
        }
      end

      private

      def fetch_or_execute(cache_key)
        if @cache.key?(cache_key)
          @hits += 1
          @cache[cache_key]
        else
          @misses += 1
          result = yield
          @cache[cache_key] = result
          result
        end
      end

      def calculate_hit_rate
        total = @hits + @misses
        return 0.0 if total.zero?

        (@hits.to_f / total * 100).round(2)
      end

      def reset_stats
        @hits = 0
        @misses = 0
      end
    end

    # Builds consistent cache keys for different command types
    #
    # Uses SHA256 hashing to generate short, collision-resistant cache keys
    # from command strings or parameter hashes. Includes time period information
    # when applicable to ensure cache invalidation across different time ranges.
    class CacheKeyBuilder
      # First 9 characters of SHA256 hash for collision resistance
      HASH_PREFIX_LENGTH = 9

      # Builds a cache key from a command string
      #
      # @param command [String] the Git command
      # @param suffix [Symbol] the cache key identifier
      # @return [String] the generated cache key
      def build_command_key(command, suffix)
        command_hash = hash_digest(command)
        "#{suffix}_#{command_hash}"
      end

      # Builds a cache key from command parameters
      #
      # Includes time period information to ensure different time ranges
      # generate different cache keys.
      #
      # @param suffix [Symbol] the cache key identifier
      # @param params [Hash] the command parameters
      # @return [String] the generated cache key
      def build_params_key(suffix, params)
        time_key = extract_time_key(params)
        params_without_time = params.except(:since, :until_date)
        params_hash = hash_digest(params_without_time.to_s)
        "#{suffix}_#{time_key}_#{params_hash}"
      end

      private

      def hash_digest(value)
        Digest::SHA256.hexdigest(value.to_s)[0...HASH_PREFIX_LENGTH]
      end

      def extract_time_key(params)
        since_date = params[:since]
        until_date = params[:until_date]

        return 'all_time' unless since_date || until_date

        "#{since_date || 'beginning'}_#{until_date || 'now'}"
      end
    end
  end
end
