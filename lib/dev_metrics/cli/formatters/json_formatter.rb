module DevMetrics
  module CLI
    module Formatters
      class JsonFormatter < Base
        def format_results(results, metadata)
          {
            metadata: metadata,
            results: results.map(&:to_h),
            summary: Services::SummaryGenerator.generate(results)
          }.to_json
        end

        def format_analysis_results(results, summary)
          {
            summary: summary,
            results: transform_analysis_results(results)
          }.to_json
        end

        private

        def transform_analysis_results(results)
          results.transform_values do |data|
            {
              category: data[:metadata][:category],
              metric: data[:metric].to_h,
              execution_time: data[:metadata][:execution_time]
            }
          end
        end
      end
    end
  end
end
