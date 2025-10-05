# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for formatting Git log commands and output options
    class GitLogFormatterService
      DEFAULT_COMMIT_FORMAT = '%H|%an|%ae|%ai|%s'
      COMMIT_STATS_FORMAT = '%H|%an|%ae|%ai|%s'
      PRETTY_FORMAT = '%H|%an|%ae|%ai|%s'

      def initialize(repository_path)
        @repository_path = repository_path
      end

      def format_commits_command(since_date: nil, until_date: nil, limit: nil)
        command_parts = ["--pretty=format:#{DEFAULT_COMMIT_FORMAT}"]
        command_parts << '--all'
        command_parts << "--since=\"#{since_date}\"" if since_date
        command_parts << "--until=\"#{until_date}\"" if until_date
        command_parts << "-n #{limit}" if limit

        command_parts.join(' ')
      end

      def format_commit_stats_command(since_date: nil, until_date: nil, limit: nil)
        command_parts = ["--pretty=format:#{COMMIT_STATS_FORMAT}"]
        command_parts << '--numstat'
        command_parts << '--all'
        command_parts << "--since=\"#{since_date}\"" if since_date
        command_parts << "--until=\"#{until_date}\"" if until_date
        command_parts << "-n #{limit}" if limit

        command_parts.join(' ')
      end

      def format_file_changes_command(since_date: nil, until_date: nil)
        command_parts = ['--pretty=format:%H']
        command_parts << '--name-only'
        command_parts << '--all'
        command_parts << "--since=\"#{since_date}\"" if since_date
        command_parts << "--until=\"#{until_date}\"" if until_date

        command_parts.join(' ')
      end

      def format_contributors_command(since_date: nil, until_date: nil)
        command_parts = []
        command_parts << '--shortlog'
        command_parts << '--summary'
        command_parts << '--numbered'
        command_parts << '--email'
        command_parts << '--all'
        command_parts << "--since=\"#{since_date}\"" if since_date
        command_parts << "--until=\"#{until_date}\"" if until_date

        command_parts.join(' ')
      end

      def format_tags_command
        '--pretty=format:%D|%ai --all'
      end

      def format_log_command(args)
        "log #{args}"
      end

      private

      attr_reader :repository_path
    end
  end
end
