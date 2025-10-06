# frozen_string_literal: true

require 'time'
require 'digest'

module DevMetrics
  module Collectors
    # Collects data from Git repositories using git log and related commands
    class GitCollector < BaseCollector
      attr_reader :git_command, :parser, :command_cache

      def initialize(repository, options = {})
        super
        @git_command = Utils::GitCommand.new(repository.path)
        @parser = Services::GitOutputParser.new(repository.name)
        @command_cache = {}
        @cache_enabled = options.fetch(:enable_cache, true)
      end

      def collect_commits(time_period = nil)
        setup_collection(time_period)
        commits_output = execute_commits_command(time_period)
        parser.parse_commits(commits_output)
      end

      def collect_commit_stats(time_period = nil)
        setup_collection(time_period)
        stats_output = execute_commit_stats_command(time_period)
        parser.parse_commit_stats(stats_output)
      end

      def collect_file_changes(time_period = nil)
        setup_collection(time_period)
        changes_output = execute_file_changes_command(time_period)
        parser.parse_file_changes(changes_output)
      end

      def collect_contributors(time_period = nil)
        setup_collection(time_period)
        shortlog_output = execute_contributors_command(time_period)
        parser.parse_contributors(shortlog_output)
      end

      def collect_tags
        tags_output = execute_tags_command
        parser.parse_tags(tags_output)
      end

      def collect_branches
        git_command.branch_list(all: true)
      end

      protected

      def validate_repository
        return if repository.valid?

        raise CollectionError, "Invalid Git repository: #{repository.path}"
      end

      def perform_collection
        # Default collection - override in specific methods
        collect_commits(@time_period)
      end

      private

      def execute_commits_command(time_period)
        if @cache_enabled
          return execute_git_log_with_cache(
            { format: '%H|%an|%ae|%ad|%s', all: true },
            :commits,
            time_period
          )
        end

        git_command.git_log(
          format: '%H|%an|%ae|%ad|%s',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          all: true
        )
      end

      def execute_commit_stats_command(time_period)
        if @cache_enabled
          return execute_git_log_with_cache(
            { format: '%H|%an|%ae|%ad|%s', numstat: true, all: true },
            :commit_stats,
            time_period
          )
        end

        git_command.git_log(
          format: '%H|%an|%ae|%ad|%s',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          numstat: true,
          all: true
        )
      end

      def execute_file_changes_command(time_period)
        if @cache_enabled
          return execute_git_log_with_cache(
            { format: '%H', name_only: true, all: true },
            :file_changes,
            time_period
          )
        end

        git_command.git_log(
          format: '%H',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          name_only: true,
          all: true
        )
      end

      def execute_contributors_command(time_period)
        if @cache_enabled
          return execute_shortlog_with_cache(
            { summary: true, numbered: true, all: true },
            :contributors,
            time_period
          )
        end

        git_command.shortlog(
          summary: true,
          numbered: true,
          all: true,
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format
        )
      end

      def execute_tags_command
        execute_with_cache(
          "tag -l --sort=-creatordate --format='%(refname:short)|%(creatordate)'",
          :tags,
          { allow_pager: true }
        )
      end

      public

      # Cache management methods
      def clear_cache
        @command_cache.clear
        reset_cache_stats
      end

      def invalidate_cache_for_time_period(time_period)
        return unless @cache_enabled

        time_key = build_time_key(time_period&.git_since_format, time_period&.git_until_format)
        @command_cache.delete_if { |key, _| key.include?(time_key) }
      end

      def cache_stats
        {
          size: @command_cache.size,
          keys: @command_cache.keys,
          hit_rate: calculate_hit_rate,
          hits: @cache_hits || 0,
          misses: @cache_misses || 0,
        }
      end

      def enable_cache
        @cache_enabled = true
      end

      def disable_cache
        @cache_enabled = false
        clear_cache
      end

      def execute_git_log_with_cache(params, cache_key_suffix, time_period)
        # Add time period to params for git_log call
        params_with_time = params.dup
        params_with_time[:since] = time_period&.git_since_format
        params_with_time[:until_date] = time_period&.git_until_format

        cache_key = build_git_log_cache_key(params_with_time, cache_key_suffix)

        if @command_cache.key?(cache_key)
          @cache_hits = (@cache_hits || 0) + 1
          return @command_cache[cache_key]
        end

        @cache_misses = (@cache_misses || 0) + 1
        result = git_command.git_log(params_with_time)
        @command_cache[cache_key] = result
        result
      end

      def execute_shortlog_with_cache(params, cache_key_suffix, time_period)
        # Add time period to params for shortlog call
        params_with_time = params.dup
        params_with_time[:since] = time_period&.git_since_format
        params_with_time[:until_date] = time_period&.git_until_format

        cache_key = build_shortlog_cache_key(params_with_time, cache_key_suffix)

        if @command_cache.key?(cache_key)
          @cache_hits = (@cache_hits || 0) + 1
          return @command_cache[cache_key]
        end

        @cache_misses = (@cache_misses || 0) + 1
        result = git_command.shortlog(params_with_time)
        @command_cache[cache_key] = result
        result
      end

      def execute_with_cache(command, cache_key_suffix, options = {}, time_period = nil)
        return git_command.execute(command, options) unless @cache_enabled

        cache_key = build_cache_key(command, cache_key_suffix, time_period)

        if @command_cache.key?(cache_key)
          @cache_hits = (@cache_hits || 0) + 1
          return @command_cache[cache_key]
        end

        @cache_misses = (@cache_misses || 0) + 1
        result = git_command.execute(command, options)
        @command_cache[cache_key] = result
        result
      end

      def build_git_log_cache_key(params, suffix)
        time_key = build_time_key(params[:since], params[:until_date])
        params_key = params.except(:since, :until_date).to_s
        "git_log_#{suffix}_#{time_key}_#{Digest::SHA256.hexdigest(params_key)[0..8]}"
      end

      def build_shortlog_cache_key(params, suffix)
        time_key = build_time_key(params[:since], params[:until_date])
        params_key = params.except(:since, :until_date).to_s
        "shortlog_#{suffix}_#{time_key}_#{Digest::SHA256.hexdigest(params_key)[0..8]}"
      end

      def build_cache_key(command, suffix, time_period)
        time_key = time_period ? "#{time_period.git_since_format}_#{time_period.git_until_format}" : 'all_time'
        "#{suffix}_#{time_key}_#{Digest::SHA256.hexdigest(command)[0..8]}"
      end

      def build_time_key(since_date, until_date)
        return 'all_time' unless since_date || until_date

        "#{since_date || 'beginning'}_#{until_date || 'now'}"
      end

      def calculate_hit_rate
        total_requests = (@cache_hits || 0) + (@cache_misses || 0)
        return 0.0 if total_requests.zero?

        ((@cache_hits || 0).to_f / total_requests * 100).round(2)
      end

      def reset_cache_stats
        @cache_hits = 0
        @cache_misses = 0
      end
    end
  end
end
