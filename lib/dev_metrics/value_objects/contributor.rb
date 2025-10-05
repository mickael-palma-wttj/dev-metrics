# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing a single contributor's statistics
    class Contributor
      attr_reader :name, :email, :commit_count

      def initialize(name:, email:, commit_count:)
        @name = name
        @email = email
        @commit_count = commit_count
        freeze
      end

      def display_name
        return formatted_name_with_email if email_present?

        name
      end

      def high_activity?
        commit_count > 50
      end

      def low_activity?
        commit_count < 5
      end

      def to_h
        {
          name: name,
          email: email,
          commit_count: commit_count,
          display_name: display_name,
        }
      end

      private

      def email_present?
        email && !email.empty?
      end

      def formatted_name_with_email
        "#{name} <#{email}>"
      end
    end
  end
end
