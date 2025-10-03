#!/usr/bin/env ruby

require 'ostruct'
require_relative 'lib/dev_metrics'

repository_path = "../../WTTJ/employer-branding"
repository = OpenStruct.new(path: repository_path)
collector = DevMetrics::Collectors::GitCollector.new(repository, {})

puts "=== Testing GitCollector.collect_tags ==="
tags = collector.collect_tags
puts "Total tags collected: #{tags.size}"
puts "First 5 tags:"
tags.first(5).each_with_index do |tag, i|
  puts "  #{i+1}. #{tag.inspect}"
end

puts "\n=== Testing production tag patterns ==="
production_patterns = [
  /^v?\d+\.\d+\.\d+$/,
  /^release[-_]v?\d+\.\d+/,
  /^prod[-_]/i,
  /^production[-_]/i,
  /[-_]prod$/i,
  /[-_]release$/i,
  /^deploy[-_]/i,
  /[-_]deploy$/i,
  /^v\d{4}\.\d{2}\.\d{2}(\.\d+)?$/,        # v2025.10.02, v2025.09.01.1
  /^v\d{8}(\.\d+)?$/,                      # v20250630, v20250123.2
  /^v\d{8}[-_]\d+$/,                       # v20241024_1, v20240109-1
  /^v\d+$/                                 # v31, v30, v29, etc.
]

matching_tags = tags.select do |tag|
  tag_name = tag[:name] || tag[:tag_name] || ''
  production_patterns.any? { |pattern| tag_name.match?(pattern) }
end

puts "Tags matching production patterns: #{matching_tags.size}"
matching_tags.first(10).each_with_index do |tag, i|
  puts "  #{i+1}. #{tag.inspect}"
end

puts "\n=== Testing deployment_frequency directly ==="
metric = DevMetrics::Metrics::Git::Flow::DeploymentFrequency.new(repository, nil, {})
result = metric.calculate

puts "Result class: #{result.class}"
puts "Result success?: #{result.success?}"
if result.success?
  puts "Result value class: #{result.value.class}"
  if result.value.is_a?(Hash)
    puts "Result value keys: #{result.value.keys}"
    puts "Overall: #{result.value[:overall]}"
    puts "Deployments: #{result.value[:deployments]&.size || 0}"
  else
    puts "Result value: #{result.value}"
  end
else
  puts "Result error: #{result.error}"
end