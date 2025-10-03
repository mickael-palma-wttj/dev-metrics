module DevMetrics
  module Collectors
    # Base class for all data collectors
    # Defines common interface and error handling for Git and GitHub data collection
    class BaseCollector
      attr_reader :repository, :options

      def initialize(repository, options = {})
        @repository = repository
        @options = options
      end

      # Template method for data collection
      def collect(time_period = nil)
        validate_repository
        setup_collection(time_period)
        perform_collection
      rescue CollectionError => e
        handle_collection_error(e)
      rescue StandardError => e
        handle_unexpected_error(e)
      end

      protected

      # Abstract methods to be implemented by subclasses
      def validate_repository
        raise NotImplementedError, 'Subclasses must implement #validate_repository'
      end

      def setup_collection(time_period)
        @time_period = time_period
      end

      def perform_collection
        raise NotImplementedError, 'Subclasses must implement #perform_collection'
      end

      private

      def handle_collection_error(error)
        log_error("Collection failed: #{error.message}")
        []
      end

      def handle_unexpected_error(error)
        log_error("Unexpected error during collection: #{error.message}")
        raise CollectionError, "Data collection failed: #{error.message}"
      end

      def log_error(message)
        # Simple logging to stderr for now
        warn "[#{self.class.name}] #{message}"
      end
    end

    # Custom exception for collection errors
    class CollectionError < StandardError; end
  end
end
