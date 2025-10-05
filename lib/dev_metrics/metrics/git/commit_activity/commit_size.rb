# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes commit size based on lines added and deleted
        # Refactored to follow SOLID principles and use service objects
        class CommitSize < BaseMetric
          def metric_name
            'commit_size'
          end

          def description
            'Distribution of commit sizes by lines changed (added + deleted)'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return build_empty_result if commits_data.empty?

            build_commit_size_stats(commits_data)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            metadata = calculate_commit_metadata(commits_data)
            super.merge(metadata.to_h)
          end

          private

          def build_empty_result
            stats = create_empty_stats
            stats.to_h
          end

          def build_commit_size_stats(commits_data)
            sizes = extract_commit_sizes(commits_data)
            distribution = categorize_sizes(sizes)
            stats_calculator = create_statistics_calculator(sizes)

            stats = ValueObjects::CommitSizeStats.new(
              total_commits: commits_data.size,
              average_size: stats_calculator.average,
              median_size: stats_calculator.median,
              min_size: stats_calculator.min,
              max_size: stats_calculator.max,
              distribution: distribution
            )

            stats.to_h
          end

          def extract_commit_sizes(commits_data)
            Services::CommitSizeExtractor.new(commits_data).extract_sizes
          end

          def categorize_sizes(sizes)
            Services::CommitSizeCategorizer.new(sizes).categorize
          end

          def create_statistics_calculator(sizes)
            Services::CommitSizeStatisticsCalculator.new(sizes)
          end

          def calculate_commit_metadata(commits_data)
            Services::CommitMetadataCalculator.new(commits_data).calculate
          end

          def create_empty_stats
            empty_distribution = create_empty_distribution

            ValueObjects::CommitSizeStats.new(
              total_commits: 0,
              average_size: 0.0,
              median_size: 0.0,
              min_size: 0,
              max_size: 0,
              distribution: empty_distribution
            )
          end

          def create_empty_distribution
            ValueObjects::SizeDistribution.new(
              small_commits: 0,
              medium_commits: 0,
              large_commits: 0,
              huge_commits: 0,
              total_commits: 0
            )
          end
        end
      end
    end
  end
end
