# frozen_string_literal: true

module DevMetrics
  module Collectors
    # Manages Git command caching with statistics
    #
    # This class provides an in-memory cache for Git command results
    # with hit/miss tracking and configurable enable/disable functionality.
    # Uses a CacheKeyBuilder to generate consistent cache keys.
    class GitCommandCache
      attr_reader :cache, :enabled

      # Initialize a new cache manager
      #
      # @param enabled [Boolean] whether caching is enabled by default
      def initialize(enabled = true)
        @cache = {}
        @enabled = enabled
        @hits = 0
        @misses = 0
        @key_builder = CacheKeyBuilder.new
      end

      # Execute a command with caching based on command string
      #
      # @param command [String] the Git command to execute
      # @param suffix [Symbol] the cache key suffix/identifier
      # @yield the block to execute if cache miss occurs
      # @return [String] the command output (cached or fresh)
      def execute_with_cache(command, suffix, &block)
        cache_key = @key_builder.build_command_key(command, suffix)
        execute_cached(cache_key, &block)
      end

      # Execute a command with caching based on parameter hash
      #
      # @param suffix [Symbol] the cache key suffix/identifier
      # @param params [Hash] the command parameters
      # @yield the block to execute if cache miss occurs
      # @return [String] the command output (cached or fresh)
      def execute_with_cache_key(suffix, params, &block)
        cache_key = @key_builder.build_params_key(suffix, params)
        execute_cached(cache_key, &block)
      end

      # Clears the cache and resets statistics
      #
      # @return [void]
      def clear
        @cache.clear
        reset_stats
      end

      def enable
        @enabled = true
      end

      def disable
        @enabled = false
        clear
      end

      def stats
        {
          size: @cache.size,
          enabled: @enabled,
          hit_rate: calculate_hit_rate,
          hits: @hits,
          misses: @misses,
        }
      end

      private

      # Execute a block with caching logic
      #
      # @param cache_key [String] the cache key to use
      # @yield the block to execute if cache miss or caching disabled
      # @return [String] the result (cached or fresh)
      def execute_cached(cache_key, &block)
        return yield unless @enabled

        fetch_or_execute(cache_key, &block)
      end

      def fetch_or_execute(cache_key)
        if @cache.key?(cache_key)
          @hits += 1
          @cache[cache_key]
        else
          @misses += 1
          result = yield
          @cache[cache_key] = result
          result
        end
      end

      def calculate_hit_rate
        total = @hits + @misses
        return 0.0 if total.zero?

        (@hits.to_f / total * 100).round(2)
      end

      def reset_stats
        @hits = 0
        @misses = 0
      end
    end
  end
end
