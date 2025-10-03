# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies the primary owner (last significant contributor) of each file
        class FileOwnership < BaseMetric
          def metric_name
            'file_ownership'
          end

          def description
            'Primary ownership and contribution distribution for each file'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            file_data = Hash.new { |h, k| h[k] = { commits: [], authors: Hash.new(0), total_changes: 0 } }

            # Collect all data for each file
            commits_data.each do |commit|
              commit[:files_changed].each do |file_change|
                filename = file_change[:filename]
                changes = file_change[:additions] + file_change[:deletions]

                file_data[filename][:commits] << {
                  author: commit[:author_name],
                  date: commit[:date],
                  changes: changes,
                  hash: commit[:hash],
                }

                file_data[filename][:authors][commit[:author_name]] += changes
                file_data[filename][:total_changes] += changes
              end
            end

            # Calculate ownership metrics for each file
            result = {}
            file_data.each do |filename, data|
              sorted_commits = data[:commits].sort_by { |c| c[:date] }
              last_commit = sorted_commits.last

              # Calculate ownership percentages
              author_percentages = {}
              data[:authors].each do |author, changes|
                percentage = (changes.to_f / data[:total_changes] * 100).round(1)
                author_percentages[author] = percentage
              end

              primary_owner = data[:authors].max_by { |_, changes| changes }

              result[filename] = {
                primary_owner: primary_owner[0],
                primary_owner_percentage: (primary_owner[1].to_f / data[:total_changes] * 100).round(1),
                last_modified_by: last_commit[:author],
                last_modified_date: last_commit[:date],
                total_commits: sorted_commits.size,
                total_changes: data[:total_changes],
                contributor_count: data[:authors].size,
                ownership_distribution: author_percentages.sort_by { |_, pct| -pct }.to_h,
                ownership_concentration: calculate_ownership_concentration(author_percentages),
                ownership_type: categorize_ownership_type(author_percentages),
              }
            end

            # Sort by ownership concentration (most concentrated first)
            result.sort_by { |_, stats| -stats[:ownership_concentration] }.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)
            concentrations = result.values.map { |s| s[:ownership_concentration] }

            super.merge(
              total_files_analyzed: result.size,
              avg_ownership_concentration: concentrations.sum.to_f / concentrations.size,
              highly_concentrated_files: result.count { |_, s| s[:ownership_concentration] > 80 },
              moderately_concentrated_files: result.count do |_, s|
                s[:ownership_concentration] > 50 && s[:ownership_concentration] <= 80
              end,
              distributed_ownership_files: result.count { |_, s| s[:ownership_concentration] <= 50 },
              single_owner_files: result.count { |_, s| s[:contributor_count] == 1 }
            )
          end

          private

          def calculate_ownership_concentration(author_percentages)
            return 100 if author_percentages.size <= 1

            # Calculate Herfindahl-Hirschman Index (HHI) for ownership concentration
            hhi = author_percentages.values.map { |pct| (pct / 100.0)**2 }.sum

            # Convert to 0-100 scale
            (hhi * 100).round(1)
          end

          def categorize_ownership_type(author_percentages)
            max_ownership = author_percentages.values.max || 0
            contributor_count = author_percentages.size

            if contributor_count == 1
              'SINGLE_OWNER'
            elsif max_ownership >= 80
              'DOMINANT_OWNER'
            elsif max_ownership >= 60
              'PRIMARY_OWNER'
            elsif max_ownership >= 40
              'SHARED_OWNERSHIP'
            else
              'DISTRIBUTED_OWNERSHIP'
            end
          end
        end
      end
    end
  end
end
