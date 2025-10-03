module DevMetrics
  module CLI
    # Handles Git repository detection and selection
    class RepositorySelector
      attr_reader :base_path

      def initialize(base_path)
        @base_path = File.expand_path(base_path)
      end

      def find_repositories(recursive: false)
        repositories = []

        repositories << DevMetrics::Models::Repository.new(base_path) if git_repository?(base_path)

        repositories.concat(find_nested_repositories) if recursive

        repositories.uniq { |repo| repo.path }
      end

      def interactive_select(repositories)
        return repositories if repositories.length <= 1

        puts "\nFound #{repositories.length} repositories:"
        repositories.each_with_index do |repo, index|
          github_info = repo.github_repository? ? " (GitHub: #{repo.github_owner}/#{repo.github_repo_name})" : ''
          puts "  #{index + 1}. #{repo.name}#{github_info}"
          puts "     #{repo.path}"
        end

        puts "\nSelect repositories to analyze:"
        puts '  - Enter numbers separated by commas (e.g., 1,3,5)'
        puts "  - Enter 'all' to select all repositories"
        puts '  - Press Enter to select all'

        print '> '
        input = $stdin.gets.chomp.strip

        return repositories if input.empty? || input.downcase == 'all'

        selected_indices = parse_selection(input, repositories.length)
        selected_indices.map { |i| repositories[i] }
      end

      private

      def git_repository?(path)
        File.directory?(File.join(path, '.git'))
      end

      def find_nested_repositories
        repositories = []

        Dir.glob(File.join(base_path, '**/'), File::FNM_DOTMATCH).each do |dir|
          next if dir == base_path
          next unless git_repository?(dir)
          next if nested_in_git_repo?(dir)

          begin
            repositories << DevMetrics::Models::Repository.new(dir)
          rescue ArgumentError
            # Skip invalid repositories
          end
        end

        repositories
      end

      def nested_in_git_repo?(path)
        parent_dir = File.dirname(path)
        while parent_dir != base_path && parent_dir != '/'
          return true if git_repository?(parent_dir)

          parent_dir = File.dirname(parent_dir)
        end
        false
      end

      def parse_selection(input, max_count)
        indices = []

        input.split(',').each do |part|
          part = part.strip

          if part.include?('-')
            # Handle ranges like "1-5"
            start_num, end_num = part.split('-').map(&:to_i)
            indices.concat((start_num - 1)..(end_num - 1)) if valid_range?(start_num, end_num, max_count)
          else
            # Handle single numbers
            num = part.to_i
            indices << num - 1 if valid_number?(num, max_count)
          end
        end

        indices.uniq.sort
      rescue StandardError
        puts 'Invalid selection. Selecting all repositories.'
        (0...max_count).to_a
      end

      def valid_number?(num, max_count)
        num > 0 && num <= max_count
      end

      def valid_range?(start_num, end_num, max_count)
        start_num > 0 && end_num <= max_count && start_num <= end_num
      end
    end
  end
end
