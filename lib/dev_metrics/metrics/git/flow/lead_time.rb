# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Flow
        # Analyzes lead time from commit to production deployment
        class LeadTime < BaseMetric
          def metric_name
            'lead_time'
          end

          def description
            'Measures lead time from code commit to production deployment'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            {
              commits: collector.collect_commits(time_period),
              tags: collector.collect_tags,
            }
          end

          def compute_metric(data)
            commits_data = data[:commits] || []
            tags_data = data[:tags] || []

            return {} if commits_data.empty?

            # Identify production releases
            production_releases = identify_production_releases(tags_data)

            # Calculate lead times for commits
            commit_lead_times = calculate_commit_lead_times(commits_data, production_releases)

            # Analyze by author
            author_stats = calculate_author_lead_times(commit_lead_times)

            # Overall statistics
            lead_times = commit_lead_times.map { |c| c[:lead_time_hours] }.compact

            {
              overall: {
                total_commits: commits_data.size,
                commits_with_lead_time: lead_times.size,
                avg_lead_time_hours: lead_times.empty? ? 0 : (lead_times.sum.to_f / lead_times.size).round(2),
                median_lead_time_hours: calculate_median(lead_times),
                p95_lead_time_hours: calculate_percentile(lead_times.sort, 95),
                min_lead_time_hours: lead_times.min || 0,
                max_lead_time_hours: lead_times.max || 0,
                flow_efficiency: calculate_flow_efficiency(lead_times),
              },
              by_author: author_stats,
              production_releases: production_releases.first(10),
              lead_time_distribution: analyze_lead_time_distribution(lead_times),
              bottleneck_analysis: identify_bottlenecks(commit_lead_times),
              trends: analyze_lead_time_trends(commit_lead_times),
            }
          end

          def build_metadata(data)
            return super if data.empty?

            result = compute_metric(data)
            overall = result[:overall]

            super.merge(
              avg_lead_time_hours: overall[:avg_lead_time_hours],
              median_lead_time_hours: overall[:median_lead_time_hours],
              flow_efficiency: overall[:flow_efficiency],
              fast_authors: count_fast_authors(result[:by_author]),
              slowest_author: find_slowest_author(result[:by_author]),
              bottleneck_count: result[:bottleneck_analysis][:high_lead_time_commits]&.size || 0
            )
          end

          private

          def identify_production_releases(tags_data)
            return [] if tags_data.empty?

            # Filter for production releases using shared patterns
            production_releases = Utils::ProductionTagPatterns.filter_production_tags(tags_data)

            # Sort by date (newest first)
            production_releases.sort_by { |tag| tag[:date] }.reverse
          end

          def calculate_commit_lead_times(commits_data, production_releases)
            return [] if production_releases.empty?

            commits_with_lead_time = []

            commits_data.each do |commit|
              commit_time = commit[:date]

              # Find the next production release after this commit
              next_release = production_releases.find do |release|
                release_time = release[:date]
                release_time > commit_time
              end

              next unless next_release

              release_time = next_release[:date]
              lead_time_seconds = release_time - commit_time
              lead_time_hours = (lead_time_seconds / 3600).round(2)

              commits_with_lead_time << commit.merge(
                lead_time_hours: lead_time_hours,
                lead_time_days: (lead_time_hours / 24).round(2),
                deployed_in_release: next_release[:name] || next_release[:tag_name],
                deployment_date: next_release[:date]
              )
            end

            commits_with_lead_time
          end

          def calculate_author_lead_times(commit_lead_times)
            stats = Hash.new do |h, k|
              h[k] = {
                total_commits: 0,
                commits_deployed: 0,
                avg_lead_time_hours: 0.0,
                median_lead_time_hours: 0.0,
                min_lead_time_hours: Float::INFINITY,
                max_lead_time_hours: 0.0,
                deployment_rate: 0.0,
              }
            end

            # Group commits by author
            author_commits = Hash.new { |h, k| h[k] = [] }
            commit_lead_times.each do |commit|
              author = commit[:author]
              author_commits[author] << commit[:lead_time_hours]
              stats[author][:commits_deployed] += 1
            end

            # Calculate author statistics
            author_commits.each do |author, lead_times|
              next if lead_times.empty?

              stats[author][:avg_lead_time_hours] = (lead_times.sum.to_f / lead_times.size).round(2)
              stats[author][:median_lead_time_hours] = calculate_median(lead_times)
              stats[author][:min_lead_time_hours] = lead_times.min
              stats[author][:max_lead_time_hours] = lead_times.max
            end

            # Calculate total commits per author (including non-deployed)
            commit_lead_times.each do |commit|
              author = commit[:author]
              stats[author][:total_commits] += 1
            end

            # Calculate deployment rate
            stats.each_value do |data|
              total = data[:total_commits]
              deployed = data[:commits_deployed]
              data[:deployment_rate] = total.positive? ? (deployed.to_f / total * 100).round(2) : 0.0
            end

            stats.sort_by { |_, data| data[:avg_lead_time_hours] }.to_h
          end

          def analyze_lead_time_distribution(lead_times)
            return {} if lead_times.empty?

            sorted_times = lead_times.sort

            {
              quartiles: {
                q1: calculate_percentile(sorted_times, 25),
                q2: calculate_percentile(sorted_times, 50),
                q3: calculate_percentile(sorted_times, 75),
              },
              percentiles: {
                p50: calculate_percentile(sorted_times, 50),
                p75: calculate_percentile(sorted_times, 75),
                p90: calculate_percentile(sorted_times, 90),
                p95: calculate_percentile(sorted_times, 95),
                p99: calculate_percentile(sorted_times, 99),
              },
              categories: categorize_lead_times(lead_times),
              outliers: identify_lead_time_outliers(sorted_times),
            }
          end

          def categorize_lead_times(lead_times)
            categories = {
              very_fast: 0,    # < 4 hours
              fast: 0,         # 4-24 hours
              moderate: 0,     # 1-7 days
              slow: 0,         # 1-4 weeks
              very_slow: 0, # > 4 weeks
            }

            lead_times.each do |hours|
              case hours
              when 0..4
                categories[:very_fast] += 1
              when 4..24
                categories[:fast] += 1
              when 24..168  # 7 days
                categories[:moderate] += 1
              when 168..672 # 4 weeks
                categories[:slow] += 1
              else
                categories[:very_slow] += 1
              end
            end

            categories
          end

          def identify_bottlenecks(commit_lead_times)
            return {} if commit_lead_times.empty?

            lead_times = commit_lead_times.map { |c| c[:lead_time_hours] }
            p95_threshold = calculate_percentile(lead_times.sort, 95)

            high_lead_time_commits = commit_lead_times.select do |commit|
              commit[:lead_time_hours] > p95_threshold
            end

            # Analyze patterns in high lead time commits
            common_factors = analyze_bottleneck_factors(high_lead_time_commits)

            {
              p95_threshold_hours: p95_threshold,
              high_lead_time_commits: high_lead_time_commits.first(20),
              common_bottleneck_factors: common_factors,
              bottleneck_authors: high_lead_time_commits.group_by { |c| c[:author] }
                .transform_values(&:size)
                .sort_by { |_, count| -count }
                .to_h,
            }
          end

          def analyze_bottleneck_factors(high_lead_time_commits)
            factors = Hash.new(0)

            high_lead_time_commits.each do |commit|
              # Time-based factors
              commit_time = commit[:date]
              factors['weekend_commits'] += 1 if commit_time.saturday? || commit_time.sunday?
              factors['after_hours_commits'] += 1 if commit_time.hour < 9 || commit_time.hour > 18
              factors['friday_commits'] += 1 if commit_time.friday?

              # Message-based factors
              message = commit[:message].downcase
              factors['merge_commits'] += 1 if message.include?('merge')
              factors['hotfix_commits'] += 1 if message.include?('hotfix') || message.include?('fix')
              factors['large_messages'] += 1 if message.length > 100
              factors['vague_messages'] += 1 if message.length < 20
            end

            factors.sort_by { |_, count| -count }.to_h
          end

          def analyze_lead_time_trends(commit_lead_times)
            return {} if commit_lead_times.size < 10

            # Group by month
            monthly_lead_times = Hash.new { |h, k| h[k] = [] }

            commit_lead_times.each do |commit|
              month = commit[:date].strftime('%Y-%m')
              monthly_lead_times[month] << commit[:lead_time_hours]
            end

            # Calculate monthly averages
            monthly_averages = monthly_lead_times.transform_values do |lead_times|
              lead_times.sum.to_f / lead_times.size
            end

            sorted_months = monthly_averages.keys.sort

            {
              monthly_averages: monthly_averages,
              trend_direction: calculate_trend_direction(sorted_months, monthly_averages),
              improvement_rate: calculate_improvement_rate(sorted_months, monthly_averages),
            }
          end

          def identify_lead_time_outliers(sorted_lead_times)
            return [] if sorted_lead_times.size < 4

            q1 = calculate_percentile(sorted_lead_times, 25)
            q3 = calculate_percentile(sorted_lead_times, 75)
            iqr = q3 - q1

            lower_bound = q1 - (1.5 * iqr)
            upper_bound = q3 + (1.5 * iqr)

            sorted_lead_times.select { |time| time < lower_bound || time > upper_bound }
          end

          def calculate_median(values)
            return 0 if values.empty?

            sorted = values.sort
            mid = sorted.length / 2

            if sorted.length.odd?
              sorted[mid]
            else
              (sorted[mid - 1] + sorted[mid]) / 2.0
            end
          end

          def calculate_percentile(sorted_array, percentile)
            return 0 if sorted_array.empty?

            index = (percentile / 100.0 * (sorted_array.length - 1)).round
            sorted_array[index]
          end

          def calculate_flow_efficiency(lead_times)
            return 1.0 if lead_times.empty?

            # Flow efficiency: percentage of commits delivered within acceptable time
            acceptable_threshold = 168 # 1 week in hours
            fast_commits = lead_times.count { |time| time <= acceptable_threshold }

            (fast_commits.to_f / lead_times.size).round(3)
          end

          def calculate_trend_direction(sorted_months, monthly_averages)
            return 'stable' if sorted_months.size < 2

            first_half = sorted_months.first(sorted_months.size / 2)
            second_half = sorted_months.last(sorted_months.size / 2)

            first_avg = first_half.sum { |month| monthly_averages[month] } / first_half.size
            second_avg = second_half.sum { |month| monthly_averages[month] } / second_half.size

            return 'improving' if second_avg < first_avg * 0.9
            return 'deteriorating' if second_avg > first_avg * 1.1

            'stable'
          end

          def calculate_improvement_rate(sorted_months, monthly_averages)
            return 0 if sorted_months.size < 2

            first_month = sorted_months.first
            last_month = sorted_months.last

            first_avg = monthly_averages[first_month]
            last_avg = monthly_averages[last_month]

            return 0 if first_avg.zero?

            ((first_avg - last_avg) / first_avg * 100).round(1)
          end

          def count_fast_authors(author_stats)
            author_stats.count { |_, stats| stats[:avg_lead_time_hours] < 24 }
          end

          def find_slowest_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:avg_lead_time_hours] }&.first
          end
        end
      end
    end
  end
end
