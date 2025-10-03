# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for processing contributor filter information
    class ContributorFilterProcessor
      def self.process(summary)
        new(summary).process
      end

      def initialize(summary)
        @summary = summary.dup
      end

      def process
        return @summary unless @summary[:contributor_filter]

        filter_info = @summary[:contributor_filter]
        @summary[:contributor_filter_display] = build_display_text(filter_info)
        @summary
      end

      private

      def build_display_text(filter_info)
        contributors_list = filter_info[:contributors].join(', ')
        contributor_label = pluralize_contributor(filter_info[:count])
        "Filtered by Contributors: #{contributors_list} (#{filter_info[:count]} #{contributor_label})"
      end

      def pluralize_contributor(count)
        count == 1 ? 'contributor' : 'contributors'
      end
    end
  end
end
