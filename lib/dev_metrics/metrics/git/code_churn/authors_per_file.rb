# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Analyzes how many authors have touched each file
        class AuthorsPerFile < BaseMetric
          def metric_name
            'authors_per_file'
          end

          def description
            'Number of distinct authors who have modified each file (bus factor analysis)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            file_authors = Hash.new { |h, k| h[k] = Set.new }

            commits_data.each do |commit|
              commit[:files_changed].each do |file_change|
                filename = file_change[:filename]
                file_authors[filename] << commit[:author_name]
              end
            end

            # Convert to final format with author counts and lists
            result = {}
            file_authors.each do |filename, authors_set|
              result[filename] = {
                author_count: authors_set.size,
                authors: authors_set.to_a.sort,
                bus_factor_risk: categorize_bus_factor_risk(authors_set.size),
                ownership_type: categorize_ownership(authors_set.size),
              }
            end

            # Sort by author count (highest first - most shared ownership)
            result.sort_by { |_, stats| -stats[:author_count] }.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)

            author_counts = result.values.map { |s| s[:author_count] }
            total_files = result.size

            # Risk categorization
            single_author_files = result.select { |_, s| s[:author_count] == 1 }.size
            shared_files = result.select { |_, s| s[:author_count] > 1 && s[:author_count] <= 3 }.size
            highly_shared_files = result.select { |_, s| s[:author_count] > 3 }.size

            super.merge(
              total_files_analyzed: total_files,
              avg_authors_per_file: total_files.positive? ? (author_counts.sum.to_f / total_files).round(2) : 0,
              max_authors_per_file: author_counts.max || 0,
              min_authors_per_file: author_counts.min || 0,
              single_author_files: single_author_files,
              shared_files: shared_files,
              highly_shared_files: highly_shared_files,
              bus_factor_risk_percentage: total_files.positive? ? (single_author_files.to_f / total_files * 100).round(1) : 0,
              collaboration_score: calculate_collaboration_score(result)
            )
          end

          private

          def categorize_bus_factor_risk(author_count)
            case author_count
            when 1
              'HIGH' # Single point of failure
            when 2..3
              'MEDIUM' # Limited knowledge sharing
            else
              'LOW' # Good knowledge distribution
            end
          end

          def categorize_ownership(author_count)
            case author_count
            when 1
              'SINGLE_OWNER' # One person knows this file
            when 2..3
              'SHARED' # Small team ownership
            when 4..10
              'COLLABORATIVE' # Good team collaboration
            else
              'HIGHLY_COLLABORATIVE' # Very distributed ownership
            end
          end

          def calculate_collaboration_score(result)
            return 0 if result.empty?

            total_files = result.size
            single_owner = result.count { |_, s| s[:author_count] == 1 }
            shared = result.count { |_, s| s[:author_count] > 1 && s[:author_count] <= 3 }
            collaborative = result.count { |_, s| s[:author_count] > 3 }

            # Weight the score: collaborative files get more points, penalize single owner
            score = ((shared * 50) + (collaborative * 100) - (single_owner * 10)).to_f / total_files
            [score, 100].min.round(1)
          end
        end
      end
    end
  end
end
