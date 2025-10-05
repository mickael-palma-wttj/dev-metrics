# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object representing a single deployment
    class Deployment
      attr_reader :type, :identifier, :date, :commit_hash, :deployment_method, :message

      def initialize(type:, identifier:, date:, commit_hash:, deployment_method:, message: nil)
        @type = type
        @identifier = identifier
        @date = date
        @commit_hash = commit_hash
        @deployment_method = deployment_method
        @message = message
        freeze
      end

      def production_release?
        type == 'production_release'
      end

      def merge_deployment?
        type == 'merge_deployment'
      end

      def tag_based?
        deployment_method == 'tag'
      end

      def merge_based?
        deployment_method == 'merge'
      end

      def short_hash
        commit_hash[0..7] if commit_hash
      end

      def days_ago
        return 0 unless date

        ((Time.now - date) / (24 * 60 * 60)).to_i
      end

      def same_day?(other_deployment)
        date.strftime('%Y-%m-%d') == other_deployment.date.strftime('%Y-%m-%d')
      end

      def to_h
        {
          type: type,
          identifier: identifier,
          date: date,
          commit_hash: commit_hash,
          deployment_method: deployment_method,
          message: message,
        }.compact
      end
    end
  end
end
