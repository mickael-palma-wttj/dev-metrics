# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object responsible for executing individual metrics
    class MetricExecutor
      attr_reader :repository, :options, :progress_reporter

      def initialize(repository, options, progress_reporter)
        @repository = repository
        @options = options
        @progress_reporter = progress_reporter
      end

      def execute_metrics(metrics_to_run)
        results = {}
        errors = {}

        metrics_to_run.each_with_index do |metric_name, index|
          next unless should_run_metric?(metric_name)

          process_metric(metric_name, index, metrics_to_run.size, results, errors)
        end

        [results, errors]
      end

      private

      def should_run_metric?(metric_name)
        return false if excluded_metric?(metric_name)
        return contributor_metric_allowed?(metric_name) if contributor_filter_active?

        true
      end

      def excluded_metric?(metric_name)
        options[:exclude_metrics]&.include?(metric_name.to_s)
      end

      def contributor_filter_active?
        options[:contributors] && !options[:contributors].empty?
      end

      def contributor_metric_allowed?(_metric_name)
        # Simple heuristic: most Git metrics work with contributor filtering
        # In a more sophisticated implementation, we'd check metric capabilities
        true
      end

      def process_metric(metric_name, index, total_size, results, errors)
        progress_reporter.update(metric_name, index, total_size)
        result = execute_single_metric(metric_name)
        results[metric_name] = format_result(result, metric_name)
      rescue StandardError => e
        errors[metric_name] = format_error(e)
        progress_reporter.error(metric_name, e.message)
      end

      def execute_single_metric(metric_name)
        metric = create_metric(metric_name)
        metric.calculate
      end

      def create_metric(metric_name)
        metric = Metrics::GitMetricsRegistry.create_metric(
          metric_name,
          repository,
          build_metric_options
        )

        raise ArgumentError, "Unknown metric: #{metric_name}" unless metric

        metric
      end

      def build_metric_options
        {
          time_period: build_time_period,
          contributors: options[:contributors] || [],
          exclude_bots: options[:exclude_bots] || false,
          include_merge_commits: options[:include_merge_commits] || true,
        }
      end

      def build_time_period
        if options[:since] || options[:until]
          start_date = parse_time_option(options[:since]) || 30
          end_date = parse_time_option(options[:until]) || Time.now
          Models::TimePeriod.new(start_date, end_date)
        else
          Models::TimePeriod.default
        end
      end

      def parse_time_option(time_option)
        return nil unless time_option

        TimeParser.new(time_option).parse
      end

      def format_result(result, metric_name)
        {
          metric: result,
          metadata: {
            category: find_metric_category(metric_name),
            execution_time: result.metadata[:execution_time],
            data_points: result.metadata[:data_points] || 0,
          },
        }
      end

      def format_error(error)
        {
          error: error.class.name,
          message: error.message,
        }
      end

      def find_metric_category(metric_name)
        Metrics::GitMetricsRegistry.all_categories.find do |category|
          Metrics::GitMetricsRegistry.metrics_for_category(category).include?(metric_name)
        end
      end
    end
  end
end
