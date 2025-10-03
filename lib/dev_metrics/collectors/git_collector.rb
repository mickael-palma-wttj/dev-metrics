module DevMetrics
  module Collectors
    # Collects data from Git repositories using git log and related commands
    class GitCollector < BaseCollector
      attr_reader :git_command

      def initialize(repository, options = {})
        super(repository, options)
        @git_command = Utils::GitCommand.new(repository.path)
      end

      def collect_commits(time_period = nil)
        setup_collection(time_period)
        
        format = '%H|%an|%ae|%ad|%s'
        
        commits_output = git_command.git_log(
          format: format,
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          all: true
        )
        
        parse_commits(commits_output)
      end

      def collect_commit_stats(time_period = nil)
        setup_collection(time_period)
        
        format = '%H|%an|%ae|%ad|%s'
        
        stats_output = git_command.git_log(
          format: format,
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          numstat: true,
          all: true
        )
        
        parse_commit_stats(stats_output)
      end

      def collect_file_changes(time_period = nil)
        setup_collection(time_period)
        
        changes_output = git_command.git_log(
          format: '%H',
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_format,
          name_only: true,
          all: true
        )
        
        parse_file_changes(changes_output)
      end

      def collect_contributors(time_period = nil)
        setup_collection(time_period)
        
        shortlog_output = git_command.shortlog(
          summary: true,
          numbered: true,
          all: true,
          since: time_period&.git_since_format,
          until_date: time_period&.git_until_date
        )
        
        parse_contributors(shortlog_output)
      end

      def collect_tags
        git_command.tag_list(sort_by_date: true, list: true)
      end

      def collect_branches
        git_command.branch_list(all: true)
      end

      protected

      def validate_repository
        unless repository.valid?
          raise CollectionError, "Invalid Git repository: #{repository.path}"
        end
      end

      def perform_collection
        # Default collection - override in specific methods
        collect_commits(@time_period)
      end

      private

      def parse_commits(output)
        return [] if output.empty?
        
        commits = []
        output.split("\n").each do |line|
          next if line.strip.empty?
          
          parts = line.split('|', 5)
          next if parts.length < 5
          
          commits << {
            hash: parts[0],
            author_name: parts[1],
            author_email: parts[2],
            date: Time.parse(parts[3]),
            subject: parts[4],
            repository: repository.name
          }
        end
        
        commits
      rescue => e
        log_error("Failed to parse commits: #{e.message}")
        []
      end

      def parse_commit_stats(output)
        return [] if output.empty?
        
        commits = []
        current_commit = nil
        
        output.split("\n").each do |line|
          line = line.strip
          next if line.empty?
          
          if line.include?('|') && line.count('|') >= 4
            # This is a commit header line
            parts = line.split('|', 5)
            current_commit = {
              hash: parts[0],
              author_name: parts[1],
              author_email: parts[2],
              date: Time.parse(parts[3]),
              subject: parts[4],
              repository: repository.name,
              files_changed: [],
              additions: 0,
              deletions: 0
            }
            commits << current_commit
          elsif current_commit && line.match(/^(\d+|-)\s+(\d+|-)\s+(.+)$/)
            # This is a numstat line
            match = line.match(/^(\d+|-)\s+(\d+|-)\s+(.+)$/)
            additions = match[1] == '-' ? 0 : match[1].to_i
            deletions = match[2] == '-' ? 0 : match[2].to_i
            filename = match[3]
            
            current_commit[:files_changed] << {
              filename: filename,
              additions: additions,
              deletions: deletions
            }
            
            current_commit[:additions] += additions
            current_commit[:deletions] += deletions
          end
        end
        
        commits
      rescue => e
        log_error("Failed to parse commit stats: #{e.message}")
        []
      end

      def parse_file_changes(output)
        return {} if output.empty?
        
        file_commits = {}
        current_commit = nil
        
        output.split("\n").each do |line|
          line = line.strip
          next if line.empty?
          
          if line.length == 40 && line.match(/^[a-f0-9]+$/)
            # This is a commit hash
            current_commit = line
          elsif current_commit
            # This is a filename
            file_commits[line] ||= []
            file_commits[line] << current_commit
          end
        end
        
        file_commits
      rescue => e
        log_error("Failed to parse file changes: #{e.message}")
        {}
      end

      def parse_contributors(output)
        return [] if output.empty?
        
        contributors = []
        output.split("\n").each do |line|
          next if line.strip.empty?
          
          match = line.match(/^\s*(\d+)\s+(.+)$/)
          next unless match
          
          commit_count = match[1].to_i
          contributor_info = match[2]
          
          # Parse "Name <email>" format
          if contributor_info.match(/^(.+)\s+<(.+)>$/)
            name_match = contributor_info.match(/^(.+)\s+<(.+)>$/)
            name = name_match[1].strip
            email = name_match[2].strip
          else
            name = contributor_info.strip
            email = nil
          end
          
          contributors << {
            name: name,
            email: email,
            commit_count: commit_count,
            repository: repository.name
          }
        end
        
        contributors
      rescue => e
        log_error("Failed to parse contributors: #{e.message}")
        []
      end
    end
  end
end