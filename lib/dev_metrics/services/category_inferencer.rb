# frozen_string_literal: true

module DevMetrics
  module Services
    # Service for categorizing metrics based on their names
    class CategoryInferencer
      CATEGORY_PATTERNS = {
        'commit_activity' => [
          /commit.*activity/, /commits.*per/, /commit.*size/, /commit.*frequency/,
        ],
        'code_churn' => [
          /churn/, /authors.*per.*file/, /ownership/, /co.*change/,
        ],
        'reliability' => [
          /revert/, /bugfix/, /large.*commit/,
        ],
        'flow' => [
          /lead.*time/, /deployment/,
        ],
        'pr_throughput' => [
          /pr.*/, /pull.*request/,
        ],
        'review_collaboration' => [
          /review/,
        ],
        'knowledge' => [
          /cross.*repo/, /critical.*file/,
        ],
        'team_health' => [
          /off.*hours/, /pickup/, /change.*failure/, /mttr/,
        ],
      }.freeze

      def self.infer(metric_name)
        new(metric_name).infer
      end

      def initialize(metric_name)
        @metric_name = metric_name.downcase
      end

      def infer
        CATEGORY_PATTERNS.each do |category, patterns|
          return category if patterns.any? { |pattern| @metric_name.match?(pattern) }
        end
        'other'
      end
    end
  end
end
