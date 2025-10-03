# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Command for scanning multiple repositories
      class ScanCommand < BaseCommand
        def execute
          puts "Scanning for repositories in: #{options[:path]}"

          repositories = find_repositories
          handle_empty_results(repositories)
          display_results(repositories)
        end

        private

        def find_repositories
          selector = RepositorySelector.new(options[:path])
          selector.find_repositories(recursive: options[:recursive])
        end

        def handle_empty_results(repositories)
          return unless repositories.empty?

          puts "No Git repositories found in #{options[:path]}"
          exit 0
        end

        def display_results(repositories)
          if options[:interactive]
            display_interactive_results(repositories)
          else
            display_standard_results(repositories)
          end
        end

        def display_interactive_results(repositories)
          selector = RepositorySelector.new(options[:path])
          selected_repos = selector.interactive_select(repositories)

          puts "\nSelected repositories:"
          selected_repos.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
        end

        def display_standard_results(repositories)
          puts "Found #{repositories.length} repositories:"
          repositories.each { |repo| puts "  - #{repo.name} (#{repo.path})" }
        end
      end
    end
  end
end
