# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for calculating statistical measures of commit sizes
    # Follows Single Responsibility Principle - only handles statistical calculations
    class CommitSizeStatisticsCalculator
      def initialize(sizes)
        @sizes = sizes
      end

      def average
        return 0.0 if sizes.empty?

        (sizes.sum.to_f / sizes.size).round(2)
      end

      def median
        return 0.0 if sizes.empty?

        sorted_sizes = sizes.sort
        calculate_median_from_sorted(sorted_sizes)
      end

      def min
        sizes.min || 0
      end

      def max
        sizes.max || 0
      end

      private

      attr_reader :sizes

      def calculate_median_from_sorted(sorted_sizes)
        mid = sorted_sizes.length / 2

        if sorted_sizes.length.odd?
          sorted_sizes[mid]
        else
          ((sorted_sizes[mid - 1] + sorted_sizes[mid]) / 2.0).round(2)
        end
      end
    end
  end
end
