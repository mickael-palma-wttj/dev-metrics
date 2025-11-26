# frozen_string_literal: true

module DevMetrics
  module Services
    # Provides descriptions and tooltips for all metrics
    class MetricDescriptions
      DESCRIPTIONS = {
        commits_per_developer: {
          title: 'Commits per Developer',
          description: 'Measures how many commits each developer has contributed to the repository',
        },
        commit_size: {
          title: 'Commit Size',
          description: 'Analyzes the distribution of commit sizes by number of lines changed, helping identify unusually large commits',
        },
        commit_frequency: {
          title: 'Commit Frequency',
          description: 'Shows how often commits are made, revealing development velocity and activity patterns',
        },
        lines_changed: {
          title: 'Lines Changed',
          description: 'Tracks the total number of lines added, removed, or modified across all commits',
        },
        file_churn: {
          title: 'File Churn',
          description: 'Identifies files that are frequently modified, which may indicate instability or active development areas',
        },
        authors_per_file: {
          title: 'Authors per File',
          description: 'Shows how many different developers have modified each file, indicating shared ownership',
        },
        file_ownership: {
          title: 'File Ownership',
          description: 'Determines primary ownership of files based on contribution history',
        },
        co_change_pairs: {
          title: 'Co-Change Pairs',
          description: 'Identifies files that are frequently modified together, revealing coupling between components',
        },
        revert_rate: {
          title: 'Revert Rate',
          description: 'Measures the percentage of commits that are reverted, indicating code quality or rework issues',
        },
        bugfix_ratio: {
          title: 'Bugfix Ratio',
          description: 'Shows the proportion of commits identified as bug fixes versus feature commits',
        },
        large_commits: {
          title: 'Large Commits',
          description: 'Identifies and analyzes commits that exceed typical size thresholds',
        },
        lead_time: {
          title: 'Lead Time',
          description: 'Measures the time from code changes to deployment, indicating development agility',
        },
        deployment_frequency: {
          title: 'Deployment Frequency',
          description: 'Tracks how often deployments occur and deployment patterns over time',
        },
      }.freeze

      VALUE_DESCRIPTIONS = {
        avg_commits: 'Average number of commits per developer',
        max_commits: 'Developer with the most commits',
        small_commits: 'Number of commits with minimal changes (best practice)',
        medium_commits: 'Number of commits with moderate changes',
        large_commits: 'Number of commits exceeding size thresholds (review for complexity)',
        avg_files_per_commit: 'Average number of files modified per commit',
        avg_lines_per_commit: 'Average number of lines changed per commit',
        peak_hour: 'Time of day with most commits',
        busiest_day: 'Day of week with most commits',
        most_changed_file: 'File with the highest modification rate',
        churn_percentage: 'Percentage of lines changed relative to total',
        single_author_files: 'Files owned by a single developer (risk factor)',
        multi_author_files: 'Files with shared ownership',
        avg_authors_per_file: 'Average number of authors per file',
        high_coupling_pairs: 'File pairs that change together frequently',
        avg_revert_rate: 'Percentage of commits that were reverted',
        avg_lead_time_days: 'Average days from commit to deployment',
        max_lead_time_days: 'Longest time between commit and deployment',
        avg_interval_days: 'Average number of days between deployments',
        std_deviation_days: 'Standard deviation of deployment intervals',
        deployment_stability: 'Consistency of deployment frequency',
        deployment_trend: 'Direction and pace of deployment frequency change',
        avg_bugfix_ratio: 'Percentage of commits classified as bug fixes',
      }.freeze

      def self.get_description(metric_name)
        DESCRIPTIONS[metric_name.to_sym] || { title: metric_name.to_s.titleize,
                                              description: 'No description available', }
      end

      def self.get_value_description(value_key)
        VALUE_DESCRIPTIONS[value_key.to_sym] || nil
      end

      def self.description_for_metric(metric_name)
        DESCRIPTIONS[metric_name.to_sym]&.fetch(:description, '')
      end

      def self.title_for_metric(metric_name)
        DESCRIPTIONS[metric_name.to_sym]&.fetch(:title, metric_name.to_s.titleize)
      end

      def self.get_section_description(section_title)
        section_descriptions[section_title.to_sym] || nil
      end

      def self.section_descriptions
        {
          'Overall Classification': 'Breakdown of total commits classified as bugfixes versus features',
          'Overall Statistics': 'High-level metrics summarizing the overall analysis results',
          'Revert Statistics by Author': 'Breakdown of revert activity and reliability scores for each contributor',
          'Recent Reverts': 'List of the most recent reverted commits with details',
          'Revert Reasons': 'Categorized breakdown of reasons why commits were reverted',
          'Revert Pattern by Hour of Day': 'Distribution of reverts by time of day to identify patterns',
          'Revert Pattern by Day of Week': 'Distribution of reverts across days of the week',
          'Bottleneck Analysis': 'Identification of lead time bottlenecks and process slowdowns',
          'Overall Metrics': 'Core lead time metrics and statistics',
          'Author Performance': 'Lead time metrics broken down by individual developers',
          'Lead Time Distribution': 'Statistical distribution of lead times',
          Trends: 'Historical trends in lead time over time',
          'Recent Production Releases': 'Latest production deployments',
          'Deployment Metrics': 'Core deployment frequency and interval metrics',
          'Recent Deployments': 'Latest deployments with details',
          'Deployment Patterns': 'Analysis of deployment timing and frequency patterns',
          'Deployment Stability': 'Consistency and reliability of deployment processes',
          'Deployment Trends': 'Trends in deployment frequency and patterns over time',
          'Daily Activity': 'Commit activity patterns by day',
          'Hourly Distribution': 'Commit activity heatmap by hour of day',
          'Work Pattern': 'Distribution of commits across working and off hours',
          'Commits by Author': 'Commit frequency metrics by developer',
          'Bugfix Ratio by Author': 'Bugfix percentage and quality metrics per developer',
          'Bugfix Distribution by File': 'Files with the most bugfix commits',
          'Size Thresholds': 'Configured thresholds for commit size categories',
          'Largest Commits': 'The biggest commits by line count',
          'Large Commits by Author': 'Developers with the most large commits',
          'Files with Large Commits': 'Files frequently modified with large commits',
          'Trends Over Time': 'Historical trends and changes in metrics over time periods',
          'Distribution by Author': 'Breakdown of metrics or activity for each team member',
          'Bugfix Distribution': 'Analysis of bug fix frequency and patterns',
          'Deployment Timeline': 'Timeline of deployments with frequency and interval metrics',
          'Lead Time by Author': 'Average lead time for code changes by developer',
          'Time Patterns': 'Activity patterns analyzed by hour of day and day of week',
          'Quality Metrics': 'Overall quality and stability metrics',
        }
      end
    end
  end
end
