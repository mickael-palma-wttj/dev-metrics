# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      class BugfixRatioRenderer < Base
        protected

        def render_content
          case @value
          when Hash
            render_bugfix_analysis
          else
            render_simple_data
          end
        end

        private

        def render_bugfix_analysis
          [
            render_overall_classification,
            render_by_author,
            render_by_file,
            render_trends,
          ].compact.join
        end

        def render_overall_classification
          return unless @value[:overall]

          overall = @value[:overall]
          tooltip = Services::MetricDescriptions.get_section_description('Overall Classification')
          section('Overall Classification', tooltip) do
            data_table(%w[Metric Value]) do
              [
                table_row(['Total Commits', format_number(overall[:total_commits])]),
                table_row(['Bugfix Commits',
                           "#{format_number(overall[:bugfix_commits])} (#{format('%.1f',
                                                                                 overall[:bugfix_ratio].to_f)}%)",]),
                table_row(['Feature Commits',
                           "#{format_number(overall[:feature_commits])} (#{format('%.1f',
                                                                                  overall[:feature_ratio].to_f)}%)",]),
                table_row(['Quality Score', format('%.2f', overall[:quality_score].to_f).to_s]),
              ].join
            end
          end
        end

        def render_by_author
          return unless @value[:by_author]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Bugfix Distribution')
          section('Bugfix Ratio by Author', tooltip) do
            headers = ['Author', 'Total Commits', 'Bugfix Commits', 'Bugfix Ratio %', 'Quality Score']
            data_table(headers) do
              @value[:by_author].map do |author, stats|
                cells = [
                  safe_string(author),
                  format_number(stats[:total_commits].to_i),
                  format_number(stats[:bugfix_commits].to_i),
                  format('%.1f', stats[:bugfix_ratio].to_f),
                  format('%.2f', stats[:quality_score].to_f),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def render_by_file
          return unless @value[:by_file]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Distribution by Author')
          section('Bugfix Distribution by File', tooltip) do
            headers = ['File', 'Bugfix Commits', 'Total Commits', 'Bugfix Ratio %']
            data_table(headers) do
              @value[:by_file].first(20).map do |file, stats|
                cells = [
                  safe_string(file),
                  format_number(stats[:bugfix_commits].to_i),
                  format_number(stats[:total_commits].to_i),
                  format('%.1f', stats[:bugfix_ratio].to_f),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def render_trends
          return unless @value[:trends]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Trends Over Time')
          section('Trends Over Time', tooltip) do
            headers = %w[Period Bugfix Count Total Count Bugfix Ratio %]
            data_table(headers) do
              @value[:trends].map do |period, stats|
                cells = [
                  safe_string(period),
                  format_number(stats[:bugfix_commits].to_i),
                  format_number(stats[:total_commits].to_i),
                  format('%.1f', stats[:bugfix_ratio].to_f),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def format_number(value)
          return '' if value.nil?

          "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
        end

        def number_with_delimiter(num)
          num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
        end

        def render_simple_data
          metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
        end

        def safe_string(value)
          str = value.to_s
          return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

          str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
          value.to_s.force_encoding('UTF-8').scrub('?')
        end
      end
    end
  end
end
