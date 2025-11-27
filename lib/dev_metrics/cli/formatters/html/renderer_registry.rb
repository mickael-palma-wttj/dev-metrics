# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Registry for metric renderers using Strategy pattern
        class RendererRegistry
          RENDERER_MAP = {
            'commit_frequency' => 'DevMetrics::CLI::HtmlRenderers::CommitFrequencyRenderer',
            'large_commits' => 'DevMetrics::CLI::HtmlRenderers::LargeCommitsRenderer',
            'bugfix_ratio' => 'DevMetrics::CLI::HtmlRenderers::BugfixRatioRenderer',
            'lines_changed' => 'DevMetrics::CLI::HtmlRenderers::LinesChangedRenderer',
            'file_churn' => 'DevMetrics::CLI::HtmlRenderers::FileChurnRenderer',
            'authors_per_file' => 'DevMetrics::CLI::HtmlRenderers::AuthorsPerFileRenderer',
            'file_ownership' => 'DevMetrics::CLI::HtmlRenderers::FileOwnershipRenderer',
            'co_change_pairs' => 'DevMetrics::CLI::HtmlRenderers::CoChangePairsRenderer',
            'revert_rate' => 'DevMetrics::CLI::HtmlRenderers::RevertRateRenderer',
            'lead_time' => 'DevMetrics::CLI::HtmlRenderers::LeadTimeRenderer',
            'deployment_frequency' => 'DevMetrics::CLI::HtmlRenderers::DeploymentFrequencyRenderer',
          }.freeze

          DEFAULT_RENDERER = 'DevMetrics::CLI::HtmlRenderers::GenericRenderer'

          def self.renderer_for(metric_name)
            renderer_class_name = RENDERER_MAP.fetch(metric_name.to_s, DEFAULT_RENDERER)
            constantize_renderer(renderer_class_name)
          end

          def self.render_metric_details(metric_name, value)
            return no_data_message unless value

            renderer_class = renderer_for(metric_name)
            result = renderer_class.new(value).render

            # Ensure the result is UTF-8 encoded to prevent encoding issues in templates
            ensure_utf8(result)
          end

          private_class_method def self.constantize_renderer(class_name)
            Object.const_get(class_name)
          end

          private_class_method def self.no_data_message
            '<div class="metric-detail">No data available</div>'
          end

          private_class_method def self.ensure_utf8(str)
            return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?

            str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
          rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
            str.force_encoding('UTF-8').scrub('?')
          end
        end
      end
    end
  end
end
