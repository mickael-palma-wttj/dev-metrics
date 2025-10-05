# frozen_string_literal: true

require 'time'
require_relative '../services/git_output_parser'

module DevMetrics
  module Collectors
    # Collects data from Git repositories using git log and related commands
    class GitCollector < BaseCollector
      attr_reader :git_command, :parser

      def initialize(repository, options = {})
        super
        @git_command = Utils::GitCommand.new(repository.path)
        @parser = Services::GitOutputParser.new(repository.name)
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
        git_command.git_log(
          format: '%H|%an|%ae|%ad|%s',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          all: true
        )
      end

      def execute_commit_stats_command(time_period)
        git_command.git_log(
          format: '%H|%an|%ae|%ad|%s',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          numstat: true,
          all: true
        )
      end

      def execute_file_changes_command(time_period)
        git_command.git_log(
          format: '%H',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          name_only: true,
          all: true
        )
      end

      def execute_contributors_command(time_period)
        git_command.shortlog(
          summary: true,
          numbered: true,
          all: true,
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format
        )
      end

      def execute_tags_command
        git_command.execute(
          "tag -l --sort=-creatordate --format='%(refname:short)|%(creatordate)'",
          allow_pager: true
        )
      end
    end
  end
end
