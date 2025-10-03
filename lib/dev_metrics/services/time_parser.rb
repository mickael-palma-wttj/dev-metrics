# frozen_string_literal: true

require 'time'

module DevMetrics
  module Services
    # Service object responsible for parsing time options into Time objects
    class TimeParser
      RELATIVE_TIME_PATTERN = /^\d+[dwmy]$/
      SECONDS_PER_DAY = 24 * 60 * 60
      SECONDS_PER_WEEK = 7 * SECONDS_PER_DAY
      SECONDS_PER_MONTH = 30 * SECONDS_PER_DAY
      SECONDS_PER_YEAR = 365 * SECONDS_PER_DAY

      TIME_MULTIPLIERS = {
        'd' => SECONDS_PER_DAY,
        'w' => SECONDS_PER_WEEK,
        'm' => SECONDS_PER_MONTH,
        'y' => SECONDS_PER_YEAR,
      }.freeze

      attr_reader :time_option

      def initialize(time_option)
        @time_option = time_option
      end

      def parse
        return nil unless time_option

        if relative_time_format?
          parse_relative_time
        else
          parse_absolute_time
        end
      rescue ArgumentError
        raise ArgumentError, "Invalid time format: #{time_option}"
      end

      private

      def relative_time_format?
        time_option.is_a?(String) && time_option.match?(RELATIVE_TIME_PATTERN)
      end

      def parse_relative_time
        number = time_option.to_i
        unit = time_option[-1]
        multiplier = TIME_MULTIPLIERS[unit]

        Time.now - (number * multiplier)
      end

      def parse_absolute_time
        Time.parse(time_option.to_s)
      end
    end
  end
end
