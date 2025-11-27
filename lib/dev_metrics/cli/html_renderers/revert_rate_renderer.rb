# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      # Specialized renderer for Revert Rate metric showing revert analysis
      class RevertRateRenderer < Base
        def render_content
          case @value
          when Hash
            render_revert_analysis
          else
            render_simple_data
          end
        end

        private

        def render_revert_analysis
          [
            render_overall_statistics,
            render_by_author,
            render_revert_details,
            render_time_patterns,
          ].compact.join
        end

        def render_overall_statistics
          return unless @value[:overall].is_a?(Hash)

          overall = @value[:overall]
          tooltip = Services::MetricDescriptions.get_section_description('Overall Statistics')
          section('Overall Statistics', tooltip) do
            data_table(%w[Metric Value]) do
              [
                table_row(['Total Commits', format_number(overall[:total_commits].to_i)]),
                table_row(['Revert Commits', format_number(overall[:revert_commits].to_i)]),
                table_row(['Reverted Commits', format_number(overall[:reverted_commits].to_i)]),
                table_row(['Revert Rate', "#{format_percentage_plain(overall[:revert_rate].to_f)}%"]),
                table_row(['Stability Score', stability_score_html(overall[:stability_score].to_f)]),
              ].join
            end
          end
        end

        def render_by_author
          return unless @value[:by_author].is_a?(Hash) && @value[:by_author].any?

          tooltip = Services::MetricDescriptions.get_section_description('Revert Statistics by Author')
          section('Revert Statistics by Author', tooltip) do
            headers = ['Author', 'Total Commits', 'Reverts Made', 'Commits Reverted', 'Revert Rate',
                       'Reliability Score',]
            data_table(headers) do
              @value[:by_author].map do |author, stats|
                cells = [
                  safe_string(author),
                  format_number(stats[:total_commits].to_i),
                  format_number(stats[:reverts_made].to_i),
                  format_number(stats[:commits_reverted].to_i),
                  "#{format_percentage_plain(stats[:revert_rate].to_f)}%",
                  reliability_score_html(stats[:reliability_score].to_f),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def render_revert_details
          return unless @value[:revert_details].is_a?(Hash)

          details = @value[:revert_details]
          output = []

          # Recent Reverts
          if details[:recent_reverts]&.any?
            tooltip_recent = Services::MetricDescriptions.get_section_description('Recent Reverts')
            output << section('Recent Reverts', tooltip_recent) do
              headers = ['Date', 'Author', 'Message', 'Reverted Commit']
              data_table(headers) do
                details[:recent_reverts].first(10).map do |commit|
                  cells = [
                    safe_string(commit[:date].to_s.split.first),
                    safe_string(commit[:author_name].to_s),
                    safe_string(commit[:message].to_s[0..50]),
                    safe_string(commit[:reverted_commit_hash].to_s[0..8]),
                  ]
                  table_row(cells)
                end.join
              end
            end
          end

          # Revert Reasons
          if details[:revert_reasons].is_a?(Hash) && details[:revert_reasons].any?
            tooltip_reasons = Services::MetricDescriptions.get_section_description('Revert Reasons')
            output << section('Revert Reasons', tooltip_reasons) do
              headers = %w[Reason Count]
              data_table(headers) do
                details[:revert_reasons].map do |reason, count|
                  cells = [
                    safe_string(reason),
                    format_number(count.to_i),
                  ]
                  table_row(cells)
                end.join
              end
            end
          end

          output.join
        end

        def render_time_patterns
          return unless @value[:time_patterns].is_a?(Hash)

          patterns = @value[:time_patterns]
          output = []

          # By Hour of Day
          if patterns[:by_hour_of_day].is_a?(Hash) && patterns[:by_hour_of_day].any?
            tooltip_hour = Services::MetricDescriptions.get_section_description('Revert Pattern by Hour of Day')
            output << section('Revert Pattern by Hour of Day', tooltip_hour) do
              headers = %w[Hour Count]
              data_table(headers) do
                patterns[:by_hour_of_day].map do |hour, count|
                  cells = [
                    safe_string("#{hour}:00"),
                    format_number(count.to_i),
                  ]
                  table_row(cells)
                end.join
              end
            end
          end

          # By Day of Week
          if patterns[:by_day_of_week].is_a?(Hash) && patterns[:by_day_of_week].any?
            tooltip_day = Services::MetricDescriptions.get_section_description('Revert Pattern by Day of Week')
            output << section('Revert Pattern by Day of Week', tooltip_day) do
              headers = %w[Day Count]
              data_table(headers) do
                patterns[:by_day_of_week].map do |day, count|
                  cells = [
                    safe_string(day),
                    format_number(count.to_i),
                  ]
                  table_row(cells)
                end.join
              end
            end
          end

          output.join
        end

        def stability_score_html(score)
          css_class = case score
                      when 0..20 then 'high'
                      when 21..50 then 'medium'
                      else 'low'
                      end
          "<span class=\"risk-#{css_class}\">#{format_float_plain(score, 1)}</span>"
        end

        def reliability_score_html(score)
          css_class = case score
                      when 0..20 then 'high'
                      when 21..50 then 'medium'
                      else 'low'
                      end
          "<span class=\"risk-#{css_class}\">#{format_float_plain(score, 1)}</span>"
        end
      end
    end
  end
end
