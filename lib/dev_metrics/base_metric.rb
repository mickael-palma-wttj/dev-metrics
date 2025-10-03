module DevMetrics
  # Base class for all metric calculations
  # Implements Template Method pattern for consistent metric computation workflow
  class BaseMetric
    include Utils::TimeHelper

    attr_reader :repository, :time_period, :options

    def initialize(repository, time_period = nil, options = {})
      @repository = repository
      @time_period = time_period || Models::TimePeriod.default
      @options = options
    end

    # Template method - defines the algorithm structure
    def calculate
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      validate_inputs
      raw_data = collect_data
      processed_data = process_data(raw_data)
      result = compute_metric(processed_data)

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      execution_time = (end_time - start_time).round(3)

      Models::MetricResult.new(
        metric_name: metric_name,
        value: result,
        repository: repository.name,
        time_period: time_period,
        metadata: build_metadata(processed_data).merge(execution_time: execution_time)
      )
    rescue StandardError => e
      handle_error(e)
    end

    # Abstract methods to be implemented by subclasses
    def metric_name
      raise NotImplementedError, 'Subclasses must implement #metric_name'
    end

    def description
      raise NotImplementedError, 'Subclasses must implement #description'
    end

    protected

    # Abstract methods for the template method pattern
    def collect_data
      raise NotImplementedError, 'Subclasses must implement #collect_data'
    end

    def process_data(raw_data)
      # Default implementation - can be overridden
      raw_data
    end

    def compute_metric(processed_data)
      raise NotImplementedError, 'Subclasses must implement #compute_metric'
    end

    def build_metadata(processed_data)
      data_points = processed_data.respond_to?(:size) ? processed_data.size : 0
      {
        total_records: data_points,
        data_points: data_points,
        data_points_label: data_points_description,
        computed_at: Time.now,
        options_used: options
      }
    end

    # Override in subclasses to provide meaningful data points description
    def data_points_description
      'records'
    end

    private

    def validate_inputs
      raise ArgumentError, 'Repository cannot be nil' if repository.nil?
      raise ArgumentError, 'Time period cannot be nil' if time_period.nil?
    end

    def handle_error(error)
      Models::MetricResult.new(
        metric_name: metric_name,
        value: nil,
        repository: repository&.name || 'unknown',
        time_period: time_period,
        error: error.message,
        metadata: { error_class: error.class.name }
      )
    end
  end
end
