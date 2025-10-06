# frozen_string_literal: true

module DevMetrics
  module Utils
    # Utility module for string operations - replaces global String monkey patching
    module StringUtils
      def self.humanize(string)
        safe_string = safe_to_utf8(string.to_s)
        safe_string.gsub(/[_-]/, ' ').split.map(&:capitalize).join(' ')
      end

      def self.titleize(string)
        humanize(string)
      end

      def self.truncate(text, length)
        return text unless text

        safe_text = safe_to_utf8(text.to_s)
        safe_text.length > length ? "#{safe_text[0...length]}..." : safe_text
      end

      def self.safe_to_utf8(string)
        return string if string.encoding == Encoding::UTF_8 && string.valid_encoding?

        # Handle encoding issues by forcing UTF-8 and cleaning invalid bytes
        string.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        # Fallback for severe encoding issues
        string.force_encoding('UTF-8').scrub('?')
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
