require 'time'
require 'date'

module DevMetrics
  # Represents a time period for metric analysis
  # Handles date parsing, validation, and common time range operations
  class TimePeriod
    attr_reader :start_date, :end_date

    def initialize(start_date, end_date = nil)
      @start_date = parse_date(start_date)
      @end_date = parse_date(end_date) || Time.now
      
      validate_dates
    end

    def self.default
      # Default to last 30 days
      new(30, Time.now)
    end

    def self.last_week
      new(7, Time.now)
    end

    def self.last_month
      new(30, Time.now)
    end

    def self.last_quarter
      new(90, Time.now)
    end

    def self.last_year
      new(365, Time.now)
    end

    def to_h
      {
        start_date: start_date,
        end_date: end_date,
        duration_days: duration_days
      }
    end

    def duration_days
      ((end_date - start_date) / (24 * 60 * 60)).round
    end

    def contains?(date)
      parsed_date = parse_date(date)
      parsed_date >= start_date && parsed_date <= end_date
    end

    def to_s
      "#{format_date(start_date)} to #{format_date(end_date)}"
    end

    def ==(other)
      return false unless other.is_a?(TimePeriod)
      start_date == other.start_date && end_date == other.end_date
    end

    # Git log date format for filtering
    def git_since_format
      start_date.strftime('%Y-%m-%d')
    end

    def git_until_format
      end_date.strftime('%Y-%m-%d')
    end

    private

    def parse_date(date_input)
      return nil if date_input.nil?
      return date_input if date_input.is_a?(Time)
      
      case date_input
      when String
        Time.parse(date_input)
      when Date
        date_input.to_time
      when Integer
        # Assume days ago
        Time.now - (date_input * 24 * 60 * 60)
      else
        raise ArgumentError, "Cannot parse date: #{date_input}"
      end
    rescue ArgumentError => e
      raise ArgumentError, "Invalid date format: #{date_input}. #{e.message}"
    end

    def validate_dates
      raise ArgumentError, "Start date cannot be nil" if start_date.nil?
      raise ArgumentError, "End date cannot be nil" if end_date.nil?
      raise ArgumentError, "Start date must be before end date" if start_date >= end_date
    end

    def format_date(date)
      date.strftime('%Y-%m-%d')
    end

    # Helper methods for date arithmetic (simple implementations)
    def days_ago(n)
      Time.now - (n * 24 * 60 * 60)
    end
  end
end