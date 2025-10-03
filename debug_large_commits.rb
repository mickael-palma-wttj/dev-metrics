#!/usr/bin/env ruby

require 'ostruct'
require_relative 'lib/dev_metrics'

repository_path = "../../WTTJ/employer-branding"
repository = OpenStruct.new(path: repository_path, name: 'employer-branding')

# Create a time period for last 30 days
time_period = DevMetrics::Models::TimePeriod.new(30, Time.now)

puts "=== Testing large_commits metric ==="

# Test GitCollector.collect_commit_stats directly
collector = DevMetrics::Collectors::GitCollector.new(repository, {})

puts "Testing collect_commit_stats..."
begin
  commit_stats = collector.collect_commit_stats(time_period)
  puts "Commit stats collected: #{commit_stats.size}"
  
  if commit_stats.any?
    puts "First commit stat: #{commit_stats.first.inspect}"
  end
rescue => e
  puts "Error in collect_commit_stats: #{e.message}"
  puts e.backtrace.first(3)
end

puts "\n=== Testing large_commits metric directly ==="
begin
  metric = DevMetrics::Metrics::Git::Reliability::LargeCommits.new(repository, time_period, {})
  result = metric.calculate
  
  puts "Metric result success?: #{result.success?}"
  if result.success?
    puts "Metric value class: #{result.value.class}"
    puts "Metric value keys: #{result.value.keys}" if result.value.is_a?(Hash)
    if result.value.is_a?(Hash) && result.value[:overall]
      puts "Overall stats: #{result.value[:overall]}"
    end
  else
    puts "Metric error: #{result.error}"
  end
rescue => e
  puts "Error in large_commits metric: #{e.message}"
  puts e.backtrace.first(5)
end