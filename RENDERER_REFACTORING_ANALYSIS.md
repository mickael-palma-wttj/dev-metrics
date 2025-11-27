# HTML Renderer Refactoring Analysis

## Executive Summary

The HTML renderers have **significant code duplication** and **opportunity for abstraction**. This analysis identifies 8 major refactoring opportunities that will reduce code by ~40%, improve maintainability, and enable easier testing.

---

## 1. CRITICAL: Duplicate Utility Methods Across Renderers

### Problem
**Every renderer duplicates these methods:**
- `format_number()` - Identical in 8+ renderers
- `number_with_delimiter()` - Identical in 8+ renderers  
- `safe_string()` - Duplicate (already in Base, but redefined)
- `safe_value_format()` - Identical in 8+ renderers
- `render_simple_data()` - Identical in 8+ renderers

### Current State
```ruby
# AuthorsPerFileRenderer
def format_number(value)
  return '' if value.nil?
  "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
end

def number_with_delimiter(num)
  num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
end

# FileChurnRenderer - IDENTICAL CODE
def format_number(value)
  return '' if value.nil?
  "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
end

def number_with_delimiter(num)
  num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
end
```

### Solution: Move to Base class
Move all formatting utilities to `Base` class once, delete from all child renderers.

**Affected Renderers:** 8+ (Authors Per File, File Churn, File Ownership, Lines Changed, Co Change Pairs, etc.)

**Impact:** 
- Remove ~50 lines of duplicated code
- Single source of truth for formatting
- Easier bug fixes

---

## 2. HIGH: Duplicate `safe_string()` Method

### Problem
- `Base` class already defines `safe_string()` with encoding handling
- Child renderers redefine it identically
- Creates maintenance burden if changes needed

### Current State (in Base)
```ruby
def safe_string(value)
  return '' if value.nil?
  str = ensure_utf8(value)
  str.gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
end
```

### Affected Renderers
- AuthorsPerFileRenderer
- FileChurnRenderer  
- FileOwnershipRenderer
- LinesChangedRenderer
- CoChangePairsRenderer
- Large Commits, Bugfix Ratio, Revert Rate, etc.

**Action:** Delete all child implementations, inherit from Base.

---

## 3. HIGH: Duplicate `safe_value_format()` Method

### Problem
- Identical implementation in 6+ renderers
- Used in fallback rows for unexpected data formats
- Perfect candidate for Base class method

### Current Implementation (repeated everywhere)
```ruby
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
```

**Optimization:** Consider delegating to `Utils::ValueFormatter.format_generic_value()` instead (already exists).

---

## 4. HIGH: Pattern Duplication in Table Rendering

### Problem
Every renderer with file/author metrics follows identical pattern:

```ruby
def render_*_table
  headers = [...]
  data_table(headers) do
    @value.map do |key, stats|
      if stats.is_a?(Hash)
        render_*_columns(key, stats)  # <- Only this method differs
      else
        table_row([key, safe_value_format(stats)])
      end
    end.join
  end
end
```

### Affected Renderers
- AuthorsPerFileRenderer
- FileChurnRenderer
- FileOwnershipRenderer
- LinesChangedRenderer
- CoChangePairsRenderer
- Large Commits (by_author, by_file sections)

### Solution: Extract Template Method

Create reusable `render_keyed_hash_table()` in Base:

```ruby
# Base class
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

# Child renderer usage
def render_authors_table
  headers = ['Author', 'Count', ...]
  render_keyed_hash_table(headers, method(:render_author_columns))
end
```

**Impact:** Remove 60+ lines of repetitive code.

---

## 5. MEDIUM: Inconsistent Float/Percentage Formatting

### Problem
- FileChurnRenderer uses `format_float()` method
- LinesChangedRenderer uses inline `format('%.2f', value)`
- Co-changes uses inconsistent approaches
- No standard for percentage styling

### Current Inconsistencies
```ruby
# FileChurnRenderer
def format_float(value)
  return '' if value.nil?
  "<span class=\"percentage\">#{format('%.2f', value)}</span>"
end

# LinesChangedRenderer  
"#{format_float(stats[:churn_ratio])}%"

# CoChangePairsRenderer
"#{format('%.1f', coupling_percentage)}%"  # No span wrapper
```

### Solution: Standardize in Base

```ruby
# Base class
def format_percentage(value, decimals = 1)
  return '' if value.nil?
  "<span class=\"percentage\">#{format('%.#{decimals}f', value)}%</span>"
end

def format_float(value, decimals = 2, css_class = 'percentage')
  return '' if value.nil?
  "<span class=\"#{css_class}\">#{format('%.#{decimals}f', value)}</span>"
end
```

---

## 6. MEDIUM: Encoding Handling Duplication

### Problem
- `ensure_utf8()` defined in Base ✓ (Good)
- BUT: Many renderers override with local `safe_string()` that duplicates encoding logic
- Should use inherited `ensure_utf8()` consistently

### Solution
- Keep `ensure_utf8()` in Base
- Use it in `safe_string()` (already done ✓)
- Delete all local encoding handling in child renderers
- Call parent `safe_string()` exclusively

---

## 7. MEDIUM: Missing Abstraction for Multi-Section Renderers

### Problem
Renderers like `LargeCommitsRenderer`, `LeadTimeRenderer`, `DeploymentFrequencyRenderer` have complex multi-section logic:

```ruby
def render_content
  case @value
  when Hash
    render_large_commits_analysis
  else
    render_simple_data
  end
end

def render_large_commits_analysis
  [
    render_overall_statistics,
    render_thresholds,
    render_largest_commits_table,
    render_by_author,
    render_by_file,
  ].compact.join
end
```

### Pattern Recognition
- All follow: `@value` is Hash → render sections
- All sections use same `section()` helper
- All sections fetch metadata from `MetricDescriptions`
- All have similar structure

### Solution: Extract Section Renderer

```ruby
class SectionRenderer
  def initialize(sections)
    @sections = sections  # Array of { title, description, content_proc }
  end
  
  def render
    @sections.map { |s| render_section(s) }.compact.join
  end
  
  private
  
  def render_section(section)
    tooltip = Services::MetricDescriptions.get_section_description(section[:title])
    # ... use tooltip in section()
  end
end
```

---

## 8. MEDIUM: Incomplete Abstraction in Base Class

### Problem
Base class defines helper methods but many renderers don't use them:

**Not used consistently:**
- `metric_details()` - Defined but rarely used
- `metric_detail()` - Good abstraction, used sometimes
- `ensure_utf8()` - Defined but renderers reimplement locally
- `format_number()` - Should be inherited, not redefined

### Solution
- Document which Base methods should be used
- Remove local reimplementations
- Consider adding `format_count()` for consistency with number formatting

---

## 9. LOW: Missing CSS Class Constants

### Problem
Magic strings scattered throughout:
```ruby
"<span class=\"count\">#{...}</span>"
"<span class=\"percentage\">#{...}</span>"
"<span class=\"risk-#{score_class}\">#{...}</span>"
```

### Solution
Define constants in Base:
```ruby
module HTMLClasses
  COUNT = 'count'
  PERCENTAGE = 'percentage'
  METRIC_DETAIL = 'metric-detail'
  # ...
end
```

---

## 10. LOW: Inconsistent Use of `render_simple_data()`

### Problem
```ruby
# Most renderers
def render_simple_data
  metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
end

# Some use different labels
metric_detail('Items', @value.length, 'count')  # GenericRenderer
```

### Solution
Standardize parameter names and defaults in Base.

---

## Summary of Changes

### Lines of Code to Remove
- Duplicate formatting methods: **50 lines**
- Duplicate safe_string methods: **80 lines**
- Duplicate safe_value_format: **60 lines**
- Duplicate table rendering patterns: **100 lines**
- Total: **~290 lines of duplicated code**

### Files to Modify
1. **Base** - Add 20 new utility methods
2. **AuthorsPerFileRenderer** - Remove 30 lines
3. **FileChurnRenderer** - Remove 30 lines
4. **FileOwnershipRenderer** - Remove 25 lines
5. **LinesChangedRenderer** - Remove 35 lines
6. **CoChangePairsRenderer** - Remove 35 lines
7. **Other renderers** - Remove 10-20 lines each
8. Create new: **SectionRenderer** (optional, for multi-section refactor)

### Priority Order
1. **Phase 1 (Critical)**: Move duplicate utilities to Base (Opportunities 1-3)
2. **Phase 2 (High)**: Extract table rendering pattern (Opportunity 4)
3. **Phase 3 (Medium)**: Standardize formatting (Opportunities 5-6)
4. **Phase 4 (Optional)**: Extract SectionRenderer (Opportunity 7)

---

## Testing Recommendations

After refactoring, ensure:
- All renderers produce identical HTML output
- No regression in functionality
- Add unit tests for new Base methods
- Verify encoding handling with special characters

---

## Estimated Impact

- **Code Quality**: ⭐⭐⭐⭐⭐ (40% less duplication)
- **Maintainability**: ⭐⭐⭐⭐⭐ (single source of truth)
- **Performance**: ✓ No impact (refactor only)
- **Testing**: ⭐⭐⭐⭐ (easier to test utilities)
- **Risk**: ⭐⭐ (low - mostly moving code, not changing logic)
