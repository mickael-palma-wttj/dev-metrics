# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing commit metadata
    class CommitSizeMetadata
      attr_reader :total_lines_changed, :total_additions, :total_deletions, :net_lines, :files_per_commit

      def initialize(total_lines_changed:, total_additions:, total_deletions:, net_lines:, files_per_commit:)
        @total_lines_changed = total_lines_changed
        @total_additions = total_additions
        @total_deletions = total_deletions
        @net_lines = net_lines
        @files_per_commit = files_per_commit
        freeze
      end

      def net_positive?
        net_lines.positive?
      end

      def net_negative?
        net_lines.negative?
      end

      def balanced_changes?
        return false if total_lines_changed.zero?

        deletion_ratio = (total_deletions.to_f / total_lines_changed * 100).round(1)
        (40..60).cover?(deletion_ratio)
      end

      def addition_dominant?
        total_additions > (total_deletions * 2)
      end

      def to_h
        {
          total_lines_changed: total_lines_changed,
          total_additions: total_additions,
          total_deletions: total_deletions,
          net_lines: net_lines,
          files_per_commit: files_per_commit,
        }
      end
    end
  end
end
