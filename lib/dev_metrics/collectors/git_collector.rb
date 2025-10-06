# frozen_string_literal: true

require 'time'
require 'digest'

module DevMetrics
  module Collectors
    # Collects data from Git repositories using git log and related commands
    class GitCollector < BaseCollector
      attr_reader :git_command, :parser, :cache_manager

      def initialize(repository, options = {})
        super
        @git_command = Utils::GitCommand.new(repository.path)
        @parser = Services::GitOutputParser.new(repository.name)
        @cache_manager = GitCommandCache.new(options.fetch(:enable_cache, true))
        @command_executor = GitCommandExecutor.new(@git_command, @cache_manager)
      end

      def collect_commits(time_period = nil)
        setup_collection(time_period)
        commits_output = @command_executor.execute_commits_command(time_period)
        parser.parse_commits(commits_output)
      end

      def collect_commit_stats(time_period = nil)
        setup_collection(time_period)
        stats_output = @command_executor.execute_commit_stats_command(time_period)
        parser.parse_commit_stats(stats_output)
      end

      def collect_file_changes(time_period = nil)
        setup_collection(time_period)
        changes_output = @command_executor.execute_file_changes_command(time_period)
        parser.parse_file_changes(changes_output)
      end

      def collect_contributors(time_period = nil)
        setup_collection(time_period)
        shortlog_output = @command_executor.execute_contributors_command(time_period)
        parser.parse_contributors(shortlog_output)
      end

      def collect_tags
        tags_output = @command_executor.execute_tags_command
        parser.parse_tags(tags_output)
      end

      def collect_branches
        git_command.branch_list(all: true)
      end

      # Cache management delegation
      def clear_cache
        @cache_manager.clear
      end

      def cache_stats
        @cache_manager.stats
      end

      def enable_cache
        @cache_manager.enable
      end

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
    class GitCommandExecutor
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
        command = "tag -l --sort=-creatordate --format='%(refname:short)|%(creatordate)'"
        @cache_manager.execute_with_cache(command, :tags) do
          @git_command.execute(command, allow_pager: true)
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
          .with_format('%H|%an|%ae|%ad|%s')
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      def build_commit_stats_params(time_period)
        GitCommandParams.new
          .with_format('%H|%an|%ae|%ad|%s')
          .with_numstat
          .with_all
          .with_time_period(time_period)
          .to_h
      end

      def build_file_changes_params(time_period)
        GitCommandParams.new
          .with_format('%H')
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
    class GitCommandParams
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

      def to_h
        @params.dup
      end
    end

    # Manages Git command caching with statistics
    class GitCommandCache
      attr_reader :cache, :enabled

      def initialize(enabled = true)
        @cache = {}
        @enabled = enabled
        @hits = 0
        @misses = 0
        @key_builder = CacheKeyBuilder.new
      end

      def execute_with_cache(command, suffix, &block)
        return block.call unless @enabled

        cache_key = @key_builder.build_command_key(command, suffix)
        fetch_or_execute(cache_key, &block)
      end

      def execute_with_cache_key(suffix, params, &block)
        return block.call unless @enabled

        cache_key = @key_builder.build_params_key(suffix, params)
        fetch_or_execute(cache_key, &block)
      end

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
    class CacheKeyBuilder
      def build_command_key(command, suffix)
        command_hash = Digest::SHA256.hexdigest(command)[0..8]
        "#{suffix}_#{command_hash}"
      end

      def build_params_key(suffix, params)
        time_key = extract_time_key(params)
        params_without_time = params.except(:since, :until_date)
        params_hash = Digest::SHA256.hexdigest(params_without_time.to_s)[0..8]
        "#{suffix}_#{time_key}_#{params_hash}"
      end

      private

      def extract_time_key(params)
        since_date = params[:since]
        until_date = params[:until_date]

        return 'all_time' unless since_date || until_date

        "#{since_date || 'beginning'}_#{until_date || 'now'}"
      end
    end
  end
end
