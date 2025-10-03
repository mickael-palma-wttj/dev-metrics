module DevMetrics
  # Represents a contributor with identity resolution and metadata
  class Contributor
    attr_reader :name, :email, :aliases

    def initialize(name, email = nil, aliases = [])
      @name = normalize_name(name)
      @email = normalize_email(email)
      @aliases = aliases.map { |a| normalize_name(a) }.uniq
    end

    def primary_identity
      email || name
    end

    def matches?(other_name, other_email = nil)
      return true if name == normalize_name(other_name)
      return true if email && email == normalize_email(other_email)
      return true if aliases.include?(normalize_name(other_name))
      
      false
    end

    def add_alias(alias_name)
      normalized = normalize_name(alias_name)
      @aliases << normalized unless @aliases.include?(normalized) || normalized == name
    end

    def to_h
      {
        name: name,
        email: email,
        aliases: aliases,
        primary_identity: primary_identity
      }
    end

    def ==(other)
      return false unless other.is_a?(Contributor)
      primary_identity == other.primary_identity
    end

    def to_s
      email ? "#{name} <#{email}>" : name
    end

    private

    def normalize_name(name)
      return nil if name.nil? || name.strip.empty?
      
      # Remove common Git artifacts and normalize
      normalized = name.strip
                      .gsub(/\s+/, ' ')
                      .gsub(/[<>]/, '')
      
      # Handle common patterns like "Name (Company)" -> "Name"
      normalized.gsub(/\s*\([^)]+\)$/, '')
    end

    def normalize_email(email)
      return nil if email.nil? || email.strip.empty?
      
      email.strip.downcase
    end
  end
end