module DevMetrics
  module Metrics
    module Git
      module Flow
        # Analyzes deployment frequency and release patterns
        class DeploymentFrequency < DevMetrics::BaseMetric
          def metric_name
            'deployment_frequency'
          end

          def description
            'Measures deployment frequency and release cadence patterns'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            {
              tags: collector.collect_tags,
              commits: collector.collect_commits(time_period),
              branches: collector.collect_branches
            }
          end

          def compute_metric(data)
            tags_data = data[:tags] || []
            commits_data = data[:commits] || []
            branches_data = data[:branches] || []

            return {} if tags_data.empty? && commits_data.empty?

            # Identify different types of deployments
            deployments = identify_deployments(tags_data, commits_data, branches_data)

            # Calculate frequency metrics
            frequency_metrics = calculate_frequency_metrics(deployments)

            # Analyze deployment patterns
            patterns = analyze_deployment_patterns(deployments)

            # Calculate stability metrics
            stability = calculate_deployment_stability(deployments, commits_data)

            {
              overall: frequency_metrics,
              deployments: deployments.first(20),
              patterns: patterns,
              stability: stability,
              trends: analyze_frequency_trends(deployments),
              quality_metrics: calculate_quality_metrics(deployments, commits_data)
            }
          end

          def build_metadata(data)
            return super if data.empty?

            result = compute_metric(data)
            overall = result[:overall]

            super.merge(
              total_deployments: overall[:total_deployments],
              deployments_per_week: overall[:deployments_per_week],
              avg_days_between: overall[:avg_days_between_deployments],
              deployment_consistency: result[:stability][:consistency_score],
              deployment_velocity: result[:quality_metrics][:deployment_velocity],
              last_deployment_days_ago: overall[:days_since_last_deployment]
            )
          end

          private

          def identify_deployments(tags_data, commits_data, branches_data)
            deployments = []

            # Production releases from tags
            production_tags = identify_production_tags(tags_data)
            production_tags.each do |tag|
              deployments << {
                type: 'production_release',
                identifier: tag[:name] || tag[:tag_name],
                date: tag[:date],
                commit_hash: tag[:commit_hash],
                deployment_method: 'tag'
              }
            end

            # Merge commits to main/master (potential deployments)
            main_merges = identify_main_branch_merges(commits_data, branches_data)
            main_merges.each do |commit|
              deployments << {
                type: 'merge_deployment',
                identifier: commit[:hash][0..7],
                date: commit[:date],
                commit_hash: commit[:hash],
                deployment_method: 'merge',
                message: commit[:message]
              }
            end

            # Remove duplicates and sort by date
            unique_deployments = remove_duplicate_deployments(deployments)
            unique_deployments.sort_by { |d| d[:date] }.reverse
          end

          def identify_production_tags(tags_data)
            Utils::ProductionTagPatterns.filter_production_tags(tags_data)
          end

          def identify_main_branch_merges(commits_data, branches_data)
            main_branch_names = %w[main master production prod]
            
            # branches_data is an array of strings, not hashes with :current key
            # Look for main branch patterns in the branch names
            current_branch = branches_data.find { |branch| 
              main_branch_names.any? { |main_name| branch.include?(main_name) }
            } || 'main'

            # Include current branch if it looks like a main branch
            main_branch_names << current_branch unless main_branch_names.include?(current_branch)

            merge_patterns = [
              /^Merge pull request/i,
              /^Merge branch/i,
              /^Merge remote-tracking branch/i,
              /^Merged in/i
            ]

            commits_data.select do |commit|
              message = commit[:message].strip
              merge_patterns.any? { |pattern| message.match?(pattern) }
            end
          end

          def remove_duplicate_deployments(deployments)
            # Remove deployments that are too close together (same day)
            unique_deployments = []

            deployments_by_date = deployments.group_by { |d| d[:date].strftime('%Y-%m-%d') }

            deployments_by_date.each do |date, day_deployments|
              # Prefer production releases over merges
              production_release = day_deployments.find { |d| d[:type] == 'production_release' }

              if production_release
                unique_deployments << production_release
              else
                # Take the latest merge of the day
                latest_merge = day_deployments
                               .select { |d| d[:type] == 'merge_deployment' }
                               .max_by { |d| d[:date] }
                unique_deployments << latest_merge if latest_merge
              end
            end

            unique_deployments
          end

          def calculate_frequency_metrics(deployments)
            return default_frequency_metrics if deployments.empty?

            total_deployments = deployments.size

            # Calculate time span
            dates = deployments.map { |d| d[:date] }.sort
            first_deployment = dates.first
            last_deployment = dates.last

            days_span = ((last_deployment - first_deployment) / 86_400).round(1)
            days_span = [days_span, 1].max # Avoid division by zero

            # Calculate frequencies
            deployments_per_day = (total_deployments.to_f / days_span).round(3)
            deployments_per_week = (deployments_per_day * 7).round(2)
            deployments_per_month = (deployments_per_day * 30).round(2)

            # Calculate intervals between deployments
            intervals = calculate_deployment_intervals(dates)
            avg_days_between = intervals.empty? ? 0 : (intervals.sum.to_f / intervals.size).round(2)

            {
              total_deployments: total_deployments,
              days_span: days_span,
              deployments_per_day: deployments_per_day,
              deployments_per_week: deployments_per_week,
              deployments_per_month: deployments_per_month,
              avg_days_between_deployments: avg_days_between,
              min_days_between: intervals.min || 0,
              max_days_between: intervals.max || 0,
              days_since_last_deployment: calculate_days_since_last(last_deployment),
              frequency_category: categorize_frequency(deployments_per_week)
            }
          end

          def calculate_deployment_intervals(sorted_dates)
            return [] if sorted_dates.size < 2

            sorted_dates.each_cons(2).map do |date1, date2|
              ((date2 - date1) / 86_400).round(2) # Convert to days
            end
          end

          def analyze_deployment_patterns(deployments)
            return {} if deployments.empty?

            by_hour = Hash.new(0)
            by_day_of_week = Hash.new(0)
            by_month = Hash.new(0)
            by_deployment_type = Hash.new(0)

            deployments.each do |deployment|
              time = deployment[:date]

              by_hour[time.hour] += 1
              by_day_of_week[time.strftime('%A')] += 1
              by_month[time.strftime('%Y-%m')] += 1
              by_deployment_type[deployment[:type]] += 1
            end

            {
              by_hour_of_day: by_hour,
              by_day_of_week: by_day_of_week,
              by_month: by_month,
              by_deployment_type: by_deployment_type,
              peak_deployment_hour: by_hour.max_by { |_, count| count }&.first,
              peak_deployment_day: by_day_of_week.max_by { |_, count| count }&.first,
              working_hours_ratio: calculate_working_hours_ratio(by_hour),
              weekday_ratio: calculate_weekday_ratio(by_day_of_week)
            }
          end

          def calculate_deployment_stability(deployments, commits_data)
            return default_stability_metrics if deployments.empty?

            intervals = calculate_deployment_intervals(
              deployments.map { |d| d[:date] }.sort
            )

            return default_stability_metrics if intervals.empty?

            # Calculate coefficient of variation (lower = more consistent)
            mean_interval = intervals.sum.to_f / intervals.size
            variance = intervals.sum { |interval| (interval - mean_interval)**2 } / intervals.size
            std_deviation = Math.sqrt(variance)

            coefficient_of_variation = mean_interval > 0 ? (std_deviation / mean_interval) : 0
            consistency_score = [1.0 - coefficient_of_variation, 0.0].max.round(3)

            {
              consistency_score: consistency_score,
              coefficient_of_variation: coefficient_of_variation.round(3),
              std_deviation_days: std_deviation.round(2),
              deployment_predictability: categorize_predictability(consistency_score),
              longest_gap_days: intervals.max,
              shortest_gap_days: intervals.min
            }
          end

          def analyze_frequency_trends(deployments)
            return {} if deployments.size < 4

            # Group by month
            monthly_counts = Hash.new(0)
            deployments.each do |deployment|
              month = deployment[:date].strftime('%Y-%m')
              monthly_counts[month] += 1
            end

            sorted_months = monthly_counts.keys.sort
            return {} if sorted_months.size < 3

            # Calculate trend
            first_half = sorted_months.first(sorted_months.size / 2)
            second_half = sorted_months.last(sorted_months.size / 2)

            first_avg = first_half.sum { |month| monthly_counts[month] } / first_half.size.to_f
            second_avg = second_half.sum { |month| monthly_counts[month] } / second_half.size.to_f

            trend_direction = calculate_trend_direction(first_avg, second_avg)
            trend_percentage = first_avg > 0 ? ((second_avg - first_avg) / first_avg * 100).round(1) : 0

            {
              monthly_counts: monthly_counts,
              trend_direction: trend_direction,
              trend_percentage: trend_percentage,
              most_active_month: monthly_counts.max_by { |_, count| count }&.first,
              least_active_month: monthly_counts.min_by { |_, count| count }&.first
            }
          end

          def calculate_quality_metrics(deployments, commits_data)
            return {} if deployments.empty? || commits_data.empty?

            # Calculate commits per deployment
            total_commits = commits_data.size
            commits_per_deployment = (total_commits.to_f / deployments.size).round(2)

            # Calculate batch size (commits delivered per deployment)
            deployment_velocity = categorize_velocity(commits_per_deployment)

            # Analyze deployment success patterns
            success_indicators = analyze_success_patterns(deployments)

            {
              commits_per_deployment: commits_per_deployment,
              deployment_velocity: deployment_velocity,
              batch_size_category: categorize_batch_size(commits_per_deployment),
              success_indicators: success_indicators,
              deployment_efficiency: calculate_deployment_efficiency(deployments, commits_data)
            }
          end

          def analyze_success_patterns(deployments)
            # Analyze deployment messages for success/failure indicators
            success_keywords = %w[success successful deploy deployed release released]
            failure_keywords = %w[rollback revert failed error issue problem]

            success_count = 0
            failure_count = 0

            deployments.each do |deployment|
              message = (deployment[:message] || '').downcase

              success_count += 1 if success_keywords.any? { |keyword| message.include?(keyword) }
              failure_count += 1 if failure_keywords.any? { |keyword| message.include?(keyword) }
            end

            {
              apparent_successes: success_count,
              apparent_failures: failure_count,
              success_rate: calculate_success_rate(success_count, failure_count, deployments.size)
            }
          end

          def default_frequency_metrics
            {
              total_deployments: 0,
              days_span: 0,
              deployments_per_day: 0,
              deployments_per_week: 0,
              deployments_per_month: 0,
              avg_days_between_deployments: 0,
              frequency_category: 'none'
            }
          end

          def default_stability_metrics
            {
              consistency_score: 0,
              coefficient_of_variation: 0,
              deployment_predictability: 'unknown'
            }
          end

          def calculate_days_since_last(last_deployment_time)
            return 0 if last_deployment_time.nil?

            ((Time.now - last_deployment_time) / 86_400).round(1)
          end

          def categorize_frequency(deployments_per_week)
            case deployments_per_week
            when 0
              'none'
            when 0..0.25
              'low'        # Less than once per month
            when 0.25..1
              'moderate'   # Weekly to monthly
            when 1..3
              'high'       # Multiple times per week
            else
              'very_high'  # Daily or more
            end
          end

          def categorize_predictability(consistency_score)
            case consistency_score
            when 0.8..1.0
              'highly_predictable'
            when 0.6..0.8
              'moderately_predictable'
            when 0.4..0.6
              'somewhat_predictable'
            else
              'unpredictable'
            end
          end

          def categorize_velocity(commits_per_deployment)
            case commits_per_deployment
            when 0..5
              'small_batches'      # Ideal for continuous deployment
            when 5..20
              'medium_batches'     # Reasonable batch size
            when 20..50
              'large_batches'      # May indicate infrequent deployments
            else
              'very_large_batches' # High risk, infrequent deployments
            end
          end

          def categorize_batch_size(commits_per_deployment)
            case commits_per_deployment
            when 0..1
              'SINGLE_COMMIT'
            when 1..5
              'SMALL_BATCH'
            when 5..15
              'MEDIUM_BATCH'
            when 15..30
              'LARGE_BATCH'
            else
              'VERY_LARGE_BATCH'
            end
          end

          def calculate_working_hours_ratio(by_hour)
            working_hours = (9..18).to_a
            working_deployments = working_hours.sum { |hour| by_hour[hour] }
            total_deployments = by_hour.values.sum

            return 0 if total_deployments == 0

            (working_deployments.to_f / total_deployments).round(3)
          end

          def calculate_weekday_ratio(by_day_of_week)
            weekdays = %w[Monday Tuesday Wednesday Thursday Friday]
            weekday_deployments = weekdays.sum { |day| by_day_of_week[day] }
            total_deployments = by_day_of_week.values.sum

            return 0 if total_deployments == 0

            (weekday_deployments.to_f / total_deployments).round(3)
          end

          def calculate_trend_direction(first_avg, second_avg)
            return 'stable' if first_avg == 0 || (second_avg - first_avg).abs < 0.1

            second_avg > first_avg ? 'increasing' : 'decreasing'
          end

          def calculate_success_rate(success_count, failure_count, total_deployments)
            return 0 if total_deployments == 0

            # If we have explicit success/failure indicators
            if success_count > 0 || failure_count > 0
              total_with_indicators = success_count + failure_count
              return 0 if total_with_indicators == 0

              (success_count.to_f / total_with_indicators * 100).round(2)
            end

            # Assume deployments are successful unless proven otherwise
            apparent_success_rate = ((total_deployments - failure_count).to_f / total_deployments * 100).round(2)
            [apparent_success_rate, 0].max
          end

          def calculate_deployment_efficiency(deployments, commits_data)
            return 0 if deployments.empty? || commits_data.empty?

            # Simple efficiency: more frequent deployments with smaller batches = higher efficiency
            deployments_per_week = (deployments.size.to_f / (commits_data.size / 7.0)).round(3)
            commits_per_deployment = commits_data.size.to_f / deployments.size

            # Normalize: prefer frequent small deployments
            frequency_score = [deployments_per_week, 5.0].min / 5.0
            batch_size_score = [20.0 / [commits_per_deployment, 1.0].max, 1.0].min

            ((frequency_score + batch_size_score) / 2).round(3)
          end

          def data_points_description
            'deployments'
          end
        end
      end
    end
  end
end
