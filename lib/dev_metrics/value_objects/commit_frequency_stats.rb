# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing daily commit statistics
    class DailyCommitStats
      attr_reader :by_date, :average, :max, :min

      def initialize(by_date:, average:, max:, min:)
        @by_date = by_date.freeze
        @average = average
        @max = max
        @min = min
        freeze
      end

      def total_days
        by_date.size
      end

      def days_with_commits
        by_date.count { |_, count| count.positive? }
      end

      def days_without_commits
        total_days - days_with_commits
      end

      def activity_ratio
        return 0.0 if total_days.zero?

        (days_with_commits.to_f / total_days * 100).round(1)
      end

      def to_h
        {
          by_date: by_date,
          average: average,
          max: max,
          min: min,
          total_days: total_days,
          activity_ratio: activity_ratio,
        }
      end
    end

    # Value object representing hourly commit distribution
    class HourlyCommitStats
      attr_reader :hourly_distribution

      def initialize(hourly_distribution)
        @hourly_distribution = hourly_distribution.freeze
        freeze
      end

      def peak_hour
        return nil if hourly_distribution.empty?

        hourly_distribution.max_by { |_, count| count }&.first
      end

      def quietest_hour
        return nil if hourly_distribution.empty?

        hourly_distribution.min_by { |_, count| count }&.first
      end

      def morning_commits
        (6..11).sum { |hour| hourly_distribution[hour] || 0 }
      end

      def afternoon_commits
        (12..17).sum { |hour| hourly_distribution[hour] || 0 }
      end

      def evening_commits
        (18..23).sum { |hour| hourly_distribution[hour] || 0 }
      end

      def night_commits
        (0..5).sum { |hour| hourly_distribution[hour] || 0 }
      end

      def to_h
        hourly_distribution
      end
    end

    # Value object representing working hours vs off-hours statistics
    class WorkingHoursStats
      attr_reader :working_hours, :off_hours, :working_hours_percentage, :off_hours_percentage

      def initialize(working_hours:, off_hours:, working_hours_percentage:, off_hours_percentage:)
        @working_hours = working_hours
        @off_hours = off_hours
        @working_hours_percentage = working_hours_percentage
        @off_hours_percentage = off_hours_percentage
        freeze
      end

      def total_commits
        working_hours + off_hours
      end

      def mostly_working_hours?
        working_hours_percentage > 60
      end

      def balanced_schedule?
        (40..60).cover?(working_hours_percentage)
      end

      def night_owl?
        working_hours_percentage < 40
      end

      def to_h
        {
          working_hours: working_hours,
          off_hours: off_hours,
          working_hours_percentage: working_hours_percentage,
          off_hours_percentage: off_hours_percentage,
        }
      end
    end

    # Value object representing the busiest day statistics
    class BusiestDay
      attr_reader :date, :commits

      def initialize(date:, commits:)
        @date = date
        @commits = commits
        freeze
      end

      def formatted_date
        Date.parse(date).strftime('%A, %B %d, %Y')
      rescue StandardError
        date
      end

      def to_h
        {
          date: date,
          commits: commits,
        }
      end
    end

    # Value object representing complete commit frequency analysis
    class CommitFrequencyStats
      attr_reader :total_commits, :daily_stats, :hourly_stats, :weekday_distribution,
                  :working_hours_stats, :busiest_day, :busiest_hour, :consistency_score

      def initialize(total_commits:, daily_stats:, hourly_stats:, weekday_distribution:,
                     working_hours_stats:, busiest_day:, busiest_hour:, consistency_score:)
        @total_commits = total_commits
        @daily_stats = daily_stats
        @hourly_stats = hourly_stats
        @weekday_distribution = weekday_distribution.freeze
        @working_hours_stats = working_hours_stats
        @busiest_day = busiest_day
        @busiest_hour = busiest_hour
        @consistency_score = consistency_score
        freeze
      end

      def high_consistency?
        consistency_score > 70
      end

      def medium_consistency?
        (40..70).cover?(consistency_score)
      end

      def low_consistency?
        consistency_score < 40
      end

      def busiest_weekday
        return nil if weekday_distribution.empty?

        weekday_distribution.max_by { |_, count| count }&.first
      end

      def quietest_weekday
        return nil if weekday_distribution.empty?

        weekday_distribution.min_by { |_, count| count }&.first
      end

      def to_h
        {
          total_commits: total_commits,
          commits_per_day: daily_stats.to_h,
          commits_per_hour: hourly_stats.to_h,
          commits_per_weekday: weekday_distribution,
          working_hours_commits: working_hours_stats.to_h,
          busiest_day: busiest_day&.to_h,
          busiest_hour: busiest_hour,
          consistency_score: consistency_score,
        }
      end
    end
  end
end
