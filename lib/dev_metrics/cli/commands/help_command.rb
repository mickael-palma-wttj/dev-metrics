# frozen_string_literal: true

module DevMetrics
  module CLI
    module Commands
      # Command for displaying help information
      class HelpCommand < BaseCommand
        def execute
          puts help_text
        end

        private

        def help_text
          <<~HELP
            Developer Metrics CLI

            USAGE:
              dev-metrics <command> [path] [options]

            COMMANDS:
              analyze [path]     Analyze repositories (single or multiple with --recursive/--interactive)
              scan [path]        Legacy alias for analyze (deprecated)
              report             Generate detailed reports
              config             Manage configuration
              help               Show this help message

            OPTIONS:
              --metrics=CATS     Comma-separated metric categories (default: all)
                                Available: git,all or specific metric names
              --categories=CATS  Git metric categories: commit_activity,code_churn,reliability,flow
              --format=FORMAT    Output format: text,json,csv,html,markdown (default: text)
              --output=FILE      Output file path (default: ./report/[auto-generated])
              --since=DATE       Start date (YYYY-MM-DD or relative like 30d)
              --until=DATE       End date (YYYY-MM-DD)
              --all-time         Analyze since the first commit in the repository
              --contributors=X   Focus on specific contributors (comma-separated)
              --interactive      Interactive repository selection
              --recursive        Scan subdirectories for repositories
              --analyze          Automatically run analysis on found/selected repositories
              --exclude-bots     Exclude bot accounts from analysis
              --exclude-merges   Exclude merge commits from analysis
              --no-progress      Disable progress indicators

            EXAMPLES:
              dev-metrics analyze .                                    # Single repository
              dev-metrics analyze /workspace --recursive               # All repositories in workspace
              dev-metrics analyze /workspace --interactive             # Interactive repository selection
              dev-metrics analyze . --all-time --format=json          # Single repo, all-time, JSON format
              dev-metrics analyze /workspace --recursive --all-time    # All repos, complete history
              dev-metrics analyze . --since=2024-01-01 --contributors=john.doe

            For more information, visit: https://github.com/your-username/dev-metrics-new
          HELP
        end
      end
    end
  end
end
