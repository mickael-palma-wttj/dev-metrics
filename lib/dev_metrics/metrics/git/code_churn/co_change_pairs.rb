# frozen_string_literal: true

module DevMetrics
  module Metrics
    module Git
      module CodeChurn
        # Identifies files that are frequently changed together
        class CoChangePairs < BaseMetric
          def metric_name
            'co_change_pairs'
          end

          def description
            'Files that are frequently modified together, indicating coupling'
          end

          protected

          def collect_data
            collector = Collectors::GitCollector.new(repository, options)
            collector.collect_commit_stats(time_period)
          end

          def compute_metric(commits_data)
            return {} if commits_data.empty?

            # Count file co-occurrences in commits
            co_change_counts = Hash.new(0)
            file_commit_counts = Hash.new(0)

            commits_data.each do |commit|
              files = commit[:files_changed].map { |f| f[:filename] }.sort

              # Count individual file changes
              files.each { |file| file_commit_counts[file] += 1 }

              # Count pairs of files changed together
              files.combination(2).each do |file1, file2|
                pair_key = [file1, file2].sort.join(' <-> ')
                co_change_counts[pair_key] += 1
              end
            end

            # Calculate coupling metrics
            result = {}
            co_change_counts.each do |pair_key, co_change_count|
              file1, file2 = pair_key.split(' <-> ')

              file1_total = file_commit_counts[file1]
              file2_total = file_commit_counts[file2]

              # Calculate coupling strength
              coupling_strength = calculate_coupling_strength(co_change_count, file1_total, file2_total)

              result[pair_key] = {
                file1: file1,
                file2: file2,
                co_changes: co_change_count,
                file1_total_changes: file1_total,
                file2_total_changes: file2_total,
                coupling_strength: coupling_strength,
                coupling_percentage: (co_change_count.to_f / [file1_total, file2_total].min * 100).round(1),
                coupling_category: categorize_coupling(coupling_strength),
              }
            end

            # Sort by coupling strength (strongest first)
            result.sort_by { |_, stats| -stats[:coupling_strength] }.to_h
          end

          def build_metadata(commits_data)
            return super if commits_data.empty?

            result = compute_metric(commits_data)

            coupling_strengths = result.values.map { |s| s[:coupling_strength] }

            super.merge(
              total_file_pairs: result.size,
              avg_coupling_strength: coupling_strengths.empty? ? 0 : (coupling_strengths.sum.to_f / coupling_strengths.size).round(3),
              max_coupling_strength: coupling_strengths.max || 0,
              high_coupling_pairs: result.count { |_, s| s[:coupling_strength] > 0.5 },
              medium_coupling_pairs: result.count do |_, s|
                s[:coupling_strength] > 0.2 && s[:coupling_strength] <= 0.5
              end,
              low_coupling_pairs: result.count { |_, s| s[:coupling_strength] <= 0.2 },
              architectural_hotspots: identify_architectural_hotspots(result)
            )
          end

          private

          def calculate_coupling_strength(co_changes, file1_total, file2_total)
            return 0 if file1_total.zero? || file2_total.zero?

            # Jaccard similarity coefficient: intersection / union
            union = file1_total + file2_total - co_changes
            return 0 if union.zero?

            (co_changes.to_f / union).round(3)
          end

          def categorize_coupling(strength)
            case strength
            when 0.5..1.0
              'HIGH'
            when 0.2..0.5
              'MEDIUM'
            when 0.1..0.2
              'LOW'
            else
              'MINIMAL'
            end
          end

          def identify_architectural_hotspots(result)
            # Find files that appear in multiple high-coupling relationships
            file_coupling_counts = Hash.new(0)

            result.each_value do |stats|
              next unless stats[:coupling_strength] > 0.3

              file_coupling_counts[stats[:file1]] += 1
              file_coupling_counts[stats[:file2]] += 1
            end

            # Return files that are highly coupled with multiple other files
            hotspots = file_coupling_counts.select { |_, count| count >= 3 }
            hotspots.sort_by { |_, count| -count }.to_h
          end
        end
      end
    end
  end
end
