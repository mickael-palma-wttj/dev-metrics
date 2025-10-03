# frozen_string_literal: true

require 'time'

module DevMetrics
  module Analyzers
    # Orchestrates Git metrics collection and analysis
    class GitAnalyzer
      attr_reader :repository, :options, :results

      def initialize(repository, options = {})
        @repository = repository
        @options = options
        @results = {}
      end

      def analyze(metric_names = 'all', categories = nil)
        metrics_to_run = Metrics::GitMetricsRegistry.filter_metrics(metric_names, categories)

        raise ArgumentError, 'No valid metrics specified for analysis' if metrics_to_run.empty?

        puts "Analyzing #{metrics_to_run.size} Git metrics..." unless options[:no_progress]

        @results = {}
        errors = {}

        metrics_to_run.each_with_index do |metric_name, index|
          next unless should_run_metric?(metric_name)

          begin
            progress_update(metric_name, index, metrics_to_run.size) unless options[:no_progress]

            metric = create_metric(metric_name)
            result = metric.calculate

            @results[metric_name] = {
              metric: result,
              metadata: {
                category: find_metric_category(metric_name),
                execution_time: result.metadata[:execution_time],
                data_points: result.metadata[:data_points] || 0,
              },
            }
          rescue StandardError => e
            errors[metric_name] = {
              error: e.class.name,
              message: e.message,
            }
            puts "  ⚠️  Failed to analyze #{metric_name}: #{e.message}" unless options[:no_progress]
          end
        end

        handle_analysis_errors(errors) unless errors.empty?

        puts "Analysis complete! Processed #{@results.size} metrics" unless options[:no_progress]
        @results
      end

      def summary
        return {} if @results.empty?

        categories = @results.group_by { |_, data| data[:metadata][:category] }

        {
          total_metrics: @results.size,
          categories: categories.transform_values(&:size),
          execution_time: total_execution_time,
          data_coverage: calculate_data_coverage,
          repository_info: {
            name: repository.name,
            path: repository.path,
            analyzed_at: Time.now.iso8601,
          },
        }
      end

      def results_for_category(category)
        @results.select { |_, data| data[:metadata][:category] == category }
      end

      def metric_result(metric_name)
        @results[metric_name.to_sym]
      end

      private

      def should_run_metric?(metric_name)
        # Skip metrics based on options
        return false if options[:exclude_metrics]&.include?(metric_name.to_s)

        # Skip if contributors filter doesn't match
        return contributor_data?(metric_name) if options[:contributors] && !options[:contributors].empty?

        true
      end

      def create_metric(metric_name)
        metric = Metrics::GitMetricsRegistry.create_metric(metric_name, repository, metric_options)

        raise ArgumentError, "Unknown metric: #{metric_name}" unless metric

        metric
      end

      def metric_options
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

        if time_option.is_a?(String) && time_option.match?(/^\d+[dwmy]$/)
          # Relative time format (30d, 2w, 1m, 1y)
          number = time_option.to_i
          unit = time_option[-1]

          case unit
          when 'd' then Time.now - (number * 24 * 60 * 60)
          when 'w' then Time.now - (number * 7 * 24 * 60 * 60)
          when 'm' then Time.now - (number * 30 * 24 * 60 * 60)
          when 'y' then Time.now - (number * 365 * 24 * 60 * 60)
          end
        else
          Time.parse(time_option.to_s)
        end
      rescue ArgumentError
        raise ArgumentError, "Invalid time format: #{time_option}"
      end

      def find_metric_category(metric_name)
        Metrics::GitMetricsRegistry.all_categories.find do |category|
          Metrics::GitMetricsRegistry.metrics_for_category(category).include?(metric_name)
        end
      end

      def contributor_data?(_metric_name)
        # Simple heuristic: most Git metrics work with contributor filtering
        # In a more sophisticated implementation, we'd check metric capabilities
        true
      end

      def progress_update(metric_name, index, total)
        progress = ((index + 1).to_f / total * 100).round(1)
        puts "  [#{progress}%] Analyzing #{metric_name}..."
      end

      def handle_analysis_errors(errors)
        puts "\n⚠️  Some metrics failed to analyze:"
        errors.each do |metric_name, error_info|
          puts "  - #{metric_name}: #{error_info[:message]}"
        end
        puts ''
      end

      def total_execution_time
        return 0 if @results.empty?

        @results.values.sum { |data| data[:metadata][:execution_time] || 0 }
      end

      def calculate_data_coverage
        return 0 if @results.empty?

        metrics_with_data = @results.count { |_, data| (data[:metadata][:data_points] || 0).positive? }
        (metrics_with_data.to_f / @results.size * 100).round(1)
      end
    end
  end
end
