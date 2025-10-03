module DevMetrics
  module Models
    # Standardized container for metric calculation results
    # Provides consistent structure for all metric outputs
    class MetricResult
      attr_reader :metric_name, :value, :repository, :time_period, :metadata, :error

      def initialize(metric_name:, value:, repository:, time_period:, metadata: {}, error: nil)
        @metric_name = metric_name
        @value = value
        @repository = repository
        @time_period = time_period
        @metadata = metadata || {}
        @error = error
      end

      def success?
        error.nil?
      end

      def failed?
        !success?
      end

      def to_h
        {
          metric_name: metric_name,
          value: value,
          repository: repository,
          time_period: time_period&.to_h,
          metadata: metadata,
          error: error
        }
      end

      def to_json(*args)
        require 'json'
        to_h.to_json(*args)
      end

      def ==(other)
        return false unless other.is_a?(MetricResult)

        metric_name == other.metric_name &&
          value == other.value &&
          repository == other.repository &&
          time_period == other.time_period
      end

      def to_s
        if success?
          "#{metric_name}: #{format_value} (#{repository})"
        else
          "#{metric_name}: ERROR - #{error} (#{repository})"
        end
      end

      private

      def format_value
        case value
        when Numeric
          value.round(2)
        when Array
          "#{value.size} items"
        when Hash
          "#{value.keys.size} entries"
        else
          value.to_s
        end
      end
    end
  end
end
