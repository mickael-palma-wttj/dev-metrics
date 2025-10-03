#!/usr/bin/env ruby

require 'ostruct'
require_relative 'lib/dev_metrics'

repository_path = "../../WTTJ/employer-branding"
repository = OpenStruct.new(path: repository_path, name: 'employer-branding')

# Create a time period for last 90 days to ensure we catch tags
time_period = DevMetrics::Models::TimePeriod.new(90, Time.now)

puts "=== Time Period ==="
puts "Start: #{time_period.start_date}"
puts "End: #{time_period.end_date}"
puts "Git since format: #{time_period.git_since_format}"

collector = DevMetrics::Collectors::GitCollector.new(repository, {})

puts "\n=== Testing collect_data directly ==="
data = {
  tags: collector.collect_tags,
  commits: collector.collect_commits(time_period),
  branches: collector.collect_branches
}

puts "Tags collected: #{data[:tags].size}"
puts "Commits collected: #{data[:commits].size}"
puts "Branches collected: #{data[:branches].size}"

puts "\n=== Sample branches (first 3) ==="
data[:branches].first(3).each_with_index do |branch, i|
  puts "  #{i+1}. #{branch.inspect}"
end

puts "\n=== Sample tags (first 5) ==="
data[:tags].first(5).each_with_index do |tag, i|
  puts "  #{i+1}. #{tag[:name]} - #{tag[:date]}"
end

puts "\n=== Creating deployment frequency metric ==="
metric = DevMetrics::Metrics::Git::Flow::DeploymentFrequency.new(repository, time_period, {})

# Test compute_metric directly with our data
puts "\n=== Testing compute_metric directly ==="
begin
  result = metric.send(:compute_metric, data)
  puts "Result keys: #{result.keys}"
  puts "Overall: #{result[:overall]}"
  puts "Deployments found: #{result[:deployments]&.size || 0}"
  if result[:deployments]&.any?
    puts "First deployment: #{result[:deployments].first}"
  end
rescue => e
  puts "Error in compute_metric: #{e.message}"
  puts e.backtrace.first(5)
end