# frozen_string_literal: true

module DevMetrics
  module Utils
    # Shared production tag patterns for consistent deployment identification
    module ProductionTagPatterns
      # Define production release tag patterns
      # These patterns identify tags that represent production deployments
      PRODUCTION_PATTERNS = [
        # Semantic versioning patterns
        /^v?\d+\.\d+\.\d+$/,                              # v1.2.3 or 1.2.3
        /^v?\d+\.\d+\.\d+[-_](alpha|beta|rc\d*)/i,        # v1.2.3-alpha, v1.2.3-beta, v1.2.3-rc1

        # Release branch patterns
        /^release[-_]v?\d+\.\d+/, # release-v1.2 or release_1.2

        # Environment-specific patterns
        /^prod[-_]/i,                                     # prod- or prod_
        /^production[-_]/i,                               # production- or production_
        /[-_]prod$/i,                                     # -prod or _prod
        /[-_]release$/i,                                  # -release or _release
        /^deploy[-_]/i,                                   # deploy- or deploy_
        /[-_]deploy$/i,                                   # -deploy or _deploy

        # Date-based versioning patterns (common in many organizations)
        /^v\d{4}\.\d{2}\.\d{2}(\.\d+)?$/, # v2025.10.02, v2025.09.01.1
        /^v\d{4}\.\d{2}\.\d{2}(\.\d+)?[-_](alpha|beta|rc\d*)/i, # v2025.10.02-alpha

        # Compact date patterns
        /^v\d{8}(\.\d+)?$/,                              # v20250630, v20250123.2
        /^v\d{8}(\.\d+)?[-_](alpha|beta|rc\d*)/i,        # v20250630-alpha, v20240403.1-alpha
        /^v\d{8}[-_]\d+$/,                               # v20241024_1, v20240109-1

        # Simple version numbers
        /^v\d+$/, # v31, v30, v29, etc.
      ].freeze

      # Check if a tag name matches production patterns
      def self.production_tag?(tag_name)
        return false if tag_name.nil? || tag_name.empty?

        PRODUCTION_PATTERNS.any? { |pattern| tag_name.match?(pattern) }
      end

      # Filter tags to only include production releases
      def self.filter_production_tags(tags)
        tags.select do |tag|
          tag_name = tag[:name] || tag[:tag_name] || ''
          production_tag?(tag_name)
        end
      end

      # Get list of all production patterns (for debugging/inspection)
      def self.patterns
        PRODUCTION_PATTERNS
      end
    end
  end
end
