module DevMetrics
  module CLI
    module HtmlRenderers
      class CommitFrequencyRenderer < Base
        protected

        def render_content
          [
            render_daily_activity,
            render_hourly_distribution,
            render_work_pattern
          ].compact.join
        end

        private

        def render_daily_activity
          return unless @value[:commits_per_day]

          section('Daily Activity') do
            metric_details do
              commits_per_day = @value[:commits_per_day]
              [
                metric_detail('Average per day', commits_per_day[:average], 'count'),
                metric_detail('Max in a day', commits_per_day[:max], 'count'),
                metric_detail('Total commits', @value[:total_commits], 'count')
              ].join
            end
          end
        end

        def render_hourly_distribution
          return unless @value[:commits_per_hour]&.any?

          section('Hourly Distribution') do
            metric_details do
              @value[:commits_per_hour].map do |hour, count|
                metric_detail("#{hour}:00", "#{count} commits", 'count')
              end.join
            end
          end
        end

        def render_work_pattern
          return unless @value[:working_hours_commits]

          section('Work Pattern') do
            metric_details do
              working_hours = @value[:working_hours_commits]
              [
                metric_detail(
                  'Working hours',
                  "#{working_hours[:working_hours_percentage]}% (#{working_hours[:working_hours]} commits)",
                  'percentage'
                ),
                metric_detail(
                  'Off hours',
                  "#{working_hours[:off_hours_percentage]}% (#{working_hours[:off_hours]} commits)",
                  'percentage'
                )
              ].join
            end
          end
        end
      end
    end
  end
end
