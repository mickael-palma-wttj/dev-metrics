# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object containing all business thresholds and rules for file churn analysis
    # Eliminates magic numbers and centralizes churn categorization logic
    class FileChurnThresholds
      # Churn level thresholds for categorization
      HIGH_CHURN_THRESHOLD = 1000
      MEDIUM_CHURN_THRESHOLD = 100

      # Precision for calculations
      CHURN_PRECISION = 2
      PERCENTAGE_PRECISION = 1

      class << self
        # Categorizes churn level based on predefined thresholds
        # @param total_churn [Integer] the total churn value
        # @return [String] the churn category
        def categorize_churn(total_churn)
          case total_churn
          when HIGH_CHURN_THRESHOLD..Float::INFINITY
            'HIGH'
          when MEDIUM_CHURN_THRESHOLD...HIGH_CHURN_THRESHOLD
            'MEDIUM'
          else
            'LOW'
          end
        end

        # Determines if a file has high churn
        # @param total_churn [Integer] the total churn value
        # @return [Boolean] true if churn is considered high
        def high_churn?(total_churn)
          total_churn > HIGH_CHURN_THRESHOLD
        end

        # Determines if a file has medium churn
        # @param total_churn [Integer] the total churn value
        # @return [Boolean] true if churn is considered medium
        def medium_churn?(total_churn)
          total_churn > MEDIUM_CHURN_THRESHOLD && total_churn <= HIGH_CHURN_THRESHOLD
        end

        # Determines if a file has low churn
        # @param total_churn [Integer] the total churn value
        # @return [Boolean] true if churn is considered low
        def low_churn?(total_churn)
          total_churn <= MEDIUM_CHURN_THRESHOLD
        end
      end
    end
  end
end
