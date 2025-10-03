#!/usr/bin/env ruby

require 'ostruct'
require_relative 'lib/dev_metrics'

repository_path = "../../WTTJ/employer-branding"
repository = OpenStruct.new(path: repository_path, name: 'employer-branding')

collector = DevMetrics::Collectors::GitCollector.new(repository, {})

puts "=== Testing shared ProductionTagPatterns module ==="
all_tags = collector.collect_tags
puts "Total tags collected: #{all_tags.size}"

# Test the new shared module
matching_tags = DevMetrics::Utils::ProductionTagPatterns.filter_production_tags(all_tags)
puts "Tags matching production patterns: #{matching_tags.size}"

# Find the alpha tag specifically
alpha_tag = all_tags.find { |tag| tag[:name].include?('alpha') }
if alpha_tag
  puts "\nAlpha tag found: #{alpha_tag[:name]}"
  puts "Is production tag?: #{DevMetrics::Utils::ProductionTagPatterns.production_tag?(alpha_tag[:name])}"
else
  puts "\nNo alpha tag found"
end

# Test both metrics use the same patterns
puts "\n=== Testing both metrics use shared patterns ==="
time_period = DevMetrics::Models::TimePeriod.new(90, Time.now)

# Test deployment frequency
df_metric = DevMetrics::Metrics::Git::Flow::DeploymentFrequency.new(repository, time_period, {})
df_result = df_metric.calculate

# Test lead time
lt_metric = DevMetrics::Metrics::Git::Flow::LeadTime.new(repository, time_period, {})
lt_result = lt_metric.calculate

puts "Deployment frequency result: #{df_result.success? ? 'Success' : 'Failed'}"
puts "Lead time result: #{lt_result.success? ? 'Success' : 'Failed'}"

if df_result.success?
  puts "Deployment frequency deployments: #{df_result.value[:deployments]&.size || 0}"
end

if lt_result.success?
  puts "Lead time production releases: #{lt_result.value[:production_releases]&.size || 0}"
end