# frozen_string_literal: true

module DevMetrics
  module Services
    # Service object for sorting contributors by commit count
    # Follows Single Responsibility Principle - only handles sorting logic
    class ContributorSorter
      def initialize(contributors)
        @contributors = contributors
      end

      def sort_by_commits_desc
        contributors.sort_by { |contributor| -contributor.commit_count }
      end

      def sort_by_name
        contributors.sort_by(&:name)
      end

      def sort_by_activity_level
        contributors.sort do |a, b|
          activity_score(b) <=> activity_score(a)
        end
      end

      private

      attr_reader :contributors

      def activity_score(contributor)
        return 3 if contributor.high_activity?
        return 1 if contributor.low_activity?

        2 # medium activity
      end
    end
  end
end
