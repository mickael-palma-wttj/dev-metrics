#!/usr/bin/env ruby

require 'ostruct'
require_relative 'lib/dev_metrics'

repository_path = "../../WTTJ/employer-branding"
repository = OpenStruct.new(path: repository_path, name: 'employer-branding')

collector = DevMetrics::Collectors::GitCollector.new(repository, {})

puts "=== All tags collected by GitCollector ==="
all_tags = collector.collect_tags
puts "Total tags collected: #{all_tags.size}"

puts "\n=== Production patterns ==="
production_patterns = [
  /^v?\d+\.\d+\.\d+$/,           # v1.2.3 or 1.2.3
  /^release[-_]v?\d+\.\d+/,     # release-v1.2 or release_1.2
  /^prod[-_]/i,                 # prod- or prod_
  /^production[-_]/i,           # production- or production_
  /[-_]prod$/i,                 # -prod or _prod
  /[-_]release$/i,              # -release or _release
  /^deploy[-_]/i,               # deploy- or deploy_
  /[-_]deploy$/i,               # -deploy or _deploy
  /^v\d{4}\.\d{2}\.\d{2}(\.\d+)?$/,        # v2025.10.02, v2025.09.01.1
  /^v\d{8}(\.\d+)?$/,                      # v20250630, v20250123.2
  /^v\d{8}[-_]\d+$/,                       # v20241024_1, v20240109-1
  /^v\d+$/                                 # v31, v30, v29, etc.
]

matching_tags = all_tags.select do |tag|
  tag_name = tag[:name] || tag[:tag_name] || ''
  production_patterns.any? { |pattern| tag_name.match?(pattern) }
end

non_matching_tags = all_tags.reject do |tag|
  tag_name = tag[:name] || tag[:tag_name] || ''
  production_patterns.any? { |pattern| tag_name.match?(pattern) }
end

puts "Tags matching production patterns: #{matching_tags.size}"
puts "Tags NOT matching production patterns: #{non_matching_tags.size}"

puts "\n=== Non-matching tags (first 10) ==="
non_matching_tags.first(10).each_with_index do |tag, i|
  puts "  #{i+1}. #{tag[:name]} (#{tag[:date]})"
end

if non_matching_tags.size > 10
  puts "  ... and #{non_matching_tags.size - 10} more"
end

puts "\n=== Sample of matching tags (first 10) ==="
matching_tags.first(10).each_with_index do |tag, i|
  puts "  #{i+1}. #{tag[:name]} (#{tag[:date]})"
end