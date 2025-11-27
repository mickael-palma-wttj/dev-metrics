# Renderer Refactoring - Visual Summary

## Code Duplication Heat Map

```
Duplication by Method (across 12 renderers):

format_number()              ████████████████ 8 renderers
number_with_delimiter()      ████████████████ 8 renderers
safe_value_format()          ██████████████ 6 renderers
render_simple_data()         ██████████████ 6 renderers
safe_string()                ████████████ 5+ renderers
format_float()               ███████ 3 renderers (varies)
Keyed hash table pattern     ████████████████ 6 renderers

Total duplicated lines: ~290
```

---

## Before & After: Code Metrics

### Current State
```
Renderers:              12 files
Total lines:            ~1,200 LOC
Formatting methods:     40-50 duplicated
Methods per renderer:   8-15 methods

Code smell score:       ⭐⭐⭐⭐☆ (High duplication)
```

### After Full Refactoring
```
Renderers:              12 files
Total lines:            ~900 LOC  (-25%)
Formatting methods:     8 shared in Base
Methods per renderer:   3-8 methods

Code smell score:       ⭐☆☆☆☆ (Minimal duplication)
```

---

## Opportunity Impact Matrix

```
┌─────────────────────────────────────────────────────────────┐
│ HIGH IMPACT / LOW EFFORT (Do First!)                        │
│                                                             │
│ 1. Move formatting methods to Base     [Remove 50 lines]   │
│ 2. Remove duplicate safe_string()      [Remove 80 lines]   │
│ 3. Remove duplicate safe_value_format()[Remove 60 lines]   │
│                                                             │
│ Total quick wins: ~190 lines, 2-3 hours                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ MEDIUM IMPACT / MEDIUM EFFORT (Do Next)                    │
│                                                             │
│ 4. Extract keyed hash table pattern   [Remove 100 lines]   │
│ 5. Standardize float formatting      [Change 30 calls]    │
│                                                             │
│ Total effort: ~100 lines, 2-3 hours                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ LOWER PRIORITY (Nice to Have)                               │
│                                                             │
│ 6. Extract SectionRenderer             [New class]         │
│ 7. Add CSS class constants            [5-10 lines]        │
│ 8. Improve method documentation       [Testing]           │
└─────────────────────────────────────────────────────────────┘
```

---

## Refactoring Flow Diagram

```
PHASE 1: Consolidate Utilities (2-3h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────────────────────────────────────────┐
│ Base Class                                              │
├─────────────────────────────────────────────────────────┤
│ + format_number()          ← from all 8 renderers       │
│ + format_float()           ← standardize across 3       │
│ + format_percentage()      ← new, replaces duplicates   │
│ + number_with_delimiter()  ← from all 8 renderers       │
│ + safe_value_format()      ← from all 6 renderers       │
│ + render_simple_data()     ← from all 6 renderers       │
│ + render_keyed_hash_table()← template for 6 renderers   │
└─────────────────────────────────────────────────────────┘
         ↓ Inherited by
    [All 12 renderers]
    
✓ Result: Remove ~190 lines of duplication


PHASE 2: Standardize Formatting (1-2h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    FileChurnRenderer
    LinesChangedRenderer
    CoChangePairsRenderer
         ↓
    Update float/percentage calls
         ↓
    Use consistent format_float() and format_percentage()
    
✓ Result: Consistent styling, ~30 call sites updated


PHASE 3: Extract Table Pattern (1-2h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    AuthorsPerFileRenderer
    FileChurnRenderer
    FileOwnershipRenderer
    LinesChangedRenderer
    CoChangePairsRenderer
    etc.
         ↓
    Replace explicit loops with render_keyed_hash_table()
         ↓
    Cleaner, 12-line → 1-line rendering calls
    
✓ Result: Remove ~100 lines, improve readability


PHASE 4: Extract Sections (Optional, 3-4h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ┌─────────────────────┐
    │ SectionRenderer     │
    │ (New class)         │
    └──────────┬──────────┘
               ↓
    LargeCommitsRenderer
    LeadTimeRenderer
    DeploymentFrequencyRenderer
         ↓
    Replaces complex section rendering with declarative config
    
✓ Result: Cleaner, easier to extend multi-section renderers
```

---

## Example: AuthorsPerFileRenderer Refactoring

### BEFORE (73 lines)
```ruby
class AuthorsPerFileRenderer < Base
  def render_content
    case @value
    when Hash
      render_authors_per_file_stats_table
    else
      render_simple_data
    end
  end

  private

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

  def render_file_author_stats_columns(filename, stats)
    safe_filename = safe_string(filename)
    authors = stats[:authors].is_a?(Array) ? stats[:authors].join(', ') : stats[:authors].to_s
    safe_authors = safe_string(authors)
    bus_factor = stats[:bus_factor_risk].to_s
    ownership = stats[:ownership_type].to_s

    cells = [
      safe_filename,
      format_number(stats[:author_count]),
      safe_authors,
      bus_factor,
      ownership,
    ]
    table_row(cells)
  end

  def format_number(value)                    # ← DUPLICATED
    return '' if value.nil?
    "<span class=\"count\">#{number_with_delimiter(value.to_i)}</span>"
  end

  def number_with_delimiter(num)              # ← DUPLICATED
    num.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
  end

  def safe_value_format(value)                # ← DUPLICATED
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

  def render_simple_data                      # ← DUPLICATED
    metric_detail('Value', Utils::ValueFormatter.format_generic_value(@value))
  end

  def safe_string(value)                      # ← DUPLICATED (also in Base)
    str = value.to_s
    return str if str.encoding == Encoding::UTF_8 && str.valid_encoding?
    str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    value.to_s.force_encoding('UTF-8').scrub('?')
  end
end
```

### AFTER (31 lines - 58% reduction)
```ruby
class AuthorsPerFileRenderer < Base
  def render_content
    case @value
    when Hash
      render_authors_per_file_stats_table
    else
      render_simple_data  # ← Inherited from Base
    end
  end

  private

  def render_authors_per_file_stats_table
    headers = ['Filename', 'Author Count', 'Authors', 'Bus Factor', 'Ownership Type']
    render_keyed_hash_table(headers, method(:render_file_author_stats_columns))
  end

  def render_file_author_stats_columns(filename, stats)
    safe_filename = safe_string(filename)
    authors = stats[:authors].is_a?(Array) ? stats[:authors].join(', ') : stats[:authors].to_s
    safe_authors = safe_string(authors)
    bus_factor = stats[:bus_factor_risk].to_s
    ownership = stats[:ownership_type].to_s

    cells = [
      safe_filename,
      format_number(stats[:author_count]),    # ← Inherited
      safe_authors,
      bus_factor,
      ownership,
    ]
    table_row(cells)
  end
  # All other methods removed - inherited from Base!
end
```

**Lines removed: 42 lines (58% reduction)**
**Complexity removed: 7 methods → 2 methods**

---

## Renderer Refactoring Savings

```
                      BEFORE  AFTER  SAVED
AuthorsPerFileRenderer   73     31     42
FileChurnRenderer        96     40     56
FileOwnershipRenderer    76     35     41
LinesChangedRenderer     93     42     51
CoChangePairsRenderer    93     41     52
                        ───    ───    ───
Phase 1-3 Total:        531    189    342 lines

Reduction: 64% for these 5 renderers
```

---

## Testing Strategy

### Unit Tests to Add
```ruby
# spec/lib/dev_metrics/cli/html_renderers/base_spec.rb

describe 'HTML Renderer Base Class' do
  describe '#format_number' do
    it 'formats integers with thousands separators' do
      expect(format_number(1000)).to include('1,000')
    end
    
    it 'wraps in count span' do
      expect(format_number(42)).to include('<span class="count">')
    end
  end
  
  describe '#format_percentage' do
    it 'formats floats with 1 decimal' do
      expect(format_percentage(12.345)).to include('12.3%')
    end
  end
  
  describe '#render_keyed_hash_table' do
    it 'renders each key-value pair with renderer' do
      # ... test table generation
    end
  end
end
```

### Integration Tests
```ruby
# Compare HTML output before/after for each renderer
# Should be identical (pixel-perfect)
```

---

## Benefits Summary

| Dimension | Benefit |
|-----------|---------|
| **Code Volume** | -40% duplication removed |
| **Maintainability** | ⭐⭐⭐⭐⭐ Single source of truth |
| **Testing** | ⭐⭐⭐⭐ Easier to unit test shared methods |
| **Onboarding** | ⭐⭐⭐⭐ Clearer base patterns for new renderers |
| **Bug Fixes** | ⭐⭐⭐⭐⭐ Fix once in Base, benefit all renderers |
| **Performance** | No change (refactor only) |
| **Risk** | ⭐⭐ Low - moving code, not changing logic |

---

## Recommendations

### Start With
1. **Phase 1** - Move utilities to Base (highest ROI, lowest risk)
2. **Phase 3** - Extract table pattern (high value for effort)

### Optional
3. **Phase 2** - Standardize formatting (nice consistency)
4. **Phase 4** - Extract SectionRenderer (future-proofing)

### Timeline
- **Quick Start**: Phase 1 + 3 = 3-5 hours, remove 290 lines
- **Full Refactor**: All phases = 7-11 hours, remove 340 lines + improved architecture
