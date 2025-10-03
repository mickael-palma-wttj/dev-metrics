# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CommitActivity
        # Analyzes commit frequency patterns over time
        class CommitFrequency < BaseMetric
          include Utils::TimeHelper

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
            return {} if commits_data.empty?

            {
              total_commits: commits_data.size,
              commits_per_day: calculate_commits_per_day(commits_data),
              commits_per_hour: calculate_commits_per_hour(commits_data),
              commits_per_weekday: calculate_commits_per_weekday(commits_data),
              working_hours_commits: calculate_working_hours_split(commits_data),
              busiest_day: find_busiest_day(commits_data),
              busiest_hour: find_busiest_hour(commits_data),
              consistency_score: calculate_consistency_score(commits_data),
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            dates = commits_data.map { |c| c[:date] }
            date_range = dates.max - dates.min

            super.merge(
              time_span_days: (date_range / (24 * 60 * 60)).round(1),
              first_commit: dates.min,
              last_commit: dates.max,
              average_commits_per_day: (commits_data.size.to_f / [date_range / (24 * 60 * 60), 1].max).round(2)
            )
          end

          private

          def calculate_commits_per_day(commits_data)
            daily_counts = commits_data.group_by { |c| c[:date].strftime('%Y-%m-%d') }
              .transform_values(&:count)

            {
              by_date: daily_counts,
              average: (daily_counts.values.sum.to_f / daily_counts.size).round(2),
              max: daily_counts.values.max,
              min: daily_counts.values.min,
            }
          end

          def calculate_commits_per_hour(commits_data)
            hourly_counts = Hash.new(0)

            commits_data.each do |commit|
              hour = commit[:date].hour
              hourly_counts[hour] += 1
            end

            # Fill in missing hours with 0
            (0..23).each { |hour| hourly_counts[hour] ||= 0 }

            hourly_counts
          end

          def calculate_commits_per_weekday(commits_data)
            weekday_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
            weekday_counts = Hash.new(0)

            commits_data.each do |commit|
              weekday = weekday_names[commit[:date].wday]
              weekday_counts[weekday] += 1
            end

            weekday_counts
          end

          def calculate_working_hours_split(commits_data)
            working_hours_count = commits_data.count { |c| working_hours?(c[:date]) }
            off_hours_count = commits_data.size - working_hours_count

            {
              working_hours: working_hours_count,
              off_hours: off_hours_count,
              working_hours_percentage: (working_hours_count.to_f / commits_data.size * 100).round(1),
              off_hours_percentage: (off_hours_count.to_f / commits_data.size * 100).round(1),
            }
          end

          def find_busiest_day(commits_data)
            daily_counts = commits_data.group_by { |c| c[:date].strftime('%Y-%m-%d') }
              .transform_values(&:count)

            busiest_date = daily_counts.max_by { |_, count| count }
            return nil unless busiest_date

            {
              date: busiest_date[0],
              commits: busiest_date[1],
            }
          end

          def find_busiest_hour(commits_data)
            return 'Unknown' if commits_data.empty?

            hourly_counts = calculate_commits_per_hour(commits_data)
            busiest_hour = hourly_counts.max_by { |_, count| count }.first

            "#{busiest_hour}:00"
          end

          def data_points_description
            'commits'
          end

          def calculate_consistency_score(commits_data)
            return 0 if commits_data.empty?

            daily_counts = commits_data.group_by { |c| c[:date].strftime('%Y-%m-%d') }
              .transform_values(&:count)

            return 100 if daily_counts.size <= 1

            values = daily_counts.values
            mean = values.sum.to_f / values.size
            variance = values.map { |v| (v - mean)**2 }.sum / values.size
            std_dev = Math.sqrt(variance)

            # Convert to 0-100 scale where lower standard deviation = higher consistency
            coefficient_of_variation = std_dev / mean
            consistency = [100 - (coefficient_of_variation * 50), 0].max

            consistency.round(1)
          end
        end
      end
    end
  end
end
