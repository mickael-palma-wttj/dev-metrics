# frozen_string_literal: true

require 'digest'

module DevMetrics
  module Collectors
    # Builds consistent cache keys for different command types
    #
    # Uses SHA256 hashing to generate short, collision-resistant cache keys
    # from command strings or parameter hashes. Includes time period information
    # when applicable to ensure cache invalidation across different time ranges.
    class CacheKeyBuilder
      # 9 characters provides ~35 bits of entropy, sufficient for cache key uniqueness
      # with negligible collision probability in typical usage (< millions of keys)
      HASH_PREFIX_LENGTH = 9

      # Builds a cache key from a command string
      #
      # @param command [String] the Git command
      # @param suffix [Symbol] the cache key identifier
      # @return [String] the generated cache key
      def build_command_key(command, suffix)
        command_hash = hash_digest(command)
        "#{suffix}_#{command_hash}"
      end

      # Builds a cache key from command parameters
      #
      # Includes time period information to ensure different time ranges
      # generate different cache keys.
      #
      # @param suffix [Symbol] the cache key identifier
      # @param params [Hash] the command parameters
      # @return [String] the generated cache key
      def build_params_key(suffix, params)
        time_key = extract_time_key(params)
        params_without_time = params.except(:since, :until_date)
        params_hash = hash_digest(params_without_time.to_s)
        "#{suffix}_#{time_key}_#{params_hash}"
      end

      private

      def hash_digest(value)
        Digest::SHA256.hexdigest(value.to_s)[0...HASH_PREFIX_LENGTH]
      end

      def extract_time_key(params)
        since_date = params[:since]
        until_date = params[:until_date]

        return 'all_time' if all_time_range?(since_date, until_date)

        build_time_range_key(since_date, until_date)
      end

      def all_time_range?(since_date, until_date)
        since_date.nil? && until_date.nil?
      end

      def build_time_range_key(since_date, until_date)
        "#{since_date || 'beginning'}_#{until_date || 'now'}"
      end
    end
  end
end
