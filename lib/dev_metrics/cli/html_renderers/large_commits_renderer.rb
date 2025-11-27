# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      class LargeCommitsRenderer < Base
        protected

        def render_content
          case @value
          when Hash
            render_large_commits_analysis
          else
            render_simple_data
          end
        end

        private

        def render_large_commits_analysis
          [
            render_overall_statistics,
            render_thresholds,
            render_largest_commits_table,
            render_by_author,
            render_by_file,
          ].compact.join
        end

        def render_overall_statistics
          return unless @value[:overall]

          overall = @value[:overall]
          tooltip = Services::MetricDescriptions.get_section_description('Overall Statistics')
          section('Overall Statistics', tooltip) do
            data_table(%w[Metric Value]) do
              [
                table_row(['Total Commits', format_number(overall[:total_commits].to_i)]),
                table_row(['Large Commits',
                           "#{format_number(overall[:large_commits].to_i)} (#{format_percentage_plain(overall[:large_commit_ratio].to_f)}%)",]),
                table_row(['Huge Commits',
                           "#{format_number(overall[:huge_commits].to_i)} (#{format_percentage_plain(overall[:huge_commit_ratio].to_f)}%)",]),
                table_row(['Risk Score', risk_score_html(overall[:risk_score].to_f)]),
              ].join
            end
          end
        end

        def render_thresholds
          return unless @value[:thresholds]

          tooltip = Services::MetricDescriptions.get_section_description('Size Thresholds')
          section('Size Thresholds', tooltip) do
            data_table(['Size Category', 'Threshold (lines)']) do
              @value[:thresholds].map do |size, threshold|
                table_row([
                            format_label(size),
                            format_number(threshold.to_i),
                          ])
              end.join
            end
          end
        end

        def render_largest_commits_table
          return unless @value[:largest_commits]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Largest Commits')
          section('Largest Commits', tooltip) do
            headers = ['Date', 'Author', 'Size (lines)', 'File Count', 'Message']
            data_table(headers) do
              @value[:largest_commits].first(20).map do |commit|
                table_row([
                            commit[:date].to_s.split.first,
                            safe_string(commit[:author_name].to_s),
                            format_number(commit[:calculated_size].to_i),
                            format_number(commit[:file_count].to_i),
                            safe_string((commit[:subject] || commit[:message] || '').to_s.slice(0, 50)),
                          ])
              end.join
            end
          end
        end

        def render_by_author
          return unless @value[:by_author]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Distribution by Author')
          section('Large Commits by Author', tooltip) do
            headers = ['Author', 'Total Commits', 'Large Commits', 'Large %', 'Huge Commits', 'Avg Size']
            data_table(headers) do
              @value[:by_author].first(15).map do |author, stats|
                cells = [
                  safe_string(author),
                  format_number(stats[:total_commits].to_i),
                  format_number(stats[:large_commits].to_i),
                  format_percentage_plain(stats[:large_commit_ratio].to_f),
                  format_number(stats[:huge_commits].to_i),
                  format_number(stats[:avg_size].to_i),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def render_by_file
          return unless @value[:by_file]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Files with Large Commits')
          section('Files with Large Commits', tooltip) do
            headers = ['File', 'Large Commits', 'Total Commits', 'Large %', 'Max Size']
            data_table(headers) do
              @value[:by_file].first(15).map do |file, stats|
                cells = [
                  safe_string(file),
                  format_number(stats[:large_commits].to_i),
                  format_number(stats[:total_commits].to_i),
                  format_percentage_plain(stats[:large_commit_ratio].to_f),
                  format_number(stats[:max_size].to_i),
                ]
                table_row(cells)
              end.join
            end
          end
        end

        def risk_score_html(score)
          css_class = case score
                      when 0..20 then 'low'
                      when 21..50 then 'medium'
                      else 'high'
                      end
          "<span class=\"risk-#{css_class}\">#{format_percentage_plain(score, 1)}</span>"
        end

        def format_label(key)
          key.to_s.gsub('_', ' ').split.map(&:capitalize).join(' ')
        end
      end
    end
  end
end
