# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object for building and standardizing commit data structures
    class CommitDataBuilder
      def initialize(repository_name)
        @repository_name = repository_name
      end

      def build_commit(attributes)
        base_commit_attributes(attributes).merge(
          message: attributes[:message]
        ).merge(attributes.except(*base_keys, :message))
      end

      def build_commit_with_stats(attributes)
        base_commit_attributes(attributes).merge(
          subject: attributes[:subject],
          files_changed: attributes[:files_changed] || [],
          additions: attributes[:additions] || 0,
          deletions: attributes[:deletions] || 0
        )
      end

      def build_file_change(filename:, additions:, deletions:)
        {
          filename: filename,
          additions: additions,
          deletions: deletions,
        }
      end

      def build_contributor(name:, email:, commit_count:)
        {
          name: name,
          email: email,
          commit_count: commit_count,
          repository: repository_name,
        }
      end

      def build_tag(name:, date:)
        {
          name: name,
          tag_name: name, # alias for compatibility
          date: ensure_time_object(date),
          repository: repository_name,
        }
      end

      def empty_commit_stats
        {
          files_changed: [],
          additions: 0,
          deletions: 0,
        }
      end

      def empty_file_changes
        {}
      end

      def empty_commits
        []
      end

      def empty_contributors
        []
      end

      def empty_tags
        []
      end

      private

      attr_reader :repository_name

      def base_commit_attributes(attributes)
        {
          hash: attributes[:hash],
          author_name: attributes[:author_name],
          author_email: attributes[:author_email],
          date: ensure_time_object(attributes[:date]),
          repository: repository_name,
        }
      end

      def base_keys
        %i[hash author_name author_email date]
      end

      def ensure_time_object(date)
        return date if date.is_a?(Time)
        return Time.parse(date) if date.is_a?(String)

        date
      end
    end
  end
end
