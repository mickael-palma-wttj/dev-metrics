# frozen_string_literal: true

module DevMetrics
  module Services
    # Helper service for parsing Git commit-related output
    class GitCommitParser
      def initialize(repository_name)
        @repository_name = repository_name
      end

      def parse_commits(output)
        return [] if output.empty?

        parse_lines(output) do |line|
          parse_commit_line(line)
        end
      rescue StandardError => e
        log_error("Failed to parse commits: #{e.message}")
        []
      end

      def parse_commit_stats(output)
        return [] if output.empty?

        commits = []
        current_commit = nil

        process_stats_lines(output, commits, current_commit)
      rescue StandardError => e
        log_error("Failed to parse commit stats: #{e.message}")
        []
      end

      private

      attr_reader :repository_name

      def parse_lines(output)
        results = []
        output.split("\n").each do |line|
          next if line.strip.empty?

          result = yield(line)
          results << result if result
        end
        results
      end

      def parse_commit_line(line)
        parts = line.split('|', 5)
        return nil if parts.length < 5

        build_basic_commit(parts)
      end

      def build_basic_commit(parts)
        {
          hash: parts[0],
          author_name: parts[1],
          author_email: parts[2],
          date: Time.parse(parts[3]),
          message: parts[4],
          repository: repository_name,
        }
      end

      def commit_header_line?(line)
        line.include?('|') && line.count('|') >= 4
      end

      def process_stats_lines(output, commits, current_commit)
        output.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          current_commit = process_stats_line(line, commits, current_commit)
        end
        commits
      end

      def process_stats_line(line, commits, current_commit)
        if commit_header_line?(line)
          current_commit = build_commit_header(line)
          commits << current_commit
        elsif current_commit && numstat_line?(line)
          process_numstat_line(line, current_commit)
        end
        current_commit
      end

      def build_commit_header(line)
        parts = line.split('|', 5)
        build_header_hash(parts)
      end

      def build_header_hash(parts)
        {
          hash: parts[0],
          author_name: parts[1],
          author_email: parts[2],
          date: Time.parse(parts[3]),
          subject: parts[4],
          repository: repository_name,
          files_changed: [],
          additions: 0,
          deletions: 0,
        }
      end

      def numstat_line?(line)
        line.match?(/^(\d+|-)\s+(\d+|-)\s+(.+)$/)
      end

      def process_numstat_line(line, commit)
        match = line.match(/^(\d+|-)\s+(\d+|-)\s+(.+)$/)
        additions = match[1] == '-' ? 0 : match[1].to_i
        deletions = match[2] == '-' ? 0 : match[2].to_i
        filename = match[3]

        commit[:files_changed] << build_file_change(filename, additions, deletions)
        commit[:additions] += additions
        commit[:deletions] += deletions
      end

      def build_file_change(filename, additions, deletions)
        {
          filename: filename,
          additions: additions,
          deletions: deletions,
        }
      end

      def log_error(message)
        warn(message)
      end
    end
  end
end
