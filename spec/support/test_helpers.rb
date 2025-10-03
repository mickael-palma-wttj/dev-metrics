# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

module TestHelpers
  # Creates a temporary Git repository for testing
  def create_test_repository(name = 'test-repo')
    repo_path = File.join(Dir.tmpdir, "dev-metrics-test-#{name}-#{Time.now.to_i}")
    FileUtils.mkdir_p(repo_path)

    Dir.chdir(repo_path) do
      system('git init --quiet')
      system('git config user.name "Test User"')
      system('git config user.email "test@example.com"')

      # Create initial commit
      File.write('README.md', "# Test Repository\n\nThis is a test repository.")
      system('git add README.md')
      system('git commit -m "Initial commit" --quiet')
    end

    (@test_repositories ||= []) << repo_path
    DevMetrics::Models::Repository.new(repo_path)
  end

  # Creates test commits with specific patterns
  def create_test_commits(repository, commit_data)
    Dir.chdir(repository.path) do
      commit_data.each_with_index do |data, index|
        filename = data[:file] || "file_#{index}.txt"
        content = data[:content] || "Content for commit #{index}"
        author = data[:author] || 'Test User <test@example.com>'
        message = data[:message] || "Test commit #{index}"
        date = data[:date] || Time.now

        File.write(filename, content)
        system("git add #{filename}")

        # Set author and date for commit
        env_vars = {
          'GIT_AUTHOR_NAME' => author.split('<').first.strip,
          'GIT_AUTHOR_EMAIL' => author.match(/<(.+)>/)[1],
          'GIT_AUTHOR_DATE' => date.to_s,
          'GIT_COMMITTER_NAME' => author.split('<').first.strip,
          'GIT_COMMITTER_EMAIL' => author.match(/<(.+)>/)[1],
          'GIT_COMMITTER_DATE' => date.to_s,
        }

        system(env_vars, "git commit -m '#{message}' --quiet")
      end
    end
  end

  # Mock GitHub API responses
  def mock_github_api_response(_endpoint, response_data)
    # Simple mock for testing - in real implementation would use WebMock or similar
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(
      double('response', body: response_data.to_json, code: '200')
    )
  end

  # Clean up test repositories
  def cleanup_test_repositories
    return unless @test_repositories

    @test_repositories.each do |repo_path|
      FileUtils.rm_rf(repo_path)
    end
    @test_repositories.clear
  end

  # Create test contributors
  def create_test_contributor(name = 'John Doe', email = 'john@example.com')
    DevMetrics::Models::Contributor.new(name, email)
  end

  # Create test time period
  def create_test_time_period(days_ago = 30)
    start_date = Time.now - (days_ago * 24 * 60 * 60)
    DevMetrics::Models::TimePeriod.new(start_date, Time.now)
  end
end

RSpec.configure do |config|
  config.include TestHelpers

  config.after(:suite) do
    # Final cleanup
    cleanup_test_repositories if respond_to?(:cleanup_test_repositories)
  end
end
