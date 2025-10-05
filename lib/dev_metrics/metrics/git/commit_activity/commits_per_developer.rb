# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Calculates commits per developer over a time period
        # Refactored to follow SOLID principles and use service objects
        class CommitsPerDeveloper < BaseMetric
          def metric_name
            'commits_per_developer'
          end

          def description
            'Number of commits per developer in the specified time period'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_contributors(time_period)
          end

          def compute_metric(contributors_data)
            return build_empty_result if contributors_data.empty?

            build_contributor_stats(contributors_data)
          end

          def build_metadata(contributors_data)
            return super if contributors_data.empty?

            contributor_stats = calculate_contributor_stats(contributors_data)
            super.merge(build_enhanced_metadata(contributor_stats))
          end

          private

          def build_empty_result
            {}
          end

          def build_contributor_stats(contributors_data)
            contributor_stats = calculate_contributor_stats(contributors_data)
            contributor_stats.to_h
          end

          def calculate_contributor_stats(contributors_data)
            contributors = transform_contributors(contributors_data)
            Services::ContributorMetricsCalculator.new(contributors).calculate
          end

          def transform_contributors(contributors_data)
            Services::ContributorTransformer.new(contributors_data).transform
          end

          def build_enhanced_metadata(contributor_stats)
            {
              total_contributors: contributor_stats.total_contributors,
              total_commits: contributor_stats.total_commits,
              avg_commits_per_contributor: contributor_stats.avg_commits_per_contributor,
              top_contributor: contributor_stats.top_contributor,
              top_contributor_dominance: contributor_stats.top_contributor_dominance,
              balanced_team: contributor_stats.balanced_team?,
              contributor_distribution: contributor_stats.contributor_distribution,
            }
          end
        end
      end
    end
  end
end
