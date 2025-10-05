# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Flow
        # Analyzes lead time from commit to production deployment
        class LeadTime < BaseMetric
          def metric_name
            'lead_time'
          end

          def description
            'Measures lead time from code commit to production deployment'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            {
              commits: collector.collect_commits(time_period),
              tags: collector.collect_tags,
            }
          end

          def compute_metric(data)
            commits_data = data[:commits] || []
            tags_data = data[:tags] || []

            return build_empty_result if commits_data.empty?

            production_releases = identify_production_releases(tags_data)
            commit_lead_times = calculate_commit_lead_times(commits_data, production_releases)

            build_comprehensive_result(commit_lead_times)
          end

          private

          def build_empty_result
            {
              overall: build_empty_overall_stats,
              by_author: {},
              production_releases: [],
              lead_time_distribution: {},
              bottleneck_analysis: {},
              trends: {},
            }
          end

          def build_empty_overall_stats
            ValueObjects::LeadTimeMetrics.new(
              total_commits: 0,
              commits_with_lead_time: 0,
              avg_lead_time_hours: 0.0,
              median_lead_time_hours: 0.0,
              p95_lead_time_hours: 0.0,
              min_lead_time_hours: 0.0,
              max_lead_time_hours: 0.0,
              flow_efficiency: 0.0
            ).to_h
          end

          def identify_production_releases(tags_data)
            return [] if tags_data.empty?

            production_releases = Utils::ProductionTagPatterns.filter_production_tags(tags_data)
            production_releases.sort_by { |tag| tag[:date] }.reverse
          end

          def calculate_commit_lead_times(commits_data, production_releases)
            calculator = Services::LeadTimeCalculator.new(commits_data, production_releases)
            calculator.calculate
          end

          def build_comprehensive_result(commit_lead_times)
            return build_empty_result if commit_lead_times.empty?

            overall_metrics = build_overall_metrics(commit_lead_times)
            author_stats = analyze_author_performance(commit_lead_times)
            bottlenecks = detect_bottlenecks(commit_lead_times, author_stats)
            trends = analyze_trends(commit_lead_times)
            performance_distribution = categorize_performance(commit_lead_times)

            {
              overall: overall_metrics.to_h,
              by_author: serialize_author_stats(author_stats),
              production_releases: get_recent_releases,
              lead_time_distribution: performance_distribution,
              bottleneck_analysis: bottlenecks,
              trends: trends,
            }
          end

          def build_overall_metrics(commit_lead_times)
            lead_times = commit_lead_times.map(&:lead_time_hours)

            ValueObjects::LeadTimeMetrics.new(
              total_commits: commit_lead_times.size,
              commits_with_lead_time: lead_times.size,
              avg_lead_time_hours: calculate_average(lead_times),
              median_lead_time_hours: calculate_median(lead_times),
              p95_lead_time_hours: calculate_percentile(lead_times.sort, 95),
              min_lead_time_hours: lead_times.min || 0,
              max_lead_time_hours: lead_times.max || 0,
              flow_efficiency: calculate_flow_efficiency(lead_times)
            )
          end

          def analyze_author_performance(commit_lead_times)
            analyzer = Services::AuthorLeadTimeAnalyzer.new(commit_lead_times)
            analyzer.analyze
          end

          def detect_bottlenecks(commit_lead_times, author_stats)
            detector = Services::BottleneckDetector.new(commit_lead_times, author_stats)
            detector.detect_bottlenecks
          end

          def analyze_trends(commit_lead_times)
            analyzer = Services::TrendAnalyzer.new(commit_lead_times)
            analyzer.analyze_trends
          end

          def serialize_author_stats(author_stats)
            author_stats.transform_values(&:to_h)
          end

          def get_recent_releases
            # Return first 10 recent releases for display
            @production_releases&.first(10) || []
          end

          def categorize_performance(commit_lead_times)
            {
              very_fast: commit_lead_times.count(&:very_fast?),
              fast: commit_lead_times.count(&:fast?),
              moderate: commit_lead_times.count(&:moderate?),
              slow: commit_lead_times.count(&:slow?),
              very_slow: commit_lead_times.count(&:very_slow?),
            }
          end

          def calculate_average(values)
            return 0.0 if values.empty?

            (values.sum.to_f / values.size).round(2)
          end

          def calculate_median(values)
            return 0.0 if values.empty?

            sorted = values.sort
            mid = sorted.length / 2

            if sorted.length.odd?
              sorted[mid]
            else
              (sorted[mid - 1] + sorted[mid]) / 2.0
            end
          end

          def calculate_percentile(sorted_array, percentile)
            return 0.0 if sorted_array.empty?

            index = (percentile / 100.0 * (sorted_array.length - 1)).round
            sorted_array[index]
          end

          def calculate_flow_efficiency(lead_times)
            return 1.0 if lead_times.empty?

            acceptable_threshold = 168 # 1 week in hours
            fast_commits = lead_times.count { |time| time <= acceptable_threshold }

            (fast_commits.to_f / lead_times.size).round(3)
          end

          def build_metadata(data)
            return super if data.empty?

            result = compute_metric(data)
            overall = result[:overall]

            super.merge(
              avg_lead_time_hours: overall[:avg_lead_time_hours],
              median_lead_time_hours: overall[:median_lead_time_hours],
              flow_efficiency: overall[:flow_efficiency],
              fast_authors: count_fast_authors(result[:by_author]),
              slowest_author: find_slowest_author(result[:by_author]),
              bottleneck_count: result[:bottleneck_analysis][:blocked_commits]&.size || 0
            )
          end

          def count_fast_authors(author_stats)
            author_stats.count { |_, stats| stats[:avg_lead_time_hours] < 24 }
          end

          def find_slowest_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:avg_lead_time_hours] }&.first
          end
        end
      end
    end
  end
end
