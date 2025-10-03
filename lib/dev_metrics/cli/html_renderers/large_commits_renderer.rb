module DevMetrics
  module CLI
    module HtmlRenderers
      class LargeCommitsRenderer < Base
        protected

        def render_content
          [
            render_overall_statistics,
            render_thresholds,
            render_largest_commits_table
          ].compact.join
        end

        private

        def render_overall_statistics
          return unless @value[:overall]

          section('Overall Statistics') do
            metric_details do
              overall = @value[:overall]
              [
                metric_detail('Total commits', overall[:total_commits], 'count'),
                metric_detail('Large commits', large_commits_text, 'count'),
                metric_detail('Huge commits', huge_commits_text, 'count'),
                metric_detail('Risk score', overall[:risk_score], risk_css_class)
              ].join
            end
          end
        end

        def render_thresholds
          return unless @value[:thresholds]

          section('Size Thresholds') do
            metric_details do
              @value[:thresholds].map do |size, threshold|
                metric_detail(size.to_s.capitalize, "#{threshold} lines", 'count')
              end.join
            end
          end
        end

        def render_largest_commits_table
          return unless @value[:largest_commits]&.any?

          section('Largest Commits') do
            data_table(%w[Date Author Size Message]) do
              @value[:largest_commits].first(5).map do |commit|
                table_row([
                            commit[:date].to_s.split(' ').first,
                            commit[:author_name],
                            "<span class=\"count\">#{commit[:calculated_size]} lines</span>",
                            StringUtils.truncate(commit[:subject], 50)
                          ])
              end.join
            end
          end
        end

        def large_commits_text
          overall = @value[:overall]
          "#{overall[:large_commits]} (#{overall[:large_commit_ratio]}%)"
        end

        def huge_commits_text
          overall = @value[:overall]
          "#{overall[:huge_commits]} (#{overall[:huge_commit_ratio]}%)"
        end

        def risk_css_class
          @value[:overall][:risk_score] > 30 ? 'risk-high' : 'percentage'
        end
      end
    end
  end
end
