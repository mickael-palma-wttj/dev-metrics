# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for classifying commit messages into categories
    class CommitClassifier
      BUGFIX_PATTERNS = [
        /^fix\b/,
        /^bugfix/,
        /\bfix\s+(bug|issue|error|problem)/,
        /\b(bug|error|issue)\s+fix/,
        /\bresol(ve|ution)\b/,
        /\bhotfix/,
        /\bpatch/,
        /\bcorrect/,
        /\brepair/,
        /\bhandle\s+(error|exception)/,
      ].freeze

      FEATURE_PATTERNS = [
        /^feat\b/,
        /^feature/,
        /^add\b/,
        /^implement/,
        /^create/,
        /^new\s+/,
        /\benhance/,
        /\bimprove/,
        /\bupgrade/,
        /\bextend/,
      ].freeze

      MAINTENANCE_PATTERNS = [
        /^refactor/,
        /^clean/,
        /^update/,
        /^chore/,
        /^style/,
        /^format/,
        /^lint/,
        /^test/,
        /^spec/,
        /\bdocument/,
        /\bcomment/,
        /\btypo/,
        /\bwhitespace/,
        /\breorg/,
        /\bmove\s/,
        /\brename/,
      ].freeze

      def initialize(commits_data)
        @commits_data = commits_data
      end

      def categorize_commits
        categories = initialize_categories

        commits_data.each do |commit|
          message = normalize_message(commit[:message])
          category = classify_message(message)
          categories[category] << commit
        end

        categories
      end

      def classify_message(message)
        return :bugfix if matches_patterns?(message, BUGFIX_PATTERNS)
        return :feature if matches_patterns?(message, FEATURE_PATTERNS)
        return :maintenance if matches_patterns?(message, MAINTENANCE_PATTERNS)

        :other
      end

      private

      attr_reader :commits_data

      def initialize_categories
        {
          bugfix: [],
          feature: [],
          maintenance: [],
          other: [],
        }
      end

      def normalize_message(message)
        message.downcase.strip
      end

      def matches_patterns?(message, patterns)
        patterns.any? { |pattern| message.match?(pattern) }
      end
    end
  end
end
