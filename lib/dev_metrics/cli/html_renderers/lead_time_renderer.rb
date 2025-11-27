# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Lead Time metric showing deployment lead time analysis
      class LeadTimeRenderer < Base
        def render_content
          case @value
          when Hash
            render_lead_time_analysis
          else
            render_simple_data
          end
        end

        private

        def render_lead_time_analysis
          [
            render_overall_metrics,
            render_author_performance,
            render_lead_time_distribution,
            render_bottleneck_analysis,
            render_trends,
            render_production_releases,
          ].compact.join
        end

        def render_overall_metrics
          return unless @value[:overall]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Overall Metrics')
          section('Overall Metrics', tooltip) do
            overall = @value[:overall]
            data_table(%w[Metric Value]) do
              [
                table_row(['Total Commits', format_number(overall[:total_commits])]),
                table_row(['Commits with Lead Time', format_number(overall[:commits_with_lead_time])]),
                table_row(['Avg Lead Time Hours', format('%.2f', overall[:avg_lead_time_hours].to_f)]),
                table_row(['Median Lead Time Hours', format('%.2f', overall[:median_lead_time_hours].to_f)]),
                table_row(['P95 Lead Time Hours', format('%.2f', overall[:p95_lead_time_hours].to_f)]),
                table_row(['Min Lead Time Hours', format('%.2f', overall[:min_lead_time_hours].to_f)]),
                table_row(['Max Lead Time Hours', format('%.2f', overall[:max_lead_time_hours].to_f)]),
                table_row(['Flow Efficiency', "#{format('%.1f', overall[:flow_efficiency].to_f * 100)}%"]),
              ].join
            end
          end
        end

        def render_author_performance
          return unless @value[:by_author]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Lead Time by Author')
          section('Author Performance', tooltip) do
            headers = ['Author', 'Commits', 'Avg Lead Time (h)', 'Median (h)', 'P95 (h)', 'Flow Efficiency']
            data_table(headers) do
              @value[:by_author].map do |author, stats|
                if stats.is_a?(Hash)
                  render_author_row(author, stats)
                else
                  table_row([author, safe_value_format(stats)])
                end
              end.join
            end
          end
        end

        def render_author_row(author, stats)
          author_display = author.to_s.strip.empty? ? '(Unknown Author)' : safe_string(author)
          cells = [
            author_display,
            format_number(stats[:total_commits].to_i),
            format('%.2f', stats[:avg_lead_time_hours].to_f),
            format('%.2f', stats[:median_lead_time_hours].to_f),
            format('%.2f', stats[:p95_lead_time_hours].to_f),
            "#{format('%.1f', stats[:flow_efficiency].to_f * 100)}%",
          ]
          table_row(cells)
        end

        def render_lead_time_distribution
          return unless @value[:lead_time_distribution]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Lead Time Distribution')
          section('Lead Time Distribution', tooltip) do
            headers = %w[Category Count]
            data_table(headers) do
              @value[:lead_time_distribution].map do |category, count|
                table_row([
                            format_label(category),
                            format_number(count.to_i),
                          ])
              end.join
            end
          end
        end

        def render_bottleneck_analysis
          return unless @value[:bottleneck_analysis]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Bottleneck Analysis')
          section('Bottleneck Analysis', tooltip) do
            bottlenecks = @value[:bottleneck_analysis]
            headers = %w[Metric Value]
            data_table(headers) do
              bottlenecks.map do |key, value|
                case value
                when Array
                  formatted_value = value.empty? ? '0' : render_bottleneck_array(value)
                  table_row([format_label(key), formatted_value])
                when Hash
                  formatted_value = value.empty? ? '0' : render_bottleneck_hash(value)
                  table_row([format_label(key), formatted_value])
                when Numeric
                  table_row([format_label(key), format('%.2f', value)])
                else
                  table_row([format_label(key), safe_string(value)])
                end
              end.join
            end
          end
        end

        def render_bottleneck_array(arr)
          return format_number(arr.length) if arr.all? { |item| item.is_a?(String) || item.is_a?(Numeric) }

          # For complex objects, show count
          format_number(arr.length)
        end

        def render_bottleneck_hash(hash)
          return format_number(hash.size) if hash.values.all? { |v| v.is_a?(Numeric) || v.is_a?(String) }

          # For complex hashes, show size
          format_number(hash.size)
        end

        def render_trends
          return unless @value[:trends]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Trends Over Time')
          section('Trends', tooltip) do
            headers = %w[Trend Value]
            data_table(headers) do
              @value[:trends].map do |key, value|
                case value
                when Array
                  formatted_value = value.empty? ? '0' : format_number(value.length)
                  table_row([format_label(key), formatted_value])
                when Hash
                  formatted_value = value.empty? ? '0' : format_number(value.size)
                  table_row([format_label(key), formatted_value])
                when Numeric
                  table_row([format_label(key), format('%.2f', value)])
                else
                  table_row([format_label(key), safe_string(value)])
                end
              end.join
            end
          end
        end

        def render_production_releases
          return unless @value[:production_releases]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Deployment Timeline')
          section('Recent Production Releases', tooltip) do
            headers = ['Date', 'Tag', 'Release Notes']
            data_table(headers) do
              @value[:production_releases].first(10).map do |release|
                table_row([
                            release[:date].to_s.split.first,
                            safe_string(release[:tag].to_s),
                            safe_string((release[:message] || release[:notes] || '').to_s.slice(0, 50)),
                          ])
              end.join
            end
          end
        end

        def format_label(key)
          key.to_s.gsub('_', ' ').split.map(&:capitalize).join(' ')
        end
      end
    end
  end
end
