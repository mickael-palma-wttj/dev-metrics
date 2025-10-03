# frozen_string_literal: true

module DevMetrics
  module CLI
    module Formatters
      module HTML
        # Builder for metadata sections with extracted methods
        class MetadataBuilder
          SKIP_KEYS = %i[data_points data_points_label computed_at execution_time].freeze

          def self.build_metadata_section(metadata)
            new(metadata).build_section
          end

          def self.build_metadata_details(metadata)
            new(metadata).build_details
          end

          def initialize(metadata)
            @metadata = metadata
          end

          def build_section
            return [] unless metadata&.any?

            html = ["<div class='metadata'>", '<h3>Report Information</h3>']
            add_metadata_items(html)
            html << '</div>'
            html
          end

          def build_details
            return '' unless metadata

            html = +'<div class="metric-details">'
            add_detail_items(html)
            html << '</div>'
            html
          end

          private

          attr_reader :metadata

          def add_metadata_items(html)
            metadata.each do |key, value|
              html << build_metadata_item(key, value)
            end
          end

          def add_detail_items(html)
            metadata.each do |key, value|
              next if SKIP_KEYS.include?(key)

              html << build_detail_item(key, value)
            end
          end

          def build_metadata_item(key, value)
            "<p><strong>#{key.to_s.capitalize}:</strong> #{value}</p>"
          end

          def build_detail_item(key, value)
            [
              '<div class="metric-detail">',
              "<strong>#{Utils::StringUtils.humanize(key.to_s)}:</strong> ",
              Utils::ValueFormatter.format_metadata_value(value),
              '</div>',
            ].join
          end
        end
      end
    end
  end
end
