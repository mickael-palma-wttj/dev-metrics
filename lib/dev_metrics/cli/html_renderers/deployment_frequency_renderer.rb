# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Deployment Frequency metric showing deployment patterns
      class DeploymentFrequencyRenderer < Base
        def render_content
          case @value
          when Hash
            render_deployment_analysis
          else
            render_simple_data
          end
        end

        private

        def render_deployment_analysis
          [
            render_overall_metrics,
            render_deployments_list,
            render_patterns,
            render_stability,
            render_trends,
            render_quality_metrics,
          ].compact.join
        end

        def render_overall_metrics
          # Try both frequency_metrics and direct keys
          frequency = @value[:frequency_metrics]

          return unless frequency
          return unless frequency.is_a?(Hash) && frequency.any?

          tooltip = Services::MetricDescriptions.get_section_description('Deployment Metrics')
          section('Deployment Metrics', tooltip) do
            data_table(%w[Metric Value]) do
              [
                table_row(['Total Deployments', format_number(frequency[:total_deployments].to_i)]),
                table_row(['Deployments Per Week', format_float_plain(frequency[:deployments_per_week].to_f)]),
                table_row(['Avg Days Between', format_percentage_plain(frequency[:avg_days_between_deployments].to_f)]),
                table_row(['Days Since Last', format_number(frequency[:days_since_last_deployment].to_i)]),
                table_row(['Frequency Category', safe_string(frequency[:frequency_category].to_s)]),
                table_row(['Period Days', format_number(frequency[:period_days].to_i)]),
              ].join
            end
          end
        end

        def render_deployments_list
          return unless @value[:deployments]&.any?

          deployments = @value[:deployments]
          tooltip = Services::MetricDescriptions.get_section_description('Recent Deployments')
          section('Recent Deployments', tooltip) do
            headers = %w[Date Type Identifier Method Message]
            data_table(headers) do
              deployments.first(20).map do |deployment|
                cells = [
                  safe_string(deployment[:date].to_s.split.first),
                  safe_string(deployment[:type].to_s),
                  safe_string(deployment[:identifier].to_s.slice(0, 20)),
                  safe_string(deployment[:deployment_method].to_s),
                  safe_string((deployment[:message] || '').to_s.slice(0, 40)),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def render_patterns
          return unless @value[:patterns]

          patterns = @value[:patterns]
          return unless patterns.is_a?(Hash) && patterns.any?

          tooltip = Services::MetricDescriptions.get_section_description('Time Patterns')
          section('Deployment Patterns', tooltip) do
            data_table(%w[Metric Value]) do
              patterns.map do |key, value|
                case value
                when Numeric
                  table_row([format_label(key), format_float_plain(value)])
                when Array
                  table_row([format_label(key), format_number(value.length)])
                when Hash
                  table_row([format_label(key), format_number(value.size)])
                else
                  table_row([format_label(key), safe_string(value.to_s)])
                end
              end.join
            end
          end
        end

        def render_pattern_frequency(patterns)
          return '' unless patterns[:frequency]

          headers = ['Time Period', 'Count']
          data_table(headers) do
            patterns[:frequency].map do |period, count|
              table_row([
                          format_label(period),
                          format_number(count.to_i),
                        ])
            end.join
          end
        end

        def render_pattern_consistency(patterns)
          return '' unless patterns[:consistency]

          consistency = patterns[:consistency]
          score_class = case consistency[:consistency_score].to_f
                        when 0.8..1.0 then 'high'
                        when 0.5..0.79 then 'medium'
                        else 'low'
                        end

          "<div style=\"background: #f9f9f9; padding: 10px; border-radius: 4px; margin: 10px 0;\">
            <strong>Consistency Score:</strong> <span class=\"risk-#{score_class}\">#{format_float_plain(
              consistency[:consistency_score].to_f
            )}</span>
          </div>"
        end

        def render_pattern_automation(patterns)
          return '' unless patterns[:automation]

          automation = patterns[:automation]
          "<div style=\"background: #f9f9f9; padding: 10px; border-radius: 4px; margin: 10px 0;\">
            <strong>Automated Deployments:</strong> #{format_percentage_plain(automation[:automated_percentage].to_f)}%
          </div>"
        end

        def render_stability
          return unless @value[:stability]

          stability = @value[:stability]
          tooltip = Services::MetricDescriptions.get_section_description('Deployment Stability')
          section('Deployment Stability', tooltip) do
            data_table(%w[Metric Value]) do
              stability.map do |key, value|
                if value.is_a?(Numeric)
                  table_row([format_label(key), format_float_plain(value)])
                else
                  table_row([format_label(key), safe_string(value.to_s)])
                end
              end.join
            end
          end
        end

        def render_trends
          return unless @value[:trends]

          trends = @value[:trends]
          tooltip = Services::MetricDescriptions.get_section_description('Trends Over Time')
          section('Deployment Trends', tooltip) do
            headers = %w[Trend Value]
            data_table(headers) do
              trends.map do |key, value|
                case value
                when Numeric
                  table_row([format_label(key), format_float_plain(value)])
                when Array
                  table_row([format_label(key), format_number(value.length)])
                when Hash
                  table_row([format_label(key), format_number(value.size)])
                else
                  table_row([format_label(key), safe_string(value.to_s)])
                end
              end.join
            end
          end
        end

        def render_quality_metrics
          return unless @value[:quality_metrics]

          quality = @value[:quality_metrics]
          tooltip = Services::MetricDescriptions.get_section_description('Quality Metrics')
          section('Quality Metrics', tooltip) do
            headers = %w[Metric Value]
            data_table(headers) do
              quality.map do |key, value|
                if value.is_a?(Numeric)
                  formatted_value = if key.to_s.include?('percentage') || key.to_s.include?('ratio')
                                      "#{format_percentage_plain(value.to_f * 100)}%"
                                    else
                                      format_float_plain(value)
                                    end
                  table_row([format_label(key), formatted_value])
                else
                  table_row([format_label(key), safe_string(value.to_s)])
                end
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
