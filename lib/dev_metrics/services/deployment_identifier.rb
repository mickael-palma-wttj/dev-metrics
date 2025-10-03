# frozen_string_literal: true

module DevMetrics
  module Services
    # Service class for identifying different types of deployments from git data
    class DeploymentIdentifier
      def initialize(tags_data, commits_data, branches_data)
        @tags_data = tags_data
        @commits_data = commits_data
        @branches_data = branches_data
      end

      def identify_deployments
        # Production releases from tags
        production_tags = identify_production_tags
        deployments = production_tags.map do |tag|
          {
            type: 'production_release',
            identifier: tag[:name] || tag[:tag_name],
            date: tag[:date],
            commit_hash: tag[:commit_hash],
            deployment_method: 'tag',
          }
        end

        # Merge commits to main/master (potential deployments)
        main_merges = identify_main_branch_merges
        main_merges.each do |commit|
          deployments << {
            type: 'merge_deployment',
            identifier: commit[:hash][0..7],
            date: commit[:date],
            commit_hash: commit[:hash],
            deployment_method: 'merge',
            message: commit[:message],
          }
        end

        # Remove duplicates and sort by date
        unique_deployments = remove_duplicate_deployments(deployments)
        unique_deployments.sort_by { |d| d[:date] }.reverse
      end

      private

      attr_reader :tags_data, :commits_data, :branches_data

      def identify_production_tags
        Utils::ProductionTagPatterns.filter_production_tags(tags_data)
      end

      def identify_main_branch_merges
        main_branch_names = %w[main master production prod]

        # branches_data is an array of strings, not hashes with :current key
        # Look for main branch patterns in the branch names
        current_branch = branches_data.find do |branch|
          main_branch_names.any? { |main_name| branch.include?(main_name) }
        end || 'main'

        # Include current branch if it looks like a main branch
        main_branch_names << current_branch unless main_branch_names.include?(current_branch)

        merge_patterns = [
          /^Merge pull request/i,
          /^Merge branch/i,
          /^Merge remote-tracking branch/i,
          /^Merged in/i,
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

        deployments_by_date.each_value do |day_deployments|
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
    end
  end
end
