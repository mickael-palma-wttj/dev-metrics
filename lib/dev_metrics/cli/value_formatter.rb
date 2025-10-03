# frozen_string_literal: true

module DevMetrics
  module CLI
    # Value Object for consistent value formatting across all formatters
    class ValueFormatter
      def self.format_metric_value(value)
        new(value).format_metric_value
      end

      def self.format_generic_value(value)
        new(value).format_generic_value
      end

      def self.format_metadata_value(value)
        new(value).format_metadata_value
      end

      def initialize(value)
        @value = value
      end

      def format_metric_value
        case @value
        when Numeric
          @value.round(2)
        when Array
          format_array_for_metric
        when Hash
          format_hash_for_metric
        else
          @value.to_s
        end
      end

      def format_generic_value
        case @value
        when Float
          format('%.2f', @value)
        when Numeric
          @value.to_s
        when Hash
          "#{@value.keys.length} items"
        when Array
          "#{@value.length} items"
        else
          @value.to_s
        end
      end

      def format_metadata_value
        case @value
        when Hash
          format_hash_for_metadata
        when Array
          format_array_for_metadata
        when Numeric
          @value.is_a?(Float) ? format('%.2f', @value) : @value.to_s
        else
          @value.to_s
        end
      end

      private

      def format_array_for_metric
        return 'No items' if @value.empty?

        "#{@value.size} items"
      end

      def format_hash_for_metric
        return 'No data' if @value.empty?

        "#{@value.keys.size} categories"
      end

      def format_hash_for_metadata
        if @value.keys.length <= 3
          @value.map { |k, v| "#{k}: #{v}" }.join(', ')
        else
          "#{@value.keys.length} items"
        end
      end

      def format_array_for_metadata
        if @value.length <= 3
          @value.join(', ')
        else
          "#{@value.length} items"
        end
      end
    end
  end
end
