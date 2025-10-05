# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for calculating change metrics from aggregated author data
    class ChangeMetricsCalculator
      def initialize(author_data)
        @author_data = author_data
      end

      def calculate
        author_stats = create_author_stats
        totals = calculate_totals

        ValueObjects::ChangeMetrics.new(
          author_stats: author_stats,
          total_additions: totals[:additions],
          total_deletions: totals[:deletions],
          contributing_authors: author_stats.size
        )
      end

      private

      def create_author_stats
        @author_data.map do |author|
          name_parts = parse_author_name(author[:name])
          ValueObjects::AuthorChangeStats.new(
            author_name: name_parts[:name],
            author_email: name_parts[:email],
            additions: author[:additions],
            deletions: author[:deletions],
            commits: author[:commits]
          )
        end
      end

      def parse_author_name(name_with_email)
        if name_with_email.include?('<') && name_with_email.include?('>')
          match = name_with_email.match(/(.+?)\s*<(.+?)>/)
          { name: match[1].strip, email: match[2].strip }
        else
          { name: name_with_email, email: nil }
        end
      end

      def calculate_totals
        @author_data.each_with_object({ additions: 0, deletions: 0 }) do |author, totals|
          totals[:additions] += author[:additions]
          totals[:deletions] += author[:deletions]
        end
      end
    end
  end
end
