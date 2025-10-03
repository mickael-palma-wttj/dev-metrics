# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module Reliability
        # Analyzes the ratio of bugfix commits to identify code quality patterns
        class BugfixRatio < BaseMetric
          def metric_name
            'bugfix_ratio'
          end

          def description
            'Analyzes the proportion of commits that are bugfixes vs feature development'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commits(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            # Categorize commits
            categorized_commits = categorize_commits(commits_data)

            # Calculate ratios by author
            author_stats = calculate_author_bugfix_stats(commits_data, categorized_commits)

            # Calculate overall metrics
            total_commits = commits_data.size
            bugfix_commits = categorized_commits[:bugfix].size
            feature_commits = categorized_commits[:feature].size
            maintenance_commits = categorized_commits[:maintenance].size

            {
              overall: {
                total_commits: total_commits,
                bugfix_commits: bugfix_commits,
                feature_commits: feature_commits,
                maintenance_commits: maintenance_commits,
                bugfix_ratio: calculate_ratio(bugfix_commits, total_commits),
                feature_ratio: calculate_ratio(feature_commits, total_commits),
                maintenance_ratio: calculate_ratio(maintenance_commits, total_commits),
                quality_score: calculate_quality_score(bugfix_commits, feature_commits),
              },
              by_author: author_stats,
              commit_categories: {
                bugfix: categorized_commits[:bugfix].first(10),
                feature: categorized_commits[:feature].first(10),
                maintenance: categorized_commits[:maintenance].first(10),
              },
              time_patterns: analyze_bugfix_patterns(categorized_commits[:bugfix]),
            }
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            overall = result[:overall]

            super.merge(
              bugfix_ratio: overall[:bugfix_ratio],
              quality_score: overall[:quality_score],
              high_bugfix_authors: count_high_bugfix_authors(result[:by_author]),
              most_reliable_author: find_most_reliable_author(result[:by_author]),
              bugfix_trend: calculate_bugfix_trend(result[:time_patterns])
            )
          end

          private

          def categorize_commits(commits_data)
            categories = {
              bugfix: [],
              feature: [],
              maintenance: [],
              other: [],
            }

            commits_data.each do |commit|
              message = commit[:message].downcase.strip
              category = classify_commit_message(message)
              categories[category] << commit
            end

            categories
          end

          def classify_commit_message(message)
            # Bugfix patterns
            bugfix_patterns = [
              /^fix\b/,
              /^bugfix/,
              /\bfix\s+(bug|issue|error|problem)/,
              /\b(bug|error|issue)\s+fix/,
              /\bresol(ve|ution)\b/,
              /\bhotfix/,
              /\bpatch/,
              /\bcorrect/,
              /\brepair/,
              /\bhandle\s+(error|exception)/,
            ]

            # Feature patterns
            feature_patterns = [
              /^feat\b/,
              /^feature/,
              /^add\b/,
              /^implement/,
              /^create/,
              /^new\s+/,
              /\benhance/,
              /\bimprove/,
              /\bupgrade/,
              /\bextend/,
            ]

            # Maintenance patterns
            maintenance_patterns = [
              /^refactor/,
              /^clean/,
              /^update/,
              /^chore/,
              /^style/,
              /^format/,
              /^lint/,
              /^test/,
              /^spec/,
              /\bdocument/,
              /\bcomment/,
              /\btypo/,
              /\bwhitespace/,
              /\breorg/,
              /\bmove\s/,
              /\brename/,
            ]

            return :bugfix if bugfix_patterns.any? { |pattern| message.match?(pattern) }
            return :feature if feature_patterns.any? { |pattern| message.match?(pattern) }
            return :maintenance if maintenance_patterns.any? { |pattern| message.match?(pattern) }

            :other
          end

          def calculate_author_bugfix_stats(commits_data, categorized_commits)
            stats = Hash.new do |h, k|
              h[k] = {
                total_commits: 0,
                bugfix_commits: 0,
                feature_commits: 0,
                maintenance_commits: 0,
                bugfix_ratio: 0.0,
                feature_ratio: 0.0,
                quality_score: 1.0,
              }
            end

            # Count commits by author and category
            commits_data.each do |commit|
              author = commit[:author]
              stats[author][:total_commits] += 1
            end

            categorized_commits.each do |category, commits|
              commits.each do |commit|
                author = commit[:author]
                case category
                when :bugfix
                  stats[author][:bugfix_commits] += 1
                when :feature
                  stats[author][:feature_commits] += 1
                when :maintenance
                  stats[author][:maintenance_commits] += 1
                end
              end
            end

            # Calculate ratios and scores
            stats.each_value do |data|
              total = data[:total_commits]
              next if total.zero?

              data[:bugfix_ratio] = calculate_ratio(data[:bugfix_commits], total)
              data[:feature_ratio] = calculate_ratio(data[:feature_commits], total)
              data[:quality_score] = calculate_quality_score(data[:bugfix_commits], data[:feature_commits])
            end

            stats.sort_by { |_, data| -data[:bugfix_ratio] }.to_h
          end

          def analyze_bugfix_patterns(bugfix_commits)
            return {} if bugfix_commits.empty?

            by_hour = Hash.new(0)
            by_day = Hash.new(0)
            by_month = Hash.new(0)

            bugfix_commits.each do |commit|
              time = commit[:date]
              by_hour[time.hour] += 1
              by_day[time.strftime('%A')] += 1
              by_month[time.strftime('%Y-%m')] += 1
            end

            {
              by_hour_of_day: by_hour,
              by_day_of_week: by_day,
              by_month: by_month,
              peak_bugfix_hour: by_hour.max_by { |_, count| count }&.first,
              peak_bugfix_day: by_day.max_by { |_, count| count }&.first,
              urgency_indicators: identify_urgency_patterns(bugfix_commits),
            }
          end

          def identify_urgency_patterns(bugfix_commits)
            urgent_keywords = %w[urgent critical hotfix emergency immediate asap]
            severity_keywords = %w[critical major minor trivial blocker]

            urgency_counts = Hash.new(0)
            severity_counts = Hash.new(0)

            bugfix_commits.each do |commit|
              message = commit[:message].downcase

              urgent_keywords.each do |keyword|
                urgency_counts[keyword] += 1 if message.include?(keyword)
              end

              severity_keywords.each do |keyword|
                severity_counts[keyword] += 1 if message.include?(keyword)
              end
            end

            {
              urgency_keywords: urgency_counts,
              severity_keywords: severity_counts,
              urgent_fixes: urgency_counts.values.sum,
              urgent_ratio: calculate_ratio(urgency_counts.values.sum, bugfix_commits.size),
            }
          end

          def calculate_ratio(count, total)
            return 0.0 if total.zero?

            (count.to_f / total * 100).round(2)
          end

          def calculate_quality_score(bugfix_commits, feature_commits)
            total_productive = bugfix_commits + feature_commits
            return 1.0 if total_productive.zero?

            # Higher feature ratio = higher quality score
            feature_ratio = feature_commits.to_f / total_productive
            [feature_ratio, 0.0].max.round(3)
          end

          def count_high_bugfix_authors(author_stats)
            author_stats.count { |_, stats| stats[:bugfix_ratio] > 30.0 }
          end

          def find_most_reliable_author(author_stats)
            return nil if author_stats.empty?

            author_stats.max_by { |_, stats| stats[:quality_score] }&.first
          end

          def calculate_bugfix_trend(time_patterns)
            return 0 if time_patterns.empty? || !time_patterns[:by_month]

            monthly_data = time_patterns[:by_month]
            return 0 if monthly_data.size < 2

            # Calculate simple trend (positive = increasing bugfixes)
            months = monthly_data.keys.sort
            first_half = months.first(months.size / 2)
            second_half = months.last(months.size / 2)

            first_avg = first_half.sum { |month| monthly_data[month] } / first_half.size.to_f
            second_avg = second_half.sum { |month| monthly_data[month] } / second_half.size.to_f

            return 0 if first_avg.zero?

            ((second_avg - first_avg) / first_avg * 100).round(1)
          end
        end
      end
    end
  end
end
