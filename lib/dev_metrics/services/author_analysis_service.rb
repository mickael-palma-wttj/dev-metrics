# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing author distribution across files
    class AuthorAnalysisService
      def initialize
        @thresholds = ValueObjects::AuthorsPerFileThresholds
      end

      def analyze_file_authors(commits_data)
        return {} if commits_data.empty?

        file_authors = extract_file_authors(commits_data)
        build_analysis_result(file_authors)
      end

      private

      attr_reader :thresholds

      def extract_file_authors(commits_data)
        file_authors = Hash.new { |h, k| h[k] = Set.new }

        commits_data.each do |commit|
          process_commit_files(commit, file_authors)
        end

        file_authors
      end

      def process_commit_files(commit, file_authors)
        files = commit[:files_changed] || commit[:files] || []
        files.each do |file_change|
          filename = extract_filename(file_change)
          file_authors[filename] << commit[:author_name] if filename
        end
      end

      def extract_filename(file_change)
        return file_change[:filename] if file_change[:filename]
        return file_change[:file] if file_change[:file]
        return file_change if file_change.is_a?(String)

        nil
      end

      def build_analysis_result(file_authors)
        result = {}

        file_authors.each do |filename, authors_set|
          result[filename] = build_file_analysis(authors_set)
        end

        sort_by_author_count(result)
      end

      def build_file_analysis(authors_set)
        author_count = authors_set.size

        {
          author_count: author_count,
          authors: authors_set.to_a.sort,
          bus_factor_risk: thresholds.bus_factor_risk_category(author_count),
          ownership_type: thresholds.ownership_type(author_count),
        }
      end

      def sort_by_author_count(result)
        result.sort_by { |_, stats| -stats[:author_count] }.to_h
      end
    end
  end
end
