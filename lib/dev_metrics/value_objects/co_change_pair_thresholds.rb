# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object containing all business thresholds and rules for co-change pair analysis
    # Eliminates magic numbers and centralizes coupling categorization logic
    class CoChangePairThresholds
      # Coupling strength thresholds for categorization
      HIGH_COUPLING_THRESHOLD = 0.5
      MEDIUM_COUPLING_THRESHOLD = 0.2
      LOW_COUPLING_THRESHOLD = 0.1

      # Hotspot identification threshold
      HOTSPOT_COUPLING_THRESHOLD = 0.3
      HOTSPOT_RELATIONSHIP_COUNT = 3

      # Precision for calculations
      COUPLING_PRECISION = 3
      PERCENTAGE_PRECISION = 1

      class << self
        # Categorizes coupling strength based on predefined thresholds
        # @param strength [Float] the coupling strength value
        # @return [String] the coupling category
        def categorize_coupling(strength)
          case strength
          when HIGH_COUPLING_THRESHOLD..1.0
            'HIGH'
          when MEDIUM_COUPLING_THRESHOLD...HIGH_COUPLING_THRESHOLD
            'MEDIUM'
          when LOW_COUPLING_THRESHOLD...MEDIUM_COUPLING_THRESHOLD
            'LOW'
          else
            'MINIMAL'
          end
        end

        # Determines if a coupling strength indicates high coupling
        # @param strength [Float] the coupling strength value
        # @return [Boolean] true if coupling is considered high
        def high_coupling?(strength)
          strength > HIGH_COUPLING_THRESHOLD
        end

        # Determines if a coupling strength indicates medium coupling
        # @param strength [Float] the coupling strength value
        # @return [Boolean] true if coupling is considered medium
        def medium_coupling?(strength)
          strength > MEDIUM_COUPLING_THRESHOLD && strength <= HIGH_COUPLING_THRESHOLD
        end

        # Determines if a coupling strength indicates low coupling
        # @param strength [Float] the coupling strength value
        # @return [Boolean] true if coupling is considered low
        def low_coupling?(strength)
          strength <= MEDIUM_COUPLING_THRESHOLD
        end

        # Determines if a file should be considered an architectural hotspot
        # @param coupling_count [Integer] number of high-coupling relationships
        # @return [Boolean] true if file is an architectural hotspot
        def architectural_hotspot?(coupling_count)
          coupling_count >= HOTSPOT_RELATIONSHIP_COUNT
        end

        # Determines if coupling strength qualifies for hotspot analysis
        # @param strength [Float] the coupling strength value
        # @return [Boolean] true if strength qualifies for hotspot consideration
        def hotspot_qualifying_coupling?(strength)
          strength > HOTSPOT_COUPLING_THRESHOLD
        end
      end
    end
  end
end
