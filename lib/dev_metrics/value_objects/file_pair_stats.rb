# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing statistics for a file pair's co-change relationship
    # Replaces raw hash data structures with proper typed objects
    class FilePairStats
      attr_reader :file1, :file2, :co_changes, :file1_total_changes, :file2_total_changes,
                  :coupling_strength, :coupling_percentage, :coupling_category

      def initialize(attributes)
        @file1 = attributes[:file1]
        @file2 = attributes[:file2]
        @co_changes = attributes[:co_changes]
        @file1_total_changes = attributes[:file1_total_changes]
        @file2_total_changes = attributes[:file2_total_changes]
        @coupling_strength = attributes[:coupling_strength]
        @coupling_percentage = attributes[:coupling_percentage]
        @coupling_category = attributes[:coupling_category]

        freeze
      end

      # Creates a unique key for this file pair
      # @return [String] sorted pair key for consistent identification
      def pair_key
        [file1, file2].sort.join(' <-> ')
      end

      # Determines if this pair has high coupling
      # @return [Boolean] true if coupling strength is high
      def high_coupling?
        CoChangePairThresholds.high_coupling?(coupling_strength)
      end

      # Determines if this pair has medium coupling
      # @return [Boolean] true if coupling strength is medium
      def medium_coupling?
        CoChangePairThresholds.medium_coupling?(coupling_strength)
      end

      # Determines if this pair has low coupling
      # @return [Boolean] true if coupling strength is low
      def low_coupling?
        CoChangePairThresholds.low_coupling?(coupling_strength)
      end

      # Converts to hash for backward compatibility
      # @return [Hash] hash representation of the file pair stats
      def to_h
        {
          file1: file1,
          file2: file2,
          co_changes: co_changes,
          file1_total_changes: file1_total_changes,
          file2_total_changes: file2_total_changes,
          coupling_strength: coupling_strength,
          coupling_percentage: coupling_percentage,
          coupling_category: coupling_category,
        }
      end

      # Files involved in this pairing
      # @return [Array<String>] array of both file names
      def files
        [file1, file2]
      end
    end
  end
end
