# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for calculating lead times from commits to production releases
    class LeadTimeCalculator
      def initialize(commits_data, production_releases)
        @commits_data = commits_data
        @production_releases = production_releases
      end

      def calculate
        return [] if production_releases.empty?

        commits_data.filter_map do |commit|
          calculate_commit_lead_time(commit)
        end
      end

      private

      attr_reader :commits_data, :production_releases

      def calculate_commit_lead_time(commit)
        next_release = find_next_release(commit[:date])
        return nil unless next_release

        lead_time_hours = calculate_hours_difference(commit[:date], next_release[:date])

        ValueObjects::CommitLeadTime.new(
          hash: commit[:hash],
          author: commit[:author_name],
          message: commit[:message] || commit[:subject] || '',
          date: commit[:date],
          lead_time_hours: lead_time_hours,
          lead_time_days: (lead_time_hours / 24).round(2),
          deployed_in_release: next_release[:name] || next_release[:tag_name],
          deployment_date: next_release[:date]
        )
      end

      def find_next_release(commit_time)
        production_releases.find { |release| release[:date] > commit_time }
      end

      def calculate_hours_difference(start_time, end_time)
        ((end_time - start_time) / 3600).round(2)
      end
    end
  end
end
