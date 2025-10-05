# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing a commit with lead time information
    class CommitLeadTime
      attr_reader :hash, :author, :message, :date, :lead_time_hours,
                  :lead_time_days, :deployed_in_release, :deployment_date

      def initialize(hash:, author:, message:, date:, lead_time_hours:,
                     lead_time_days:, deployed_in_release:, deployment_date:)
        @hash = hash
        @author = author
        @message = message
        @date = date
        @lead_time_hours = lead_time_hours
        @lead_time_days = lead_time_days
        @deployed_in_release = deployed_in_release
        @deployment_date = deployment_date
        freeze
      end

      def very_fast?
        lead_time_hours <= 4
      end

      def fast?
        lead_time_hours > 4 && lead_time_hours <= 24
      end

      def moderate?
        lead_time_hours > 24 && lead_time_hours <= 168
      end

      def slow?
        lead_time_hours > 168 && lead_time_hours <= 672
      end

      def very_slow?
        lead_time_hours > 672
      end

      def weekend_commit?
        date.saturday? || date.sunday?
      end

      def after_hours_commit?
        date.hour < 9 || date.hour > 18
      end

      def friday_commit?
        date.friday?
      end

      def merge_commit?
        message.downcase.include?('merge')
      end

      def hotfix_commit?
        message.downcase.include?('hotfix') || message.downcase.include?('fix')
      end

      def large_message?
        message.length > 100
      end

      def vague_message?
        message.length < 20
      end

      def to_h
        {
          hash: hash,
          author: author,
          message: message,
          date: date,
          lead_time_hours: lead_time_hours,
          lead_time_days: lead_time_days,
          deployed_in_release: deployed_in_release,
          deployment_date: deployment_date,
        }
      end
    end
  end
end
