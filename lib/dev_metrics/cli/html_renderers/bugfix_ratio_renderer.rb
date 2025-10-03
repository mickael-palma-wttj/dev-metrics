module DevMetrics
  module CLI
    module HtmlRenderers
      class BugfixRatioRenderer < Base
        protected

        def render_content
          render_commit_classification
        end

        private

        def render_commit_classification
          return unless @value[:overall]

          section('Commit Classification') do
            metric_details do
              overall = @value[:overall]
              [
                metric_detail('Total commits', overall[:total_commits], 'count'),
                metric_detail(
                  'Bugfix commits',
                  "#{overall[:bugfix_commits]} (#{overall[:bugfix_ratio]}%)",
                  'count'
                ),
                metric_detail(
                  'Feature commits',
                  "#{overall[:feature_commits]} (#{overall[:feature_ratio]}%)",
                  'count'
                ),
                metric_detail('Quality score', overall[:quality_score], 'percentage')
              ].join
            end
          end
        end
      end
    end
  end
end
