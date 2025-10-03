module DevMetrics
  # Represents a Git repository with metadata and validation
  class Repository
    attr_reader :path, :name, :remote_url

    def initialize(path)
      @path = File.expand_path(path)
      validate_git_repository
      extract_metadata
    end

    def git_directory
      File.join(path, '.git')
    end

    def valid?
      File.directory?(git_directory)
    end

    def remote_origin_url
      @remote_url
    end

    def github_repository?
      !github_owner.nil? && !github_repo_name.nil?
    end

    def github_owner
      return nil unless remote_url
      match = remote_url.match(%r{github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$})
      match[1] if match
    end

    def github_repo_name
      return nil unless remote_url
      match = remote_url.match(%r{github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$})
      match[2] if match
    end

    def to_h
      {
        name: name,
        path: path,
        remote_url: remote_url,
        github_owner: github_owner,
        github_repo_name: github_repo_name,
        valid: valid?
      }
    end

    def ==(other)
      return false unless other.is_a?(Repository)
      path == other.path
    end

    def to_s
      "#{name} (#{path})"
    end

    private

    def validate_git_repository
      unless valid?
        raise ArgumentError, "Not a valid Git repository: #{path}"
      end
    end

    def extract_metadata
      @name = File.basename(path)
      @remote_url = extract_remote_url
    end

    def extract_remote_url
      config_file = File.join(git_directory, 'config')
      return nil unless File.exist?(config_file)

      content = File.read(config_file)
      match = content.match(/\[remote "origin"\].*?url = (.+)/m)
      match[1].strip if match
    rescue StandardError
      nil
    end
  end
end