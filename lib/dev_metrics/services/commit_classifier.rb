# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for classifying commit messages into categories
    class CommitClassifier
      BUGFIX_PATTERNS = [
        # Conventional commits
        /^fix\b/,
        /^fix\(/,
        /^bugfix/,
        # Traditional patterns
        /\bfix\s+(bug|issue|error|problem)/,
        /\b(bug|error|issue)\s+fix/,
        /\bresol(ve|ution)\b/,
        /\bhotfix/,
        /\bpatch/,
        /\bcorrect/,
        /\brepair/,
        /\bhandle\s+(error|exception)/,
        # Specific patterns from analysis
        /\baddress\s+(warning|error)/,
        /\bprevent\s+(error|exception|crash)/,
        /\bmake\s+.+\s+nullable/,
        /\bstrict\s+.+\s+validation/,
        # Case variations
        /^Fix:/,
        /^FIX:/,
      ].freeze

      FEATURE_PATTERNS = [
        # Conventional commits
        /^feat\b/,
        /^feat\(/,
        /^feature/,
        # Traditional patterns
        /^add\b/,
        /^implement/,
        /^create/,
        /^new\s+/,
        /\benhance/,
        /\bimprove/,
        /\bupgrade/,
        /\bextend/,
        # Domain-specific patterns
        /\bopen\s+.+\s+creation/,
        /\breplace\s+.+\s+by\s+/,
        /\bbroadcast\s+.+\s+(from|to)/,
        /\balign\s+.+\s+versions/,
        /\bupdate\s+.+\s+(funnel|hiring)/,
        # Allow/Enable patterns
        /^allow\s+/,
        /^enable\s+/,
      ].freeze

      MAINTENANCE_PATTERNS = [
        # Conventional commits
        /^chore\b/,
        /^chore\(/,
        /^refactor\b/,
        /^refactor\(/,
        /^style\b/,
        /^test\b/,
        /^docs\b/,
        # Build and dependency management
        /^build\(/,
        /^Build\(/,
        /^ci\(/,
        /\bBuild\(deps\)/,
        /\bBuild\(deps-dev\)/,
        /\bbump\s+.+\s+from\s+.+\s+to\s+/,
        /\bupdate\s+.+\s+dependencies/,
        # Traditional patterns
        /^clean/,
        /^update/,
        /^format/,
        /^lint/,
        /^spec/,
        /\bdocument/,
        /\bcomment/,
        /\btypo/,
        /\bwhitespace/,
        /\breorg/,
        /\bmove\s/,
        /\brename/,
        # Configuration and setup
        /\bupdate\s+(ci|config|codeowners)/,
        /\bchange\s+.+\s+to\s+match\s+/,
        /\bmigrate\s+to\s+/,
        /\bdowngrade\s+/,
      ].freeze

      MERGE_PATTERNS = [
        /^Merge\s+(pull\s+request|branch)/,
        /^Merge\s+/,
        /^merge\s+/i,
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
        return :merge if matches_patterns?(message, MERGE_PATTERNS)
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
          merge: [],
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
