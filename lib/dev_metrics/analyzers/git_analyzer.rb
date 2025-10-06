# frozen_string_literal: true

module DevMetrics
  module Analyzers
    # Orchestrates Git metrics collection and analysis
    class GitAnalyzer
      attr_reader :repository, :analysis_options, :results, :time_period

      def initialize(repository, options = {}, time_period = nil)
        @repository = repository
        @analysis_options = ValueObjects::AnalysisOptions.new(options)
        @time_period = time_period
        @results = {}
      end

      def analyze(metric_names = 'all', categories = nil)
        metrics_to_run = filter_metrics(metric_names, categories)
        progress_reporter = create_progress_reporter

        progress_reporter.start(metrics_to_run.size)

        @results, errors = execute_metrics(metrics_to_run, progress_reporter)

        progress_reporter.report_errors(errors)
        progress_reporter.complete(@results.size)

        @results
      end

      def summary
        Services::AnalysisSummaryBuilder.new(@results, repository, @time_period).build
      end

      def results_for_category(category)
        @results.select { |_, data| data[:metadata][:category] == category }
      end

      def metric_result(metric_name)
        @results[metric_name.to_sym]
      end

      private

      def filter_metrics(metric_names, categories)
        metrics_to_run = Metrics::GitMetricsRegistry.filter_metrics(metric_names, categories)
        raise ArgumentError, 'No valid metrics specified for analysis' if metrics_to_run.empty?

        metrics_to_run
      end

      def create_progress_reporter
        return Services::SilentProgressReporter.new unless analysis_options.progress_reporting_enabled?

        Services::ProgressReporter.new
      end

      def execute_metrics(metrics_to_run, progress_reporter)
        executor = Services::MetricExecutor.new(
          repository,
          analysis_options.to_h,
          progress_reporter,
          time_period
        )

        executor.execute_metrics(metrics_to_run)
      end
    end
  end
end
