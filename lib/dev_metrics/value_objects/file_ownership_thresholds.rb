# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object containing all business thresholds and rules for file ownership analysis
    # Eliminates magic numbers and centralizes ownership categorization logic
    class FileOwnershipThresholds
      # Ownership concentration thresholds for categorization
      HIGH_CONCENTRATION_THRESHOLD = 80
      MODERATE_CONCENTRATION_THRESHOLD = 50

      # Ownership type thresholds for categorization
      DOMINANT_OWNER_THRESHOLD = 80
      PRIMARY_OWNER_THRESHOLD = 60
      SHARED_OWNERSHIP_THRESHOLD = 40

      # Precision for calculations
      PERCENTAGE_PRECISION = 1
      CONCENTRATION_PRECISION = 1

      class << self
        # Categorizes ownership type based on max ownership percentage and contributor count
        # @param max_ownership [Float] the maximum ownership percentage
        # @param contributor_count [Integer] the number of contributors
        # @return [String] the ownership type category
        def categorize_ownership_type(max_ownership, contributor_count)
          return 'SINGLE_OWNER' if contributor_count == 1

          categorize_by_ownership_percentage(max_ownership)
        end

        # Determines if ownership is highly concentrated
        # @param concentration [Float] the ownership concentration value
        # @return [Boolean] true if concentration is high
        def high_concentration?(concentration)
          concentration > HIGH_CONCENTRATION_THRESHOLD
        end

        # Determines if ownership is moderately concentrated
        # @param concentration [Float] the ownership concentration value
        # @return [Boolean] true if concentration is moderate
        def moderate_concentration?(concentration)
          concentration > MODERATE_CONCENTRATION_THRESHOLD &&
            concentration <= HIGH_CONCENTRATION_THRESHOLD
        end

        # Determines if ownership is distributed
        # @param concentration [Float] the ownership concentration value
        # @return [Boolean] true if ownership is distributed
        def distributed_ownership?(concentration)
          concentration <= MODERATE_CONCENTRATION_THRESHOLD
        end

        # Categorizes concentration level
        # @param concentration [Float] the ownership concentration value
        # @return [String] the concentration category
        def categorize_concentration(concentration)
          if high_concentration?(concentration)
            'HIGH'
          elsif moderate_concentration?(concentration)
            'MODERATE'
          else
            'DISTRIBUTED'
          end
        end

        private

        # Categorizes ownership based on percentage thresholds
        def categorize_by_ownership_percentage(max_ownership)
          case max_ownership
          when DOMINANT_OWNER_THRESHOLD..Float::INFINITY
            'DOMINANT_OWNER'
          when PRIMARY_OWNER_THRESHOLD...DOMINANT_OWNER_THRESHOLD
            'PRIMARY_OWNER'
          when SHARED_OWNERSHIP_THRESHOLD...PRIMARY_OWNER_THRESHOLD
            'SHARED_OWNERSHIP'
          else
            'DISTRIBUTED_OWNERSHIP'
          end
        end
      end
    end
  end
end
