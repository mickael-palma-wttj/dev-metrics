# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object responsible for generating batch analysis reports
    # Follows Single Responsibility Principle - only handles report generation
    class ReportGeneratorService
      SUMMARY_SEPARATOR = ('=' * 50).freeze

      def initialize(options = {})
        @options = options
      end

      def generate_batch_report(results)
        return if results.empty?

        display_batch_summary(results)
        generate_individual_reports(results.select(&:successful?))
        display_failed_analyses(results.select(&:failed?))
      end

      private

      attr_reader :options

      def display_batch_summary(results)
        successful_count = results.count(&:successful?)
        failed_count = results.count(&:failed?)

        puts "\n#{SUMMARY_SEPARATOR}"
        puts 'BATCH ANALYSIS SUMMARY'
        puts SUMMARY_SEPARATOR
        puts "Total repositories analyzed: #{results.size}"
        puts "✅ Successful: #{successful_count}"
        puts "❌ Failed: #{failed_count}" if failed_count.positive?
        puts "Success rate: #{(successful_count.to_f / results.size * 100).round(1)}%"
        puts SUMMARY_SEPARATOR
      end

      def generate_individual_reports(successful_results)
        return if successful_results.empty?

        puts "\n📊 GENERATING INDIVIDUAL REPORTS"
        puts '-' * 40

        successful_results.each do |result|
          generate_single_report(result)
        end
      end

      def generate_single_report(result)
        repository = result.repository
        analyzer = result.analyzer
        analysis_results = result.results

        puts "Generating report for: #{repository.name}"

        formatter = DevMetrics::CLI::OutputFormatter.new(options[:format])
        output = formatter.format_analysis_results(analysis_results, analyzer.summary)

        output_path = build_output_path(repository.name)
        DevMetrics::Services::OutputWriter.new(output_path).write(output)

        puts "  ✅ Report saved: #{output_path}"
      end

      def display_failed_analyses(failed_results)
        return if failed_results.empty?

        puts "\n❌ FAILED ANALYSES"
        puts '-' * 40

        failed_results.each do |result|
          puts "Repository: #{result.repository.name}"
          puts "Error: #{result.error.message}"
          puts '-' * 20
        end
      end

      def build_output_path(repository_name)
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        filename = "#{repository_name}_metrics_#{timestamp}.#{file_extension}"

        if options[:output]
          File.join(options[:output], repository_name, filename)
        else
          File.join('./report', repository_name, filename)
        end
      end

      def file_extension
        case options[:format]&.to_s
        when 'json' then 'json'
        when 'csv' then 'csv'
        else 'txt'
        end
      end
    end
  end
end
