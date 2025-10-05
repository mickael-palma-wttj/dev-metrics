# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object defining thresholds for authors per file analysis
    class AuthorsPerFileThresholds
      SINGLE_AUTHOR = 1
      SHARED_OWNERSHIP_MAX = 3
      COLLABORATIVE_MAX = 10

      # Bus factor risk thresholds
      HIGH_RISK_MAX = 1
      MEDIUM_RISK_MAX = 3

      # Collaboration score weights
      COLLABORATION_WEIGHTS = {
        single_owner_penalty: -10,
        shared_points: 50,
        collaborative_points: 100,
        max_score: 100,
      }.freeze

      def self.bus_factor_risk_category(author_count)
        case author_count
        when HIGH_RISK_MAX
          'HIGH'
        when (HIGH_RISK_MAX + 1)..MEDIUM_RISK_MAX
          'MEDIUM'
        else
          'LOW'
        end
      end

      def self.ownership_type(author_count)
        case author_count
        when SINGLE_AUTHOR
          'SINGLE_OWNER'
        when 2..SHARED_OWNERSHIP_MAX
          'SHARED'
        when (SHARED_OWNERSHIP_MAX + 1)..COLLABORATIVE_MAX
          'COLLABORATIVE'
        else
          'HIGHLY_COLLABORATIVE'
        end
      end

      def self.single_author?(author_count)
        author_count == SINGLE_AUTHOR
      end

      def self.shared?(author_count)
        author_count > SINGLE_AUTHOR && author_count <= SHARED_OWNERSHIP_MAX
      end

      def self.highly_shared?(author_count)
        author_count > SHARED_OWNERSHIP_MAX
      end
    end
  end
end
