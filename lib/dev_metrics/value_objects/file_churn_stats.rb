# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing statistics for a file's churn metrics
    # Replaces raw hash data structures with proper typed objects
    class FileChurnStats
      attr_reader :filename, :total_churn, :additions, :deletions, :net_changes,
                  :commits, :authors_count, :authors, :avg_churn_per_commit, :churn_ratio

      def initialize(attributes)
        assign_basic_attributes(attributes)
        assign_calculated_attributes(attributes)
        freeze
      end

      # Determines if this file has high churn
      # @return [Boolean] true if churn level is high
      def high_churn?
        FileChurnThresholds.high_churn?(total_churn)
      end

      private

      # Assigns basic file attributes
      def assign_basic_attributes(attributes)
        @filename = attributes[:filename]
        @total_churn = attributes[:total_churn]
        @additions = attributes[:additions]
        @deletions = attributes[:deletions]
        @net_changes = attributes[:net_changes]
        @commits = attributes[:commits]
      end

      # Assigns calculated attributes
      def assign_calculated_attributes(attributes)
        @authors_count = attributes[:authors_count]
        @authors = attributes[:authors]
        @avg_churn_per_commit = attributes[:avg_churn_per_commit]
        @churn_ratio = attributes[:churn_ratio]
      end

      public

      # Determines if this file has medium churn
      # @return [Boolean] true if churn level is medium
      def medium_churn?
        FileChurnThresholds.medium_churn?(total_churn)
      end

      # Determines if this file has low churn
      # @return [Boolean] true if churn level is low
      def low_churn?
        FileChurnThresholds.low_churn?(total_churn)
      end

      # Gets the churn category for this file
      # @return [String] the churn category (HIGH, MEDIUM, LOW)
      def churn_category
        FileChurnThresholds.categorize_churn(total_churn)
      end

      # Converts to hash for backward compatibility
      # @return [Hash] hash representation of the file churn stats
      def to_h
        basic_hash.merge(calculated_hash)
      end

      private

      # Basic statistics hash
      def basic_hash
        {
          total_churn: total_churn,
          additions: additions,
          deletions: deletions,
          net_changes: net_changes,
          commits: commits,
        }
      end

      # Calculated statistics hash
      def calculated_hash
        {
          authors_count: authors_count,
          authors: authors,
          avg_churn_per_commit: avg_churn_per_commit,
          churn_ratio: churn_ratio,
        }
      end

      # Determines if this file is a hotspot (high churn)
      # @return [Boolean] true if file is considered a hotspot
      def hotspot?
        high_churn?
      end
    end
  end
end
