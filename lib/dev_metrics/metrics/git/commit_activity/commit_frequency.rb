# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes commit frequency patterns over time
        # Refactored to follow SOLID principles and use service objects
        class CommitFrequency < BaseMetric
          def metric_name
            'commit_frequency'
          end

          def description
            'Analysis of commit frequency patterns by hour, day, and week'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commits(time_period)
          end

          def compute_metric(commits_data)
            return build_empty_result if commits_data.empty?

            build_commit_frequency_stats(commits_data)
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            time_span_metadata = build_time_span_metadata(commits_data)
            super.merge(time_span_metadata)
          end

          private

          def build_empty_result
            stats = ValueObjects::CommitFrequencyStats.new(
              total_commits: 0,
              daily_stats: create_empty_daily_stats,
              hourly_stats: create_empty_hourly_stats,
              weekday_distribution: {},
              working_hours_stats: create_empty_working_hours_stats,
              busiest_day: nil,
              busiest_hour: 'Unknown',
              consistency_score: 0
            )

            # Return hash for compatibility with existing output formatter
            stats.to_h
          end

          def build_commit_frequency_stats(commits_data)
            stats = ValueObjects::CommitFrequencyStats.new(
              total_commits: commits_data.size,
              daily_stats: calculate_daily_stats(commits_data),
              hourly_stats: calculate_hourly_stats(commits_data),
              weekday_distribution: calculate_weekday_distribution(commits_data),
              working_hours_stats: calculate_working_hours_stats(commits_data),
              busiest_day: find_busiest_day(commits_data),
              busiest_hour: find_busiest_hour(commits_data),
              consistency_score: calculate_consistency_score(commits_data)
            )

            # Return hash for compatibility with existing output formatter
            stats.to_h
          end

          def calculate_daily_stats(commits_data)
            Services::DailyCommitCalculator.new(commits_data).calculate
          end

          def calculate_hourly_stats(commits_data)
            Services::HourlyCommitCalculator.new(commits_data).calculate
          end

          def calculate_weekday_distribution(commits_data)
            Services::WeekdayCommitCalculator.new(commits_data).calculate
          end

          def calculate_working_hours_stats(commits_data)
            Services::WorkingHoursCalculator.new(commits_data).calculate
          end

          def find_busiest_day(commits_data)
            Services::BusiestDayFinder.new(commits_data).find
          end

          def find_busiest_hour(commits_data)
            return 'Unknown' if commits_data.empty?

            hourly_stats = calculate_hourly_stats(commits_data)
            peak_hour = hourly_stats.peak_hour
            peak_hour ? "#{peak_hour}:00" : 'Unknown'
          end

          def calculate_consistency_score(commits_data)
            Services::ConsistencyScoreCalculator.new(commits_data).calculate
          end

          def build_time_span_metadata(commits_data)
            dates = extract_commit_dates(commits_data)
            date_range = calculate_date_range(dates)

            {
              time_span_days: (date_range / (24 * 60 * 60)).round(1),
              first_commit: dates.min,
              last_commit: dates.max,
              average_commits_per_day: calculate_average_commits_per_day(commits_data.size, date_range),
            }
          end

          def extract_commit_dates(commits_data)
            commits_data.map { |commit| commit[:date] }
          end

          def calculate_date_range(dates)
            dates.max - dates.min
          end

          def calculate_average_commits_per_day(total_commits, date_range_seconds)
            days = [date_range_seconds / (24 * 60 * 60), 1].max
            (total_commits.to_f / days).round(2)
          end

          def create_empty_daily_stats
            ValueObjects::DailyCommitStats.new(
              by_date: {},
              average: 0.0,
              max: 0,
              min: 0
            )
          end

          def create_empty_hourly_stats
            empty_distribution = (0..23).each_with_object({}) { |hour, hash| hash[hour] = 0 }
            ValueObjects::HourlyCommitStats.new(empty_distribution)
          end

          def create_empty_working_hours_stats
            ValueObjects::WorkingHoursStats.new(
              working_hours: 0,
              off_hours: 0,
              working_hours_percentage: 0.0,
              off_hours_percentage: 0.0
            )
          end

          def data_points_description
            'commits'
          end
        end
      end
    end
  end
end
