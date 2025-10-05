# frozen_string_literal: true

module DevMetrics
  module Services
    # Service responsible for analyzing co-change patterns in commit data
    # Orchestrates analysis using injected service dependencies
    class CoChangeAnalysisService
      def initialize(coupling_calculator: CouplingCalculatorService.new,
                     change_extractor: ChangeCountExtractorService.new,
                     stats_calculator: SummaryStatsCalculatorService.new)
        @coupling_calculator = coupling_calculator
        @change_extractor = change_extractor
        @stats_calculator = stats_calculator
        @thresholds = ValueObjects::CoChangePairThresholds
      end

      # Analyzes commit data to produce co-change pair statistics
      # @param commits_data [Array<Hash>] array of commit data with file changes
      # @return [Hash] sorted hash of pair keys to FilePairStats objects
      def analyze_co_changes(commits_data)
        return {} if commits_data.empty?

        co_change_counts, file_commit_counts = @change_extractor.extract_change_counts(commits_data)
        file_pair_stats = build_file_pair_stats(co_change_counts, file_commit_counts)

        sort_by_coupling_strength(file_pair_stats)
      end

      # Identifies architectural hotspots from analysis results
      # @param analysis_result [Hash] results from analyze_co_changes
      # @return [Hash] files with their hotspot relationship counts
      def identify_architectural_hotspots(analysis_result)
        file_coupling_counts = count_hotspot_relationships(analysis_result)
        filter_hotspots(file_coupling_counts)
      end

      # Calculates summary statistics from analysis results
      # @param analysis_result [Hash] results from analyze_co_changes
      # @return [Hash] summary metrics for metadata
      def calculate_summary_stats(analysis_result)
        @stats_calculator.calculate_summary_stats(analysis_result)
      end

      private

      attr_reader :coupling_calculator, :change_extractor, :stats_calculator, :thresholds

      # Builds FilePairStats objects from counts
      def build_file_pair_stats(co_change_counts, file_commit_counts)
        result = {}

        co_change_counts.each do |pair_key, co_change_count|
          file1, file2 = pair_key.split(' <-> ')
          file1_total = file_commit_counts[file1]
          file2_total = file_commit_counts[file2]

          result[pair_key] = coupling_calculator.create_file_pair_stats(
            file1, file2, co_change_count, file1_total, file2_total
          )
        end

        result
      end

      # Sorts results by coupling strength in descending order
      def sort_by_coupling_strength(file_pair_stats)
        file_pair_stats.sort_by { |_, stats| -stats.coupling_strength }.to_h
      end

      # Counts hotspot relationships for each file
      def count_hotspot_relationships(analysis_result)
        file_coupling_counts = Hash.new(0)

        analysis_result.each_value do |stats|
          next unless thresholds.hotspot_qualifying_coupling?(stats.coupling_strength)

          stats.files.each { |file| file_coupling_counts[file] += 1 }
        end

        file_coupling_counts
      end

      # Filters files that qualify as architectural hotspots
      def filter_hotspots(file_coupling_counts)
        hotspots = file_coupling_counts.select do |_, count|
          thresholds.architectural_hotspot?(count)
        end

        hotspots.sort_by { |_, count| -count }.to_h
      end
    end
  end
end
