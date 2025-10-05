# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      # Refactored HtmlFormatter following Sandi Metz rules and SOLID principles
      # Uses composition with specialized builder classes
      class HtmlFormatter < Base
        def format_analysis_results(results, summary)
          template_name = 'analysis_report.html'
          render_template_or_fallback(template_name, { results: results, summary: summary }) do
            format_html_fallback(results, summary)
          end
        end

        # Template helper methods - delegated to specialized classes
        def render_metric_details(metric_name, value)
          HTML::RendererRegistry.render_metric_details(metric_name, value)
        end

        def render_metadata_details(metadata)
          HTML::MetadataBuilder.build_metadata_details(metadata)
        end

        def group_results_by_category(results)
          HTML::TemplateHelpers.group_results_by_category(results)
        end

        def format_value(value)
          HTML::TemplateHelpers.format_value(value)
        end

        def format_execution_time(time_seconds)
          HTML::TemplateHelpers.format_execution_time(time_seconds)
        end

        def humanize_string(str)
          HTML::TemplateHelpers.humanize_string(str)
        end

        def truncate_text(text, length)
          HTML::TemplateHelpers.truncate_text(text, length)
        end

        def group_analysis_results(results)
          HTML::TemplateHelpers.group_analysis_results(results)
        end

        def format_metric_value(value)
          HTML::TemplateHelpers.format_metric_value(value)
        end

        private

        def format_html_fallback(results, summary)
          body_content = build_html_body(results, summary)
          HTML::DocumentBuilder.build_document(body_content)
        end

        def build_html_body(results, summary)
          html = []
          html.concat(HTML::MetadataBuilder.build_metadata_section(summary))
          html.concat(HTML::ResultsBuilder.build_results_sections(results))
          html
        end
      end
    end
  end
end
