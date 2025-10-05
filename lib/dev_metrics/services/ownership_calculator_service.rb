# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for calculating ownership metrics and concentrations
    # Handles percentage calculations and Herfindahl-Hirschman Index computation
    class OwnershipCalculatorService
      def initialize
        @thresholds = ValueObjects::FileOwnershipThresholds
      end

      # Calculates ownership concentration using Herfindahl-Hirschman Index
      # @param author_percentages [Hash] hash of author to percentage mapping
      # @return [Float] ownership concentration value (0-100)
      def calculate_ownership_concentration(author_percentages)
        return 100.0 if author_percentages.size <= 1

        hhi = calculate_hhi(author_percentages)
        (hhi * 100).round(@thresholds::CONCENTRATION_PRECISION)
      end

      # Calculates ownership percentages for all authors
      # @param authors_changes [Hash] hash of author to changes count
      # @param total_changes [Integer] total changes for the file
      # @return [Hash] hash of author to percentage mapping, sorted by percentage
      def calculate_ownership_percentages(authors_changes, total_changes)
        return {} if total_changes.zero?

        percentages = authors_changes.transform_values do |changes|
          calculate_percentage(changes, total_changes)
        end

        percentages.sort_by { |_, pct| -pct }.to_h
      end

      # Determines the primary owner from author changes
      # @param authors_changes [Hash] hash of author to changes count
      # @return [Array] array containing [author, changes] for primary owner
      def find_primary_owner(authors_changes)
        return ['', 0] if authors_changes.empty?

        authors_changes.max_by { |_, changes| changes }
      end

      # Calculates primary owner percentage
      # @param primary_owner_changes [Integer] changes made by primary owner
      # @param total_changes [Integer] total changes for the file
      # @return [Float] primary owner percentage
      def calculate_primary_owner_percentage(primary_owner_changes, total_changes)
        return 0.0 if total_changes.zero?

        calculate_percentage(primary_owner_changes, total_changes)
      end

      # Categorizes ownership type based on percentages and contributor count
      # @param author_percentages [Hash] hash of author to percentage mapping
      # @return [String] ownership type category
      def categorize_ownership_type(author_percentages)
        max_ownership = author_percentages.values.max || 0
        contributor_count = author_percentages.size

        @thresholds.categorize_ownership_type(max_ownership, contributor_count)
      end

      private

      attr_reader :thresholds

      # Calculates Herfindahl-Hirschman Index from percentages
      def calculate_hhi(author_percentages)
        author_percentages.values.map { |pct| (pct / 100.0)**2 }.sum
      end

      # Calculates percentage with proper precision
      def calculate_percentage(part, total)
        (part.to_f / total * 100).round(thresholds::PERCENTAGE_PRECISION)
      end
    end
  end
end
