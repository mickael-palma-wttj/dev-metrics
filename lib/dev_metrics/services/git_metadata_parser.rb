# frozen_string_literal: true

module DevMetrics
  module Services
    # Helper service for parsing Git contributor and tag output
    class GitMetadataParser
      def initialize(repository_name)
        @repository_name = repository_name
      end

      def parse_file_changes(output)
        return {} if output.empty?

        file_commits = {}
        current_commit = nil

        process_file_change_lines(output, file_commits, current_commit)
      rescue StandardError => e
        log_error("Failed to parse file changes: #{e.message}")
        {}
      end

      def parse_contributors(output)
        return [] if output.empty?

        parse_lines(output) do |line|
          parse_contributor_line(line)
        end
      rescue StandardError => e
        log_error("Failed to parse contributors: #{e.message}")
        []
      end

      def parse_tags(output)
        return [] if output.empty?

        parse_lines(output) do |line|
          parse_tag_line(line)
        end
      rescue StandardError => e
        log_error("Failed to parse tags: #{e.message}")
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

      def process_file_change_lines(output, file_commits, current_commit)
        output.split("\n").each do |line|
          line = line.strip
          next if line.empty?

          current_commit = process_file_change_line(line, file_commits, current_commit)
        end
        file_commits
      end

      def process_file_change_line(line, file_commits, current_commit)
        if commit_hash_line?(line)
          line
        elsif current_commit
          add_file_commit(file_commits, line, current_commit)
          current_commit
        else
          current_commit
        end
      end

      def commit_hash_line?(line)
        line.length == 40 && line.match?(/^[a-f0-9]+$/)
      end

      def add_file_commit(file_commits, filename, commit_hash)
        file_commits[filename] ||= []
        file_commits[filename] << commit_hash
      end

      def parse_contributor_line(line)
        match = line.match(/^\s*(\d+)\s+(.+)$/)
        return nil unless match

        commit_count = match[1].to_i
        contributor_info = match[2]
        name, email = extract_contributor_info(contributor_info)

        build_contributor(name, email, commit_count)
      end

      def extract_contributor_info(contributor_info)
        if contributor_info.match?(/^(.+)\s+<(.+)>$/)
          name_match = contributor_info.match(/^(.+)\s+<(.+)>$/)
          [name_match[1].strip, name_match[2].strip]
        else
          [contributor_info.strip, nil]
        end
      end

      def build_contributor(name, email, commit_count)
        {
          name: name,
          email: email,
          commit_count: commit_count,
          repository: repository_name,
        }
      end

      def parse_tag_line(line)
        parts = line.split('|', 2)
        return nil if parts.length < 2

        {
          name: parts[0],
          tag_name: parts[0], # alias for compatibility
          date: Time.parse(parts[1]),
          repository: repository_name,
        }
      end

      def log_error(message)
        warn(message)
      end
    end
  end
end
