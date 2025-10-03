# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for categorizing commits by size
    class CommitCategorizer
      def initialize(commits_data, commit_sizes, thresholds)
        @commits_data = commits_data
        @commit_sizes = commit_sizes
        @thresholds = thresholds
      end

      def categorize_by_size
        categories = initialize_categories

        commits_data.each_with_index do |commit, index|
          size = commit_sizes[index]
          category = determine_category(size)

          commit_with_size = enrich_commit_with_size(commit, size, category)
          categories[category] << commit_with_size
        end

        sort_categories_by_size(categories)
      end

      private

      attr_reader :commits_data, :commit_sizes, :thresholds

      def initialize_categories
        {
          small: [],
          medium: [],
          large: [],
          huge: [],
        }
      end

      def determine_category(size)
        case size
        when 0..thresholds[:small]
          :small
        when thresholds[:small]..thresholds[:medium]
          :medium
        when thresholds[:medium]..thresholds[:large]
          :large
        else
          :huge
        end
      end

      def enrich_commit_with_size(commit, size, category)
        commit.merge(
          calculated_size: size,
          size_category: category
        )
      end

      def sort_categories_by_size(categories)
        categories.each do |category, commits|
          categories[category] = commits.sort_by { |c| -c[:calculated_size] }
        end

        categories
      end
    end
  end
end
