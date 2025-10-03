# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module Text
        # Builder for summary sections with extracted methods
        class SummaryBuilder
          def self.build(summary)
            new(summary).build
          end

          def initialize(summary)
            @summary = summary
          end

          def build
            output = []
            add_repository_info(output)
            add_contributor_filter(output)
            add_metrics_summary(output)
            add_blank_line(output)
            output
          end

          private

          attr_reader :summary

          def add_repository_info(output)
            return unless summary[:repository_info]

            repo_info = summary[:repository_info]
            output << "Repository: #{repo_info[:name]}"
            output << "Path: #{repo_info[:path]}"
            output << "Analyzed: #{repo_info[:analyzed_at]}"
            add_blank_line(output)
          end

          def add_contributor_filter(output)
            return unless summary[:contributor_filter_display]

            output << summary[:contributor_filter_display]
            add_blank_line(output)
          end

          def add_metrics_summary(output)
            output << "Total Metrics: #{summary[:total_metrics] || 0}"
            output << "Execution Time: #{format_execution_time}"
            output << "Data Coverage: #{summary[:data_coverage] || 0}%"
          end

          def format_execution_time
            Utils::StringUtils.format_execution_time(summary[:execution_time])
          end

          def add_blank_line(output)
            output << ''
          end
        end
      end
    end
  end
end
