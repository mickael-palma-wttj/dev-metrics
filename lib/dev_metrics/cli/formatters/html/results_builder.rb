# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Builder for results sections with extracted formatting logic
        class ResultsBuilder
          def self.build_results_sections(results)
            new(results).build_sections
          end

          def initialize(results)
            @results = results
          end

          def build_sections
            html = []
            grouped_results = group_results_by_category

            grouped_results.each do |category, category_results|
              add_category_section(html, category, category_results)
            end

            html
          end

          private

          attr_reader :results

          def group_results_by_category
            Services::ResultGrouper.new(results).group_by_category
          end

          def add_category_section(html, category, category_results)
            html << build_category_header(category)
            html.concat(build_category_results(category_results))
          end

          def build_category_header(category)
            "<h2>#{category.upcase.gsub('_', ' ')}</h2>"
          end

          def build_category_results(category_results)
            category_results.map do |result|
              build_result_item(result)
            end
          end

          def build_result_item(result)
            css_class = result.success? ? 'metric success' : 'metric error'
            content = result.success? ? format_value(result.value) : "ERROR - #{result.error}"

            "<div class='#{css_class}'><strong>#{result.metric_name}:</strong> #{content}</div>"
          end

          def format_value(value)
            Utils::ValueFormatter.format_generic_value(value)
          end
        end
      end
    end
  end
end
