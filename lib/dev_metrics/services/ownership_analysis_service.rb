# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing file ownership patterns and generating summary statistics
    # Handles file processing and metadata calculation using injected services
    class OwnershipAnalysisService
      def initialize(ownership_calculator: OwnershipCalculatorService.new,
                     data_aggregator: FileDataAggregatorService.new,
                     summary_stats: OwnershipSummaryStatsService.new)
        @ownership_calculator = ownership_calculator
        @data_aggregator = data_aggregator
        @summary_stats = summary_stats
        @thresholds = ValueObjects::FileOwnershipThresholds
      end

      # Analyzes commit data to produce file ownership statistics
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] sorted hash of filename to FileOwnershipStats objects
      def analyze_ownership(commits_data)
        return {} if commits_data.empty?

        file_data = @data_aggregator.aggregate_file_data(commits_data)
        ownership_stats = build_ownership_stats(file_data)
        sort_by_concentration(ownership_stats)
      end

      # Calculates summary statistics for metadata
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] summary metrics for metadata
      def calculate_summary_stats(commits_data)
        return @summary_stats.calculate_summary_stats({}) if commits_data.empty?

        ownership_stats = analyze_ownership(commits_data)
        @summary_stats.calculate_summary_stats(ownership_stats)
      end

      private

      attr_reader :ownership_calculator, :data_aggregator, :summary_stats, :thresholds

      # Builds FileOwnershipStats objects from aggregated data
      def build_ownership_stats(file_data)
        result = {}

        file_data.each do |filename, data|
          result[filename] = create_ownership_stats(filename, data)
        end

        result
      end

      # Creates FileOwnershipStats for a single file
      def create_ownership_stats(filename, data)
        file_context = build_file_context(filename, data)
        ValueObjects::FileOwnershipStats.new(build_ownership_attributes(file_context))
      end

      # Builds file context object to reduce parameter passing
      def build_file_context(filename, data)
        sorted_commits = data[:commits].sort_by { |c| c[:date] }
        primary_owner_data = get_primary_owner_data(data)
        ownership_percentages = get_ownership_percentages(data)

        build_context_hash(filename, data, sorted_commits, primary_owner_data, ownership_percentages)
      end

      # Gets primary owner data
      def get_primary_owner_data(data)
        ownership_calculator.find_primary_owner(data[:authors])
      end

      # Gets ownership percentages
      def get_ownership_percentages(data)
        ownership_calculator.calculate_ownership_percentages(data[:authors], data[:total_changes])
      end

      # Builds context hash
      def build_context_hash(filename, data, sorted_commits, primary_owner_data, ownership_percentages)
        primary_owner, primary_changes = primary_owner_data

        {
          filename: filename,
          data: data,
          sorted_commits: sorted_commits,
          last_commit: sorted_commits.last,
          primary_owner: primary_owner,
          primary_changes: primary_changes,
          ownership_percentages: ownership_percentages,
        }
      end

      # Builds attributes hash for FileOwnershipStats
      def build_ownership_attributes(file_context)
        basic_attributes(file_context).merge(calculated_attributes(file_context))
      end

      # Basic file attributes
      def basic_attributes(file_context)
        {
          filename: file_context[:filename],
          last_modified_by: file_context[:last_commit][:author],
          last_modified_date: file_context[:last_commit][:date],
          total_changes: file_context[:data][:total_changes],
          contributor_count: file_context[:data][:authors].size,
        }
      end

      # Calculated ownership attributes
      def calculated_attributes(file_context)
        primary_attrs = primary_owner_attributes(file_context)
        ownership_attrs = ownership_distribution_attributes(file_context)

        primary_attrs.merge(ownership_attrs)
      end

      # Primary owner attributes
      def primary_owner_attributes(file_context)
        {
          primary_owner: file_context[:primary_owner],
          primary_owner_percentage: ownership_calculator.calculate_primary_owner_percentage(
            file_context[:primary_changes], file_context[:data][:total_changes]
          ),
          total_commits: file_context[:sorted_commits].size,
        }
      end

      # Ownership distribution attributes
      def ownership_distribution_attributes(file_context)
        {
          ownership_distribution: file_context[:ownership_percentages],
          ownership_concentration: ownership_calculator.calculate_ownership_concentration(
            file_context[:ownership_percentages]
          ),
          ownership_type: ownership_calculator.categorize_ownership_type(
            file_context[:ownership_percentages]
          ),
        }
      end

      # Sorts ownership stats by concentration in descending order
      def sort_by_concentration(ownership_stats)
        ownership_stats.sort_by { |_, stats| -stats.ownership_concentration }.to_h
      end
    end
  end
end
