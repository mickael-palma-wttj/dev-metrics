# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes large commits that may indicate risky development practices
        class LargeCommits < BaseMetric
          def metric_name
            'large_commits'
          end

          def description
            'Identifies unusually large commits that may indicate poor development practices'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            # Calculate commit sizes and categorize
            commit_sizes = calculate_commit_sizes(commits_data)
            categorized_commits = categorize_by_size(commits_data, commit_sizes)

            # Analyze by author
            author_stats = calculate_author_large_commit_stats(commits_data, commit_sizes)

            # Calculate thresholds
            thresholds = calculate_size_thresholds(commit_sizes)

            # Overall statistics
            total_commits = commits_data.size
            large_commits = categorized_commits[:large].size
            huge_commits = categorized_commits[:huge].size

            {
              overall: {
                total_commits: total_commits,
                large_commits: large_commits,
                huge_commits: huge_commits,
                large_commit_ratio: calculate_ratio(large_commits, total_commits),
                huge_commit_ratio: calculate_ratio(huge_commits, total_commits),
                risk_score: calculate_risk_score(large_commits, huge_commits, total_commits),
                avg_commit_size: commit_sizes.empty? ? 0 : (commit_sizes.sum.to_f / commit_sizes.size).round(1),
              },
              thresholds: thresholds,
              by_author: author_stats,
              largest_commits: categorized_commits[:huge] + categorized_commits[:large],
              size_distribution: analyze_size_distribution(commit_sizes),
              risk_patterns: identify_risk_patterns(commits_data, commit_sizes),
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            overall = result[:overall]

            super.merge(
              large_commit_ratio: overall[:large_commit_ratio],
              risk_score: overall[:risk_score],
              avg_commit_size: overall[:avg_commit_size],
              high_risk_authors: count_high_risk_authors(result[:by_author]),
              largest_commit_author: find_largest_commit_author(result[:by_author]),
              size_threshold_large: result[:thresholds][:large],
              size_threshold_huge: result[:thresholds][:huge]
            )
          end

          private

          def calculate_commit_sizes(commits_data)
            commits_data.map do |commit|
              additions = commit[:additions] || 0
              deletions = commit[:deletions] || 0
              files_changed = commit[:files_changed]&.size || 0

              # Weighted size calculation
              line_changes = additions + deletions
              file_weight = files_changed * 10 # Files changed have additional weight

              line_changes + file_weight
            end
          end

          def calculate_size_thresholds(commit_sizes)
            return { small: 50, medium: 200, large: 500, huge: 1000 } if commit_sizes.empty?

            sorted_sizes = commit_sizes.sort

            # Statistical thresholds based on percentiles
            {
              small: calculate_percentile(sorted_sizes, 25),
              medium: calculate_percentile(sorted_sizes, 50),
              large: calculate_percentile(sorted_sizes, 75),
              huge: calculate_percentile(sorted_sizes, 90),
            }
          end

          def categorize_by_size(commits_data, commit_sizes)
            thresholds = calculate_size_thresholds(commit_sizes)

            categories = {
              small: [],
              medium: [],
              large: [],
              huge: [],
            }

            commits_data.each_with_index do |commit, index|
              size = commit_sizes[index]

              category = case size
                         when 0..thresholds[:small]
                           :small
                         when thresholds[:small]..thresholds[:medium]
                           :medium
                         when thresholds[:medium]..thresholds[:large]
                           :large
                         else
                           :huge
                         end

              # Add size info to commit
              commit_with_size = commit.merge(
                calculated_size: size,
                size_category: category
              )

              categories[category] << commit_with_size
            end

            # Sort each category by size (largest first)
            categories.each do |category, commits|
              categories[category] = commits.sort_by { |c| -c[:calculated_size] }
            end

            categories
          end

          def calculate_author_large_commit_stats(commits_data, commit_sizes)
            stats = Hash.new do |h, k|
              h[k] = {
                total_commits: 0,
                large_commits: 0,
                huge_commits: 0,
                avg_commit_size: 0.0,
                max_commit_size: 0,
                large_commit_ratio: 0.0,
                risk_score: 0.0,
              }
            end

            thresholds = calculate_size_thresholds(commit_sizes)

            commits_data.each_with_index do |commit, index|
              author = commit[:author] || commit[:author_name]
              size = commit_sizes[index]

              stats[author][:total_commits] += 1
              stats[author][:max_commit_size] = [stats[author][:max_commit_size], size].max

              if size >= thresholds[:huge]
                stats[author][:huge_commits] += 1
                stats[author][:large_commits] += 1
              elsif size >= thresholds[:large]
                stats[author][:large_commits] += 1
              end
            end

            # Calculate derived metrics
            stats.each do |author, data|
              author_commits = commits_data.select { |c| (c[:author] || c[:author_name]) == author }
              author_sizes = author_commits.map.with_index do |_, i|
                commit_sizes[commits_data.index(author_commits[i])]
              end

              data[:avg_commit_size] = author_sizes.empty? ? 0 : (author_sizes.sum.to_f / author_sizes.size).round(1)
              data[:large_commit_ratio] = calculate_ratio(data[:large_commits], data[:total_commits])
              data[:risk_score] =
                calculate_author_risk_score(data[:large_commits], data[:huge_commits], data[:total_commits])
            end

            stats.sort_by { |_, data| -data[:risk_score] }.to_h
          end

          def analyze_size_distribution(commit_sizes)
            return {} if commit_sizes.empty?

            sorted_sizes = commit_sizes.sort

            {
              min: sorted_sizes.first,
              max: sorted_sizes.last,
              median: calculate_percentile(sorted_sizes, 50),
              p75: calculate_percentile(sorted_sizes, 75),
              p90: calculate_percentile(sorted_sizes, 90),
              p95: calculate_percentile(sorted_sizes, 95),
              p99: calculate_percentile(sorted_sizes, 99),
              std_deviation: calculate_standard_deviation(commit_sizes),
            }
          end

          def identify_risk_patterns(commits_data, commit_sizes)
            thresholds = calculate_size_thresholds(commit_sizes)
            large_commits = []

            commits_data.each_with_index do |commit, index|
              size = commit_sizes[index]
              next unless size >= thresholds[:large]

              large_commits << {
                commit: commit,
                size: size,
                risk_factors: analyze_commit_risk_factors(commit, size, thresholds),
              }
            end

            {
              risky_commits: large_commits.sort_by { |c| -c[:size] }.first(20),
              common_risk_factors: aggregate_risk_factors(large_commits),
              time_patterns: analyze_large_commit_timing(large_commits),
            }
          end

          def analyze_commit_risk_factors(commit, size, thresholds)
            risk_factors = []

            # Size-based risks
            risk_factors << 'HUGE_SIZE' if size >= thresholds[:huge]
            risk_factors << 'LARGE_SIZE' if size >= thresholds[:large]

            # File count risks
            files_count = commit[:files_changed]&.size || 0
            risk_factors << 'MANY_FILES' if files_count > 20
            risk_factors << 'EXCESSIVE_FILES' if files_count > 50

            # Message-based risks
            message = (commit[:message] || commit[:subject] || '').downcase
            risk_factors << 'MERGE_COMMIT' if message.include?('merge')
            risk_factors << 'VAGUE_MESSAGE' if message.length < 10
            risk_factors << 'MULTIPLE_CONCERNS' if message.include?('and') && message.scan(/\band\b/).size > 1

            # Time-based risks
            time = commit[:date]
            risk_factors << 'OFF_HOURS' if time.hour < 9 || time.hour > 18
            risk_factors << 'WEEKEND' if time.saturday? || time.sunday?

            risk_factors
          end

          def aggregate_risk_factors(large_commits)
            factor_counts = Hash.new(0)

            large_commits.each do |commit_data|
              commit_data[:risk_factors].each do |factor|
                factor_counts[factor] += 1
              end
            end

            factor_counts.sort_by { |_, count| -count }.to_h
          end

          def analyze_large_commit_timing(large_commits)
            return {} if large_commits.empty?

            by_hour = Hash.new(0)
            by_day = Hash.new(0)

            large_commits.each do |commit_data|
              time = commit_data[:commit][:date]
              by_hour[time.hour] += 1
              by_day[time.strftime('%A')] += 1
            end

            {
              by_hour_of_day: by_hour,
              by_day_of_week: by_day,
              peak_hour: by_hour.max_by { |_, count| count }&.first,
              peak_day: by_day.max_by { |_, count| count }&.first,
            }
          end

          def calculate_percentile(sorted_array, percentile)
            return 0 if sorted_array.empty?

            index = (percentile / 100.0 * (sorted_array.length - 1)).round
            sorted_array[index]
          end

          def calculate_standard_deviation(values)
            return 0 if values.empty?

            mean = values.sum.to_f / values.size
            variance = values.sum { |v| (v - mean)**2 } / values.size
            Math.sqrt(variance).round(2)
          end

          def calculate_ratio(count, total)
            return 0.0 if total.zero?

            (count.to_f / total * 100).round(2)
          end

          def calculate_risk_score(large_commits, huge_commits, total_commits)
            return 0.0 if total_commits.zero?

            # Weighted risk: huge commits are more risky than large ones
            risk_points = (large_commits * 1) + (huge_commits * 3)
            max_risk_points = total_commits * 3

            (risk_points.to_f / max_risk_points * 100).round(2)
          end

          def calculate_author_risk_score(large_commits, huge_commits, total_commits)
            return 0.0 if total_commits.zero?

            risk_points = (large_commits * 1) + (huge_commits * 3)
            max_risk_points = total_commits * 3

            (risk_points.to_f / max_risk_points * 100).round(2)
          end

          def count_high_risk_authors(author_stats)
            author_stats.count { |_, stats| stats[:risk_score] > 20.0 }
          end

          def find_largest_commit_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:max_commit_size] }&.first
          end

          def data_points_description
            'commits'
          end
        end
      end
    end
  end
end
