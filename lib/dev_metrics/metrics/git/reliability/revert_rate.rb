module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes the rate of reverted commits and problematic changes
        class RevertRate < DevMetrics::BaseMetric
          def metric_name
            'revert_rate'
          end

          def description
            'Analyzes commit revert patterns to identify code quality issues'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commits(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            # Identify revert commits
            revert_commits = identify_revert_commits(commits_data)

            # Identify reverted commits
            reverted_commits = identify_reverted_commits(commits_data, revert_commits)

            # Calculate revert statistics by author
            author_stats = calculate_author_revert_stats(commits_data, revert_commits, reverted_commits)

            # Calculate overall metrics
            total_commits = commits_data.size
            total_reverts = revert_commits.size
            total_reverted = reverted_commits.size

            {
              overall: {
                total_commits: total_commits,
                revert_commits: total_reverts,
                reverted_commits: total_reverted,
                revert_rate: calculate_rate(total_reverts, total_commits),
                reverted_rate: calculate_rate(total_reverted, total_commits),
                stability_score: calculate_stability_score(total_reverted, total_commits)
              },
              by_author: author_stats,
              revert_details: build_revert_details(revert_commits, reverted_commits),
              time_patterns: analyze_revert_patterns(revert_commits)
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            overall = result[:overall]

            super.merge(
              total_commits: overall[:total_commits],
              revert_rate: overall[:revert_rate],
              stability_score: overall[:stability_score],
              high_risk_authors: count_high_risk_authors(result[:by_author]),
              most_reverted_author: find_most_reverted_author(result[:by_author]),
              revert_frequency: calculate_revert_frequency(result[:revert_details])
            )
          end

          private

          def identify_revert_commits(commits_data)
            revert_patterns = [
              /^Revert\s+/i,
              /^This reverts commit/i,
              /reverts?\s+commit/i,
              /^Rollback/i,
              /^Undo\s+/i
            ]

            commits_data.select do |commit|
              message = commit[:message].strip
              revert_patterns.any? { |pattern| message.match?(pattern) }
            end
          end

          def identify_reverted_commits(commits_data, revert_commits)
            reverted_hashes = Set.new

            revert_commits.each do |revert_commit|
              # Extract commit hash from revert message
              hash_match = revert_commit[:message].match(/([a-f0-9]{7,40})/i)
              reverted_hashes.add(hash_match[1].downcase) if hash_match
            end

            commits_data.select do |commit|
              reverted_hashes.include?(commit[:hash][0..6].downcase) ||
                reverted_hashes.include?(commit[:hash].downcase)
            end
          end

          def calculate_author_revert_stats(commits_data, revert_commits, reverted_commits)
            stats = Hash.new do |h, k|
              h[k] = {
                total_commits: 0,
                reverts_made: 0,
                commits_reverted: 0,
                revert_rate: 0.0,
                reverted_rate: 0.0,
                reliability_score: 1.0
              }
            end

            # Count total commits per author
            commits_data.each do |commit|
              author = commit[:author]
              stats[author][:total_commits] += 1
            end

            # Count reverts made by each author
            revert_commits.each do |commit|
              author = commit[:author]
              stats[author][:reverts_made] += 1
            end

            # Count commits reverted for each author
            reverted_commits.each do |commit|
              author = commit[:author]
              stats[author][:commits_reverted] += 1
            end

            # Calculate rates and scores
            stats.each do |author, data|
              total = data[:total_commits]
              next if total == 0

              data[:revert_rate] = calculate_rate(data[:reverts_made], total)
              data[:reverted_rate] = calculate_rate(data[:commits_reverted], total)
              data[:reliability_score] = calculate_reliability_score(data[:commits_reverted], total)
            end

            stats.sort_by { |_, data| -data[:reverted_rate] }.to_h
          end

          def build_revert_details(revert_commits, reverted_commits)
            {
              recent_reverts: revert_commits.first(10),
              recent_reverted: reverted_commits.first(10),
              revert_reasons: categorize_revert_reasons(revert_commits)
            }
          end

          def analyze_revert_patterns(revert_commits)
            return {} if revert_commits.empty?

            by_hour = Hash.new(0)
            by_day = Hash.new(0)

            revert_commits.each do |commit|
              time = commit[:date]
              by_hour[time.hour] += 1
              by_day[time.strftime('%A')] += 1
            end

            {
              by_hour_of_day: by_hour,
              by_day_of_week: by_day,
              peak_revert_hour: by_hour.max_by { |_, count| count }&.first,
              peak_revert_day: by_day.max_by { |_, count| count }&.first
            }
          end

          def categorize_revert_reasons(revert_commits)
            categories = Hash.new(0)

            revert_commits.each do |commit|
              message = commit[:message].downcase

              case message
              when /bug|error|fix|issue|problem/
                categories['Bug fixes'] += 1
              when /test|spec|failing/
                categories['Test issues'] += 1
              when /break|broken|regression/
                categories['Breaking changes'] += 1
              when /performance|slow|timeout/
                categories['Performance issues'] += 1
              when /security|vulnerability/
                categories['Security concerns'] += 1
              else
                categories['Other'] += 1
              end
            end

            categories
          end

          def calculate_rate(count, total)
            return 0.0 if total == 0

            (count.to_f / total * 100).round(2)
          end

          def calculate_stability_score(reverted_commits, total_commits)
            return 1.0 if total_commits == 0

            stability = 1.0 - (reverted_commits.to_f / total_commits)
            [stability, 0.0].max.round(3)
          end

          def calculate_reliability_score(reverted_commits, total_commits)
            return 1.0 if total_commits == 0

            reliability = 1.0 - (reverted_commits.to_f / total_commits)
            [reliability, 0.0].max.round(3)
          end

          def count_high_risk_authors(author_stats)
            author_stats.count { |_, stats| stats[:reverted_rate] > 5.0 }
          end

          def find_most_reverted_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:reverted_rate] }&.first
          end

          def calculate_revert_frequency(revert_details)
            recent_reverts = revert_details[:recent_reverts]
            return 0 if recent_reverts.empty?

            # Calculate average days between reverts
            dates = recent_reverts.map { |commit| commit[:date] }.sort
            return 0 if dates.size < 2

            intervals = dates.each_cons(2).map { |a, b| (b - a) / 86_400 } # days
            (intervals.sum / intervals.size).round(1)
          end
        end
      end
    end
  end
end
