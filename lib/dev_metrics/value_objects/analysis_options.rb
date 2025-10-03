# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object encapsulating analysis configuration options
    class AnalysisOptions
      attr_reader :exclude_metrics, :contributors, :exclude_bots,
                  :include_merge_commits, :since, :until, :no_progress

      def initialize(options = {})
        @exclude_metrics = options[:exclude_metrics]
        @contributors = normalize_contributors(options[:contributors])
        @exclude_bots = options[:exclude_bots] || false
        @include_merge_commits = options[:include_merge_commits] || true
        @since = options[:since]
        @until = options[:until]
        @no_progress = options[:no_progress] || false
      end

      def contributor_filter_active?
        contributors && !contributors.empty?
      end

      def time_filter_active?
        since || self.until
      end

      def progress_reporting_enabled?
        !no_progress
      end

      def to_h
        {
          exclude_metrics: exclude_metrics,
          contributors: contributors,
          exclude_bots: exclude_bots,
          include_merge_commits: include_merge_commits,
          since: since,
          until: self.until,
          no_progress: no_progress,
        }
      end

      private

      def normalize_contributors(contributors)
        return [] unless contributors

        case contributors
        when String
          contributors.split(',').map(&:strip)
        when Array
          contributors
        else
          []
        end
      end
    end
  end
end
