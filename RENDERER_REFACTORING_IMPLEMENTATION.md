# Renderer Refactoring Implementation Guide

## Phase 1: Move Duplicate Methods to Base Class

This is the highest-impact, lowest-risk refactoring. It removes ~200 lines of duplicated code.

### Step 1.1: Add Methods to Base Class

Add these methods to `lib/dev_metrics/cli/html_renderers/base.rb`:

```ruby
# Number formatting
def format_number(value)
  return '' if value.nil?
  "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
end

def format_float(value, decimals = 2, css_class = 'percentage')
  return '' if value.nil?
  "<span class=\"#{css_class}\">#{format('%.#{decimals}f', value)}</span>"
end

def format_percentage(value, decimals = 1)
  return '' if value.nil?
  "<span class=\"percentage\">#{format('%.#{decimals}f', value)}%</span>"
end

def number_with_delimiter(num)
  num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
end

# Value formatting
def safe_value_format(value)
  case value
  when Numeric
    value.is_a?(Float) ? format('%.2f', value) : value.to_s
  when Hash
    "#{value.keys.length} items"
  when Array
    "#{value.length} items"
  else
    value.to_s
  end
end

# Data rendering
def render_simple_data
  metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
end

# Table rendering pattern
def render_keyed_hash_table(headers, column_renderer)
  data_table(headers) do
    @value.map do |key, stats|
      if stats.is_a?(Hash)
        column_renderer.call(key, stats)
      else
        table_row([key, safe_value_format(stats)])
      end
    end.join
  end
end
```

### Step 1.2: Remove Duplicate Methods from Child Renderers

For each of these renderers, delete:
- `format_number()`
- `number_with_delimiter()`
- `safe_value_format()`
- `render_simple_data()`
- `safe_string()` (if present - use inherited version)

**Affected files:**
- `authors_per_file_renderer.rb`
- `file_churn_renderer.rb`
- `file_ownership_renderer.rb`
- `lines_changed_renderer.rb`
- `co_change_pairs_renderer.rb`
- `large_commits_renderer.rb` (partially)
- `bugfix_ratio_renderer.rb` (partially)
- `revert_rate_renderer.rb` (partially)

### Step 1.3: Update Renderers to Use Base Methods

Example: `AuthorsPerFileRenderer`

**Before:**
```ruby
def render_authors_per_file_stats_table
  headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
  data_table(headers) do
    @value.map do |filename, stats|
      if stats.is_a?(Hash)
        render_file_author_stats_columns(filename, stats)
      else
        table_row([filename, safe_value_format(stats)])
      end
    end.join
  end
end

def format_number(value)
  # ... duplicated code
end
```

**After:**
```ruby
def render_authors_per_file_stats_table
  headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
  render_keyed_hash_table(headers, method(:render_file_author_stats_columns))
end
```

---

## Phase 2: Standardize Float/Percentage Formatting

### Current Inconsistencies

**FileChurnRenderer:**
```ruby
def format_float(value)
  return '' if value.nil?
  "<span class=\"percentage\">#{format('%.2f', value)}</span>"
end

cells = [
  # ... other cells
  format_float(stats[:avg_churn_per_commit]),
  "#{format_float(stats[:churn_ratio])}%",
]
```

**LinesChangedRenderer:**
```ruby
format_float(stats[:avg_changes_per_commit]),
"#{format_float(stats[:churn_ratio])}%",
```

**CoChangePairsRenderer:**
```ruby
format('%.2f', coupling_strength),
"#{format('%.1f', coupling_percentage)}%",
```

### Solution

Use Base class methods:

**FileChurnRenderer - After:**
```ruby
cells = [
  # ... other cells
  format_float(stats[:avg_churn_per_commit]),
  format_percentage(stats[:churn_ratio], 1),  # Handles both decoration and %
]
```

---

## Phase 3: Extract Reusable Table Pattern

### Problem Renderer Structure (Current)

**AuthorsPerFileRenderer, FileOwnershipRenderer, FileChurnRenderer** all follow:

```ruby
def render_*_table
  headers = [...]
  data_table(headers) do
    @value.map do |key, stats|
      if stats.is_a?(Hash)
        render_*_columns(key, stats)
      else
        table_row([key, safe_value_format(stats)])
      end
    end.join
  end
end

def render_*_columns(key, stats)
  # ... extract and format values from stats
end
```

### Solution: Use Template Pattern

In Base class, we already have:

```ruby
def render_keyed_hash_table(headers, column_renderer)
  data_table(headers) do
    @value.map do |key, stats|
      if stats.is_a?(Hash)
        column_renderer.call(key, stats)
      else
        table_row([key, safe_value_format(stats)])
      end
    end.join
  end
end
```

### Before/After Example

**AuthorsPerFileRenderer - Before:**
```ruby
def render_authors_per_file_stats_table
  headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
  data_table(headers) do
    @value.map do |filename, stats|
      if stats.is_a?(Hash)
        render_file_author_stats_columns(filename, stats)
      else
        table_row([filename, safe_value_format(stats)])
      end
    end.join
  end
end
```

**After:**
```ruby
def render_authors_per_file_stats_table
  headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
  render_keyed_hash_table(headers, method(:render_file_author_stats_columns))
end
```

**Lines saved: 12 per renderer × 6 renderers = 72 lines**

---

## Phase 4 (Optional): Extract Section Renderer

For complex multi-section renderers like `LargeCommitsRenderer`, `LeadTimeRenderer`.

### Create New Helper Class

```ruby
# lib/dev_metrics/cli/html_renderers/section_renderer.rb
module DevMetrics
  module CLI
    module HtmlRenderers
      class SectionRenderer
        def initialize(sections, value)
          @sections = sections
          @value = value
        end
        
        def render
          @sections.map { |section| render_section(section) }.compact.join
        end
        
        private
        
        def render_section(section)
          return '' unless @value[section[:key]]
          
          tooltip = Services::MetricDescriptions.get_section_description(section[:title])
          Base.new(nil).section(section[:title], tooltip) do
            section[:renderer].call(@value[section[:key]])
          end
        end
      end
    end
  end
end
```

### Usage in LargeCommitsRenderer

**Before:**
```ruby
def render_large_commits_analysis
  [
    render_overall_statistics,
    render_thresholds,
    render_largest_commits_table,
    render_by_author,
    render_by_file,
  ].compact.join
end

def render_overall_statistics
  return unless @value[:overall]
  tooltip = Services::MetricDescriptions.get_section_description('Overall Statistics')
  section('Overall Statistics', tooltip) do
    # ... rendering logic
  end
end
```

**After:**
```ruby
def render_large_commits_analysis
  sections = [
    { title: 'Overall Statistics', key: :overall, renderer: method(:render_overall_stats_content) },
    { title: 'Size Thresholds', key: :thresholds, renderer: method(:render_threshold_content) },
    # ... more sections
  ]
  SectionRenderer.new(sections, @value).render
end

def render_overall_stats_content(data)
  data_table(%w[Metric Value]) do
    [
      # ... rows
    ].join
  end
end
```

---

## Implementation Checklist

### Phase 1 (2-3 hours)
- [ ] Add methods to Base class
- [ ] Update AuthorsPerFileRenderer
- [ ] Update FileChurnRenderer
- [ ] Update FileOwnershipRenderer
- [ ] Update LinesChangedRenderer
- [ ] Update CoChangePairsRenderer
- [ ] Run tests - ensure no visual regressions
- [ ] Commit: "refactor: consolidate duplicate formatting methods in Base renderer"

### Phase 2 (1-2 hours)
- [ ] Standardize all format_float, format_percentage calls
- [ ] Update FileChurnRenderer
- [ ] Update LinesChangedRenderer
- [ ] Update CoChangePairsRenderer
- [ ] Update BugfixRatioRenderer
- [ ] Run tests
- [ ] Commit: "refactor: standardize float and percentage formatting"

### Phase 3 (1-2 hours)
- [ ] Replace all keyed-hash-table patterns with template method
- [ ] Update all affected renderers
- [ ] Run tests
- [ ] Commit: "refactor: extract keyed hash table rendering pattern"

### Phase 4 (Optional, 3-4 hours)
- [ ] Create SectionRenderer class
- [ ] Update multi-section renderers
- [ ] Run tests
- [ ] Commit: "refactor: extract section rendering helper"

---

## Verification Steps

After each phase:

1. **Run analysis:** `bundle exec bin/dev-metrics analyze --repo-path . --format html`
2. **Compare output:** Check generated HTML visually for differences
3. **Run tests:** `bundle exec rspec` (if tests exist)
4. **Check diffs:** Verify only code was moved, not changed

---

## Risk Assessment

| Phase | Risk | Impact | Effort |
|-------|------|--------|--------|
| 1 | Low | High | 2-3h |
| 2 | Low | Medium | 1-2h |
| 3 | Low | High | 1-2h |
| 4 | Low | Medium | 3-4h |

**Total effort**: 7-11 hours for full refactoring
**Code removed**: ~290 lines of duplication
**Maintainability gain**: ⭐⭐⭐⭐⭐
