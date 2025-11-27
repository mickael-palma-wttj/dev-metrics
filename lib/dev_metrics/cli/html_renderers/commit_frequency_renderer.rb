# frozen_string_literal: true

module DevMetrics
  module CLI
    module HtmlRenderers
      class CommitFrequencyRenderer < Base
        protected

        def render_content
          case @value
          when Hash
            render_frequency_analysis
          else
            render_simple_data
          end
        end

        private

        def render_frequency_analysis
          [
            render_daily_activity,
            render_hourly_distribution,
            render_work_pattern,
            render_by_author,
          ].compact.join
        end

        def render_daily_activity
          return unless @value[:commits_per_day]

          commits_per_day = @value[:commits_per_day]
          tooltip = Services::MetricDescriptions.get_section_description('Time Patterns')
          section('Daily Activity', tooltip) do
            data_table(%w[Metric Value]) do
              [
                table_row(['Average per Day', format_number(commits_per_day[:average].to_i)]),
                table_row(['Max in a Day', format_number(commits_per_day[:max].to_i)]),
                table_row(['Min in a Day', format_number(commits_per_day[:min].to_i)]),
                table_row(['Total Commits', format_number(@value[:total_commits].to_i)]),
              ].join
            end
          end
        end

        def render_hourly_distribution
          return unless @value[:commits_per_hour]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Time Patterns')
          section('Hourly Distribution', tooltip) do
            render_heatmap(@value[:commits_per_hour])
          end
        end

        def render_heatmap(commits_per_hour)
          max_commits = commits_per_hour.values.max.to_i
          return '<div class="heatmap-empty">No commit data available</div>' if max_commits.zero?

          hours_data = (0..23).map do |hour|
            count = commits_per_hour[hour] || 0
            intensity = calculate_intensity(count, max_commits)
            {
              hour: hour,
              count: count,
              intensity: intensity,
              label: format_hour_label(hour),
            }
          end

          render_heatmap_html(hours_data, max_commits)
        end

        def calculate_intensity(count, max_commits)
          return 0 if max_commits.zero?

          # Scale from 0 to 1, with a minimum intensity for non-zero values
          if count.zero?
            0
          else
            # Ensure minimum visibility for non-zero values
            base_intensity = 0.2
            scaled_intensity = (count.to_f / max_commits) * (1.0 - base_intensity)
            base_intensity + scaled_intensity
          end
        end

        def format_hour_label(hour)
          case hour
          when 0 then '12 AM'
          when 1..11 then "#{hour} AM"
          when 12 then '12 PM'
          when 13..23 then "#{hour - 12} PM"
          end
        end

        def render_heatmap_html(hours_data, max_commits)
          heatmap_html = <<~HTML
            <div class="commit-heatmap">
              <div class="heatmap-legend">
                <span class="legend-label">Activity Level:</span>
                <div class="legend-scale">
                  <div class="legend-item"><div class="legend-box legend-none"></div><span>None</span></div>
                  <div class="legend-item"><div class="legend-box legend-low"></div><span>Low</span></div>
                  <div class="legend-item"><div class="legend-box legend-medium"></div><span>Medium</span></div>
                  <div class="legend-item"><div class="legend-box legend-high"></div><span>High</span></div>
                </div>
              </div>
              <div class="heatmap-grid">
          HTML

          hours_data.each do |data|
            css_class = intensity_to_css_class(data[:intensity])
            heatmap_html += <<~HTML
              <div class="heatmap-cell #{css_class}"#{' '}
                   data-hour="#{data[:hour]}"#{' '}
                   data-count="#{data[:count]}"
                   title="#{data[:label]}: #{data[:count]} commit#{'s' unless data[:count] == 1}">
                <div class="cell-hour">#{data[:hour]}</div>
                <div class="cell-count">#{data[:count]}</div>
              </div>
            HTML
          end

          heatmap_html += <<~HTML
              </div>
              <div class="heatmap-summary">
                <div class="summary-stat">
                  <span class="stat-label">Peak Hour:</span>
                  <span class="stat-value">#{find_peak_hour(hours_data)}</span>
                </div>
                <div class="summary-stat">
                  <span class="stat-label">Max Commits:</span>
                  <span class="stat-value">#{max_commits}</span>
                </div>
              </div>
            </div>
          HTML

          heatmap_html
        end

        def intensity_to_css_class(intensity)
          case intensity
          when 0 then 'intensity-none'
          when 0.01..0.35 then 'intensity-low'
          when 0.36..0.7 then 'intensity-medium'
          else 'intensity-high'
          end
        end

        def find_peak_hour(hours_data)
          peak = hours_data.max_by { |data| data[:count] }
          peak[:count].positive? ? peak[:label] : 'None'
        end

        def render_work_pattern
          return unless @value[:working_hours_commits]

          working_hours = @value[:working_hours_commits]
          tooltip = Services::MetricDescriptions.get_section_description('Time Patterns')
          section('Work Pattern', tooltip) do
            data_table(%w[Category Percentage Count]) do
              [
                table_row(['Working Hours', format_percentage_plain(working_hours[:working_hours_percentage].to_f),
                           format_number(working_hours[:working_hours].to_i),]),
                table_row(['Off Hours', format_percentage_plain(working_hours[:off_hours_percentage].to_f),
                           format_number(working_hours[:off_hours].to_i),]),
              ].join
            end
          end
        end

        def render_by_author
          return unless @value[:by_author]&.any?

          tooltip = Services::MetricDescriptions.get_section_description('Distribution by Author')
          section('Commits by Author', tooltip) do
            headers = ['Author', 'Total Commits', 'Avg per Day', 'Max in a Day']
            data_table(headers) do
              @value[:by_author].first(20).map do |author, stats|
                cells = [
                  safe_string(author),
                  format_number(stats[:total_commits].to_i),
                  format('%.1f', stats[:avg_per_day].to_f),
                  format_number(stats[:max_in_day].to_i),
                ]
                table_row(cells)
              end.join
            end
          end
        end
      end
    end
  end
end
