# frozen_string_literal: true

module DevMetrics
  module Collectors
    # Handles Git command execution with caching support
    #
    # This class encapsulates the logic for executing Git commands through
    # the cache manager, building appropriate parameters, and delegating
    # to the underlying git_command wrapper.
    class GitCommandExecutor
      TAG_LIST_COMMAND = "tag -l --sort=-creatordate --format='%(refname:short)|%(creatordate)'"
      private_constant :TAG_LIST_COMMAND

      # Initialize a new GitCommandExecutor
      #
      # @param git_command [Utils::GitCommand] the Git command wrapper
      # @param cache_manager [GitCommandCache] the cache manager for command results
      def initialize(git_command, cache_manager)
        @git_command = git_command
        @cache_manager = cache_manager
      end

      def execute_commits_command(time_period)
        params = GitCommandParams.for_commits(time_period)
        execute_cached_git_log(params, :commits)
      end

      def execute_commit_stats_command(time_period)
        params = GitCommandParams.for_commit_stats(time_period)
        execute_cached_git_log(params, :commit_stats)
      end

      def execute_file_changes_command(time_period)
        params = GitCommandParams.for_file_changes(time_period)
        execute_cached_git_log(params, :file_changes)
      end

      def execute_contributors_command(time_period)
        params = GitCommandParams.for_contributors(time_period)
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
    end
  end
end
