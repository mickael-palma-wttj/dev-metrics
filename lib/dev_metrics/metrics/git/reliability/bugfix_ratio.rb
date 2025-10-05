# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes the ratio of bugfix commits to identify code quality patterns
        class BugfixRatio < BaseMetric
          def metric_name
            'bugfix_ratio'
          end

          def description
            'Analyzes the proportion of commits that are bugfixes vs feature development'
          end

          def calculate
            # Override BaseMetric's calculate to ensure proper data points calculation
            validate_inputs

            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            # Collect and process data
            processed_data = collect_data
            result = compute_metric(processed_data)

            end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            execution_time = (end_time - start_time).round(3)

            # Build metadata with correct data points
            metadata = build_metadata(processed_data)
            metadata[:execution_time] = execution_time

            # Create result directly
            Models::MetricResult.new(
              metric_name: metric_name,
              value: result,
              repository: repository.name,
              time_period: time_period,
              metadata: metadata
            )
          rescue StandardError => e
            Models::MetricResult.new(
              metric_name: metric_name,
              value: nil,
              repository: repository&.name || 'unknown',
              time_period: time_period,
              error: e.message,
              metadata: { error_class: e.class.name }
            )
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commits(time_period)
          end

          def compute_metric(commits_data)
            return build_empty_result if commits_data.empty?

            categorized_commits = classify_commits(commits_data)
            summary = build_summary(categorized_commits)
            author_stats = analyze_authors(commits_data, categorized_commits)
            time_patterns = analyze_patterns(categorized_commits[:bugfix])

            build_result(summary, author_stats, categorized_commits, time_patterns)
          end

          def build_metadata(processed_data)
            # Ensure we always report the correct data points
            data_points = processed_data.respond_to?(:size) ? processed_data.size : 0

            {
              total_records: data_points,
              data_points: data_points,
              data_points_label: data_points_description,
              computed_at: Time.now,
              options_used: options,
            }
          end

          def data_points_description
            'commits'
          end

          private

          def validate_inputs
            raise ArgumentError, 'Repository cannot be nil' if repository.nil?
            raise ArgumentError, 'Time period cannot be nil' if time_period.nil?
          end

          def build_empty_result
            {
              overall: {},
              by_author: {},
              commit_categories: { bugfix: [], feature: [], maintenance: [] },
              time_patterns: {},
            }
          end

          def classify_commits(commits_data)
            classifier = Services::CommitClassifier.new(commits_data)
            classifier.categorize_commits
          end

          def build_summary(categorized_commits)
            total = calculate_total_commits(categorized_commits)
            bugfix_count = categorized_commits[:bugfix].size
            feature_count = categorized_commits[:feature].size
            maintenance_count = categorized_commits[:maintenance].size

            ValueObjects::BugfixSummary.new(
              total_commits: total,
              bugfix_commits: bugfix_count,
              feature_commits: feature_count,
              maintenance_commits: maintenance_count
            )
          end

          def analyze_authors(commits_data, categorized_commits)
            analyzer = Services::AuthorBugfixAnalyzer.new(commits_data, categorized_commits)
            analyzer.analyze
          end

          def analyze_patterns(bugfix_commits)
            analyzer = Services::BugfixPatternAnalyzer.new(bugfix_commits)
            analyzer.analyze
          end

          def build_result(summary, author_stats, categorized_commits, time_patterns)
            {
              overall: summary.to_h,
              by_author: author_stats,
              commit_categories: extract_sample_commits(categorized_commits),
              time_patterns: time_patterns,
            }
          end

          def calculate_total_commits(categorized_commits)
            categorized_commits.values.flatten.size
          end

          def extract_sample_commits(categorized_commits)
            {
              bugfix: categorized_commits[:bugfix].first(10),
              feature: categorized_commits[:feature].first(10),
              maintenance: categorized_commits[:maintenance].first(10),
            }
          end

          def count_high_bugfix_authors(author_stats)
            author_stats.count { |_, stats| stats[:bugfix_ratio] > 30.0 }
          end

          def find_most_reliable_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:quality_score] }&.first
          end

          def calculate_trend(time_patterns)
            calculator = Services::BugfixTrendCalculator.new(time_patterns)
            calculator.calculate_trend
          end
        end
      end
    end
  end
end
