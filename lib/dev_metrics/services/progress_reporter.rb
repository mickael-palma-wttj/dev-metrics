# frozen_string_literal: true

module DevMetrics
  module Services
    # Base class for progress reporting strategies
    class ProgressReporter
      def initialize(silent: false)
        @silent = silent
      end

      def start(total_metrics)
        return if @silent

        puts "Analyzing #{total_metrics} Git metrics..."
      end

      def update(metric_name, index, total)
        return if @silent

        progress = ((index + 1).to_f / total * 100).round(1)
        puts "  [#{progress}%] Analyzing #{metric_name}..."
      end

      def error(metric_name, message)
        return if @silent

        puts "  ⚠️  Failed to analyze #{metric_name}: #{message}"
      end

      def complete(successful_count)
        return if @silent

        puts "Analysis complete! Processed #{successful_count} metrics"
      end

      def report_errors(errors)
        return if @silent || errors.empty?

        puts "\n⚠️  Some metrics failed to analyze:"
        errors.each do |metric_name, error_info|
          puts "  - #{metric_name}: #{error_info[:message]}"
        end
        puts ''
      end
    end

    # Silent reporter that outputs nothing
    class SilentProgressReporter < ProgressReporter
      def initialize
        super(silent: true)
      end
    end

    # Detailed reporter with additional debugging information
    class DetailedProgressReporter < ProgressReporter
      def update(metric_name, index, total)
        return if @silent

        progress = ((index + 1).to_f / total * 100).round(1)
        timestamp = Time.now.strftime('%H:%M:%S')
        puts "  [#{progress}%] #{timestamp} - Analyzing #{metric_name}..."
      end
    end
  end
end
