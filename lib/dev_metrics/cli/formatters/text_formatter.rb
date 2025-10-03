module DevMetrics
  module CLI
    module Formatters
      class TextFormatter < Base
        def format_results(results, metadata)
          template_name = 'basic_report.text'
          render_template_or_fallback(template_name, { results: results, metadata: metadata }) do
            format_text_fallback(results, metadata)
          end
        end

        def format_analysis_results(results, summary)
          processed_summary = Services::ContributorFilterProcessor.process(summary)
          template_name = 'analysis_report.text'

          render_template_or_fallback(template_name, { results: results, summary: processed_summary }) do
            format_analysis_text_fallback(results, processed_summary)
          end
        end

        private

        def format_text_fallback(results, metadata)
          output = build_header
          output.concat(build_metadata_section(metadata))
          output.concat(build_results_by_category(results))
          output.join("\n")
        end

        def format_analysis_text_fallback(results, summary)
          output = build_analysis_header
          output.concat(build_summary_section(summary))
          output.concat(build_analysis_results_by_category(results))
          output.join("\n")
        end

        def build_header
          [
            'Developer Metrics Report',
            '=' * 50,
            ''
          ]
        end

        def build_analysis_header
          [
            'Git Metrics Analysis Report',
            '=' * 50,
            ''
          ]
        end

        def build_metadata_section(metadata)
          output = []
          output << "Repository: #{metadata[:repository]}" if metadata[:repository]
          output << "Time Period: #{metadata[:time_period]}" if metadata[:time_period]
          output << "Generated: #{metadata[:generated_at]}" if metadata[:generated_at]
          output << ''
          output
        end

        def build_summary_section(summary)
          output = []

          if summary[:repository_info]
            repo_info = summary[:repository_info]
            output << "Repository: #{repo_info[:name]}"
            output << "Path: #{repo_info[:path]}"
            output << "Analyzed: #{repo_info[:analyzed_at]}"
            output << ''
          end

          if summary[:contributor_filter_display]
            output << summary[:contributor_filter_display]
            output << ''
          end

          output << "Total Metrics: #{summary[:total_metrics] || 0}"
          output << "Execution Time: #{DevMetrics::Utils::StringUtils.format_execution_time(summary[:execution_time])}"
          output << "Data Coverage: #{summary[:data_coverage] || 0}%"
          output << ''
          output
        end

        def build_results_by_category(results)
          output = []
          grouped_results = Services::ResultGrouper.new(results).group_by_category

          grouped_results.each do |category, category_results|
            output << category.upcase.gsub('_', ' ')
            output << '-' * 30

            category_results.each do |result|
              output << format_result_line(result)
            end

            output << ''
          end

          output
        end

        def build_analysis_results_by_category(results)
          output = []
          categories = group_analysis_results(results)

          categories.each do |category, metrics|
            output << category.to_s.upcase.gsub('_', ' ')
            output << '-' * 40

            metrics.each do |metric_name, data|
              output.concat(format_analysis_metric(metric_name, data))
            end

            output << ''
          end

          output
        end

        def format_result_line(result)
          if result.success?
            "  #{result.metric_name}: #{ValueFormatter.format_generic_value(result.value)}"
          else
            "  #{result.metric_name}: ERROR - #{result.error}"
          end
        end

        def format_analysis_metric(metric_name, data)
          metric_result = data[:metric]
          data_points_count = metric_result.metadata[:data_points] || 0
          data_points_label = metric_result.metadata[:data_points_label] || 'records'

          [
            "  #{metric_name}:",
            '    Status: ✅ Success',
            "    Data Points: #{data_points_count} #{data_points_label}",
            "    Value: #{ValueFormatter.format_metric_value(metric_result.value)}",
            ''
          ]
        end

        def group_analysis_results(results)
          results.group_by { |_, data| data[:metadata][:category] }
        end

        def format_metric_value(value)
          ValueFormatter.format_metric_value(value)
        end
      end
    end
  end
end
