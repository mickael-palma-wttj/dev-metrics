# frozen_string_literal: true

module DevMetrics
  module Utils
    # Utility module for time-related operations and working hours calculations
    module TimeHelper
      WORKING_HOURS_START = 9
      WORKING_HOURS_END = 18
      WEEKEND_DAYS = [0, 6].freeze # Sunday and Saturday

      def working_hours?(timestamp)
        time = parse_time(timestamp)
        return false if weekend?(time)

        hour = time.hour
        hour >= WORKING_HOURS_START && hour < WORKING_HOURS_END
      end

      def off_hours?(timestamp)
        !working_hours?(timestamp)
      end

      def weekend?(timestamp)
        time = parse_time(timestamp)
        WEEKEND_DAYS.include?(time.wday)
      end

      def business_days_between(start_date, end_date)
        start_time = parse_time(start_date)
        end_time = parse_time(end_date)

        days = 0
        current = start_time

        while current < end_time
          days += 1 unless weekend?(current)
          current += 24 * 60 * 60 # Add one day
        end

        days
      end

      def working_hours_between(start_time, end_time)
        start_parsed = parse_time(start_time)
        end_parsed = parse_time(end_time)

        total_hours = 0
        current = start_parsed

        while current < end_parsed
          if working_hours?(current)
            # Calculate how much of this hour is within working hours
            hour_end = Time.new(current.year, current.month, current.day, current.hour + 1)
            actual_end = [hour_end, end_parsed].min

            hours_in_this_slot = (actual_end - current) / 3600.0
            total_hours += hours_in_this_slot
          end

          current += 3600 # Move to next hour
        end

        total_hours
      end

      def format_duration(seconds)
        return '0s' if seconds.zero?

        days = seconds / (24 * 3600)
        hours = (seconds % (24 * 3600)) / 3600
        minutes = (seconds % 3600) / 60
        secs = seconds % 60

        parts = []
        parts << "#{days.to_i}d" if days.positive?
        parts << "#{hours.to_i}h" if hours.positive?
        parts << "#{minutes.to_i}m" if minutes.positive?
        parts << "#{secs.to_i}s" if secs.positive? && parts.empty?

        parts.join(' ')
      end

      def time_ago_in_words(timestamp)
        time = parse_time(timestamp)
        seconds_ago = Time.now - time

        case seconds_ago
        when 0..59
          "#{seconds_ago.to_i} seconds ago"
        when 60..3599
          minutes = (seconds_ago / 60).to_i
          "#{minutes} minute#{'s' if minutes != 1} ago"
        when 3600..86_399
          hours = (seconds_ago / 3600).to_i
          "#{hours} hour#{'s' if hours != 1} ago"
        when 86_400..2_591_999
          days = (seconds_ago / 86_400).to_i
          "#{days} day#{'s' if days != 1} ago"
        else
          time.strftime('%Y-%m-%d')
        end
      end

      private

      def parse_time(timestamp)
        return timestamp if timestamp.is_a?(Time)
        return timestamp.to_time if timestamp.respond_to?(:to_time)

        case timestamp
        when String
          Time.parse(timestamp)
        when Integer
          Time.at(timestamp)
        else
          raise ArgumentError, "Cannot parse timestamp: #{timestamp}"
        end
      end
    end
  end
end
