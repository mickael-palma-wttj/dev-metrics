# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing ownership statistics for a file
    # Replaces raw hash data structures with proper typed objects
    class FileOwnershipStats
      attr_reader :filename, :primary_owner, :primary_owner_percentage, :last_modified_by,
                  :last_modified_date, :total_commits, :total_changes, :contributor_count,
                  :ownership_distribution, :ownership_concentration, :ownership_type

      def initialize(attributes)
        assign_basic_attributes(attributes)
        assign_ownership_attributes(attributes)
        freeze
      end

      # Determines if this file has high ownership concentration
      # @return [Boolean] true if concentration is high
      def high_concentration?
        FileOwnershipThresholds.high_concentration?(ownership_concentration)
      end

      # Determines if this file has moderate ownership concentration
      # @return [Boolean] true if concentration is moderate
      def moderate_concentration?
        FileOwnershipThresholds.moderate_concentration?(ownership_concentration)
      end

      # Determines if this file has distributed ownership
      # @return [Boolean] true if ownership is distributed
      def distributed_ownership?
        FileOwnershipThresholds.distributed_ownership?(ownership_concentration)
      end

      # Determines if this file has a single owner
      # @return [Boolean] true if file has only one contributor
      def single_owner?
        contributor_count == 1
      end

      # Gets the concentration category for this file
      # @return [String] the concentration category (HIGH, MODERATE, DISTRIBUTED)
      def concentration_category
        FileOwnershipThresholds.categorize_concentration(ownership_concentration)
      end

      # Converts to hash for backward compatibility
      # @return [Hash] hash representation of the file ownership stats
      def to_h
        basic_hash.merge(ownership_hash)
      end

      private

      # Assigns basic file attributes
      def assign_basic_attributes(attributes)
        @filename = attributes[:filename]
        @primary_owner = attributes[:primary_owner]
        @primary_owner_percentage = attributes[:primary_owner_percentage]
        @last_modified_by = attributes[:last_modified_by]
        @last_modified_date = attributes[:last_modified_date]
        @total_commits = attributes[:total_commits]
        @total_changes = attributes[:total_changes]
        @contributor_count = attributes[:contributor_count]
      end

      # Assigns ownership-specific attributes
      def assign_ownership_attributes(attributes)
        @ownership_distribution = attributes[:ownership_distribution]
        @ownership_concentration = attributes[:ownership_concentration]
        @ownership_type = attributes[:ownership_type]
      end

      # Basic statistics hash
      def basic_hash
        {
          primary_owner: primary_owner,
          primary_owner_percentage: primary_owner_percentage,
          last_modified_by: last_modified_by,
          last_modified_date: last_modified_date,
          total_commits: total_commits,
          total_changes: total_changes,
          contributor_count: contributor_count,
        }
      end

      # Ownership-specific statistics hash
      def ownership_hash
        {
          ownership_distribution: ownership_distribution,
          ownership_concentration: ownership_concentration,
          ownership_type: ownership_type,
        }
      end
    end
  end
end
