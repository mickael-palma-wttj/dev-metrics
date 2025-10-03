# frozen_string_literal: true

module DevMetrics
  module Utils
    # Utility module for string operations - replaces global String monkey patching
    module StringUtils
      def self.humanize(string)
        string.to_s.gsub(/[_-]/, ' ').split.map(&:capitalize).join(' ')
      end

      def self.titleize(string)
        humanize(string)
      end

      def self.truncate(text, length)
        return text unless text

        text.length > length ? "#{text[0...length]}..." : text
      end

      def self.format_execution_time(time_seconds)
        return '0s' if time_seconds.nil? || time_seconds.zero?

        if time_seconds < 1
          "#{(time_seconds * 1000).round(0)}ms"
        else
          "#{time_seconds.round(2)}s"
        end
      end
    end
  end
end
