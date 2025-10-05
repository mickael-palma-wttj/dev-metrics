# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object responsible for repository discovery and validation
    # Follows Single Responsibility Principle - only handles repository scanning
    class RepositoryScannerService
      def initialize(path, options = {})
        @path = path
        @options = options
      end

      def find_repositories
        selector = DevMetrics::CLI::RepositorySelector.new(path)
        selector.find_repositories(recursive: options[:recursive])
      end

      def validate_repositories(repositories)
        return handle_empty_repositories if repositories.empty?

        repositories
      end

      def interactive_select(repositories)
        selector = DevMetrics::CLI::RepositorySelector.new(path)
        selector.interactive_select(repositories)
      end

      def direct_git_repository?
        File.directory?(File.join(path, '.git'))
      end

      private

      attr_reader :path, :options

      def handle_empty_repositories
        puts "No Git repositories found in #{path}"
        exit 0
      end
    end
  end
end
