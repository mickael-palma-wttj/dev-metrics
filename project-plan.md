# Developer Metrics CLI - Project Plan

## Project Overview

A Ruby CLI application that analyzes developer metrics from Git repositories and GitHub APIs to provide insights into team productivity, code quality, and development health.

## Core Objectives

- **Comprehensive Metrics**: Implement 30+ developer metrics across 6 categories
- **Dual Data Sources**: Integrate Git log analysis with GitHub API data
- **Ruby Best Practices**: Follow Sandi Metz rules, SOLID principles, and clean code practices
- **Minimal Dependencies**: Use only Ruby standard library + RSpec for testing
- **Flexible Analysis**: Support single repositories and multi-repo aggregation
- **Rich Reporting**: Provide multiple output formats and detailed insights

## Architecture Design

### Project Structure

```
lib/
├── dev_metrics/
│   ├── cli/
│   │   ├── runner.rb              # Main CLI entry point and argument parsing
│   │   ├── repository_selector.rb # Git repository detection and selection
│   │   ├── output_formatter.rb    # Results presentation in multiple formats
│   │   └── progress_reporter.rb   # Progress indicators for long operations
│   ├── collectors/
│   │   ├── base_collector.rb      # Shared collection interface
│   │   ├── git_collector.rb       # Git log data collection and parsing
│   │   └── github_collector.rb    # GitHub API data collection with rate limiting
│   ├── metrics/
│   │   ├── base_metric.rb         # Common metric interface and utilities
│   │   ├── git/                   # Git-based metrics (22 metrics)
│   │   │   ├── commit_activity/
│   │   │   │   ├── commits_per_developer.rb
│   │   │   │   ├── commit_size.rb
│   │   │   │   ├── commit_frequency.rb
│   │   │   │   └── lines_changed.rb
│   │   │   ├── code_churn/
│   │   │   │   ├── file_churn.rb
│   │   │   │   ├── authors_per_file.rb
│   │   │   │   ├── file_ownership.rb
│   │   │   │   └── co_change_pairs.rb
│   │   │   ├── reliability/
│   │   │   │   ├── revert_rate.rb
│   │   │   │   ├── bugfix_ratio.rb
│   │   │   │   └── large_commits.rb
│   │   │   └── flow/
│   │   │       ├── lead_time.rb
│   │   │       └── deployment_frequency.rb
│   │   └── github/                # GitHub API metrics (16 metrics)
│   │       ├── pr_throughput/
│   │       │   ├── pr_counts.rb
│   │       │   ├── pr_size.rb
│   │       │   ├── review_times.rb
│   │       │   ├── cycle_times.rb
│   │       │   ├── review_rounds.rb
│   │       │   └── draft_conversion.rb
│   │       ├── review_collaboration/
│   │       │   ├── review_load.rb
│   │       │   ├── review_responsiveness.rb
│   │       │   ├── review_depth.rb
│   │       │   ├── review_coverage.rb
│   │       │   └── changes_requested.rb
│   │       ├── knowledge/
│   │       │   ├── cross_repo_contributions.rb
│   │       │   └── critical_file_prs.rb
│   │       └── team_health/
│   │           ├── off_hours_activity.rb
│   │           ├── pickup_gaps.rb
│   │           ├── change_failure_rate.rb
│   │           └── mttr.rb
│   ├── aggregators/
│   │   ├── repository_aggregator.rb    # Repository-level metric aggregation
│   │   ├── contributor_aggregator.rb   # Per-contributor metric aggregation
│   │   └── team_aggregator.rb          # Team-level insights and comparisons
│   ├── models/
│   │   ├── repository.rb              # Repository model with metadata
│   │   ├── contributor.rb             # Contributor model with identity resolution
│   │   ├── metric_result.rb           # Standardized metric result container
│   │   ├── time_period.rb             # Time range handling and calculations
│   │   └── configuration.rb           # Application configuration management
│   ├── services/
│   │   ├── github_authenticator.rb    # GitHub token management
│   │   ├── cache_manager.rb           # API response caching
│   │   └── rate_limiter.rb            # GitHub API rate limit handling
│   └── utils/
│       ├── git_command.rb             # Git command execution wrapper
│       ├── time_helper.rb             # Time zone and working hours utilities
│       └── file_matcher.rb            # File pattern matching for analysis
├── bin/
│   └── dev-metrics                    # Executable entry point
├── spec/
│   ├── fixtures/                      # Test data and mock repositories
│   ├── support/                       # Test helpers and shared examples
│   └── [mirrored lib structure]       # Comprehensive test coverage
├── config/
│   ├── default.yml                    # Default configuration
│   └── metrics.yml                    # Metric definitions and thresholds
└── docs/
    ├── metrics-guide.md               # Detailed metric explanations
    ├── installation.md               # Setup and installation guide
    └── examples/                     # Usage examples and sample reports
```

## Detailed Metrics Specification

### Git-Based Metrics (22 total)

#### Commit Activity (4 metrics)
| Metric | File | Git Command | Purpose |
|--------|------|-------------|---------|
| Commits per developer | `commits_per_developer.rb` | `git shortlog -s -n --all` | Raw activity level, throughput baseline |
| Commit size | `commit_size.rb` | `git log --numstat` | Batch size discipline |
| Commit frequency | `commit_frequency.rb` | `git log --format="%ad"` | Working patterns, flow |
| Lines changed | `lines_changed.rb` | `git log --numstat --author` | Volume proxy, churn indicator |

#### Code Churn & Ownership (4 metrics)
| Metric | File | Git Command | Purpose |
|--------|------|-------------|---------|
| File churn | `file_churn.rb` | `git log --numstat --all` | Hotspots identification |
| Authors per file | `authors_per_file.rb` | `git log --format="%an" -- file` | Bus factor, shared ownership |
| File ownership | `file_ownership.rb` | `git log -n 1 --format="%an"` | Code ownership concentration |
| Co-change pairs | `co_change_pairs.rb` | `git log --name-only` | Coupling, modularity issues |

#### Reliability/Quality (3 metrics)
| Metric | File | Git Command | Purpose |
|--------|------|-------------|---------|
| Revert rate | `revert_rate.rb` | `git log --grep="revert"` | Instability proxy |
| Bugfix ratio | `bugfix_ratio.rb` | `git log --grep="fix\|bug"` | Defect-fix proxy |
| Large commits | `large_commits.rb` | `git log --numstat` | Risky changes identification |

#### Flow/Delivery (2 metrics)
| Metric | File | Git Command | Purpose |
|--------|------|-------------|---------|
| Lead time | `lead_time.rb` | `git log --tags --format="%ad"` | DORA Lead Time approximation |
| Deployment frequency | `deployment_frequency.rb` | `git tag --sort=-creatordate` | DORA Deployment Frequency |

### GitHub API Metrics (16 total)

#### PR Throughput (6 metrics)
| Metric | File | API Endpoint | Purpose |
|--------|------|-------------|---------|
| PR counts | `pr_counts.rb` | `/pulls` | Delivery velocity |
| PR size | `pr_size.rb` | `/pulls` (additions+deletions) | Batch size, reviewability |
| Review times | `review_times.rb` | `/pulls/reviews` | Review responsiveness |
| Cycle times | `cycle_times.rb` | `/pulls` (created→merged) | Development cycle time |
| Review rounds | `review_rounds.rb` | `/pulls/reviews` + commits | Rework indicator |
| Draft conversion | `draft_conversion.rb` | `/pulls` (draft→ready) | Grooming quality |

#### Review Collaboration (5 metrics)
| Metric | File | API Endpoint | Purpose |
|--------|------|-------------|---------|
| Review load | `review_load.rb` | `/pulls/reviews` | Reviewer workload |
| Review responsiveness | `review_responsiveness.rb` | `/pulls/reviews` | Team responsiveness |
| Review depth | `review_depth.rb` | `/pulls/comments` | Review thoroughness |
| Review coverage | `review_coverage.rb` | `/pulls/reviews` | Cross-team collaboration |
| Changes requested | `changes_requested.rb` | `/pulls/reviews` | Quality assertiveness |

#### Knowledge/Ownership (2 metrics)
| Metric | File | API Endpoint | Purpose |
|--------|------|-------------|---------|
| Cross-repo contributions | `cross_repo_contributions.rb` | `/pulls` across repos | Breadth vs specialization |
| Critical file PRs | `critical_file_prs.rb` | `/pulls/files` | High-risk code contributions |

#### Team Health (3 metrics)
| Metric | File | API Endpoint | Purpose |
|--------|------|-------------|---------|
| Off-hours activity | `off_hours_activity.rb` | `/pulls/reviews` timestamps | Burnout risk indicator |
| Pickup gaps | `pickup_gaps.rb` | `/pulls` created→first review | PR SLA monitoring |
| Change failure rate | `change_failure_rate.rb` | `/pulls` + issue links | DORA Change Failure Rate |

## Technical Implementation Details

### Design Patterns & Principles

#### Applied Patterns
- **Strategy Pattern**: Different metric calculation strategies
- **Template Method**: Base metric class with common workflow
- **Factory Pattern**: Metric creation based on configuration
- **Observer Pattern**: Progress reporting during analysis
- **Adapter Pattern**: Git command and GitHub API abstractions
- **Service Objects**: Focused business logic encapsulation

#### Ruby Best Practices Compliance
- **Sandi Metz Rules**:
  - Methods < 10 lines
  - Classes < 100 lines
  - Parameters ≤ 4 per method
  - Limited instance variables per method
- **SOLID Principles**: Single responsibility, dependency injection
- **Clean Code**: Intention-revealing names, no comments needed
- **DRY**: Shared base classes and modules
- **YAGNI**: No premature optimization or unused features

### Error Handling Strategy

```ruby
# Graceful degradation example
class GitCollector < BaseCollector
  def collect_commits
    execute_git_command('log --oneline')
  rescue GitCommandError => e
    log_warning("Git command failed: #{e.message}")
    []
  rescue => e
    log_error("Unexpected error: #{e.message}")
    raise CollectionError, "Failed to collect commit data"
  end
end
```

### Performance Considerations

- **Parallel Processing**: Multiple repositories analyzed concurrently
- **Streaming Parsing**: Large Git logs processed in chunks
- **API Batching**: GitHub API requests batched where possible
- **Intelligent Caching**: API responses cached with TTL
- **Memory Management**: Large datasets processed in batches

### Configuration Management

```yaml
# config/default.yml
github:
  api_base_url: "https://api.github.com"
  rate_limit_buffer: 10
  cache_ttl: 3600

analysis:
  default_time_range: "30d"
  working_hours_start: 9
  working_hours_end: 18
  large_commit_threshold: 500

output:
  default_format: "text"
  precision: 2
  show_progress: true
```

## CLI Interface Design

### Command Structure

```bash
# Basic analysis
dev-metrics analyze [PATH] [OPTIONS]

# Interactive mode
dev-metrics scan [PATH] --interactive

# Report generation  
dev-metrics report --repository=REPO [OPTIONS]

# Configuration
dev-metrics config --set github.token=TOKEN
dev-metrics config --show
```

### Command Options

```bash
# Analysis options
--metrics=CATEGORIES     # comma-separated: git,pr_throughput,team_health
--since=DATE            # start date for analysis (YYYY-MM-DD)
--until=DATE            # end date for analysis  
--contributors=NAMES    # focus on specific contributors
--exclude-bots         # exclude bot accounts from analysis

# Output options
--format=FORMAT        # text, json, csv, html
--output=FILE         # output file path
--template=TEMPLATE   # custom output template
--no-progress         # disable progress indicators

# Repository options
--recursive           # scan subdirectories for Git repos
--include-forks      # include forked repositories
--github-org=ORG     # GitHub organization name
--github-token=TOKEN # GitHub API token
```

### Sample Usage Examples

```bash
# Analyze single repository
dev-metrics analyze /path/to/repo --format=json --output=metrics.json

# Interactive multi-repo analysis
dev-metrics scan /workspace --interactive --metrics=git,pr_throughput

# Team health focus
dev-metrics analyze . --metrics=team_health --since=2024-01-01

# Contributor-specific report
dev-metrics report --contributor=john.doe --format=html --output=john-report.html

# Cross-repository analysis
dev-metrics analyze /projects --recursive --github-org=mycompany
```

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Project structure setup
- [ ] Base classes and interfaces
- [ ] Git command wrapper
- [ ] Basic CLI runner
- [ ] RSpec test framework setup

### Phase 2: Git Metrics (Weeks 3-4)
- [ ] Implement all 22 Git-based metrics
- [ ] Git collector with error handling
- [ ] Repository model and detection
- [ ] Time period handling
- [ ] Basic text output formatting

### Phase 3: GitHub Integration (Weeks 5-6)
- [ ] GitHub API client with authentication
- [ ] Rate limiting and caching
- [ ] Implement all 16 GitHub metrics
- [ ] API error handling and retries
- [ ] Configuration management

### Phase 4: Aggregation & Reporting (Week 7)
- [ ] Repository-level aggregation
- [ ] Contributor-level aggregation
- [ ] Team-level insights
- [ ] Multiple output formats (JSON, CSV, HTML)
- [ ] Report templates

### Phase 5: CLI Enhancement (Week 8)
- [ ] Interactive repository selection
- [ ] Progress reporting
- [ ] Advanced filtering options
- [ ] Configuration commands
- [ ] Help and documentation

### Phase 6: Testing & Documentation (Week 9)
- [ ] Comprehensive test coverage (>90%)
- [ ] Integration tests with real repositories
- [ ] Performance testing and optimization
- [ ] User documentation and guides
- [ ] Code quality review

### Phase 7: Polish & Release (Week 10)
- [ ] Bug fixes and edge cases
- [ ] Performance optimization
- [ ] Final documentation review
- [ ] Gem packaging preparation
- [ ] Release preparation

## Quality Assurance

### Testing Strategy
- **Unit Tests**: Each metric class individually tested
- **Integration Tests**: End-to-end CLI workflows
- **Fixture Data**: Consistent test repositories and API responses
- **Performance Tests**: Large repository handling
- **Error Scenarios**: Network failures, invalid Git repos, API limits

### Code Quality Metrics
- **Test Coverage**: >90% line coverage required
- **Complexity**: Cyclomatic complexity <10 per method
- **Documentation**: All public methods documented
- **Style**: RuboCop compliance with custom rules
- **Security**: No hardcoded credentials or unsafe operations

## Success Criteria

### Functional Requirements
- [ ] All 38 metrics accurately calculated
- [ ] Both Git and GitHub data sources working
- [ ] Multi-repository analysis capability
- [ ] Multiple output formats supported
- [ ] Error handling for edge cases

### Performance Requirements
- [ ] Large repositories (10k+ commits) processed within 5 minutes
- [ ] GitHub API rate limits respected
- [ ] Memory usage <500MB for typical analysis
- [ ] Progress reporting for operations >30 seconds

### Usability Requirements
- [ ] Clear, actionable error messages
- [ ] Intuitive CLI interface
- [ ] Comprehensive help documentation
- [ ] Installation instructions for all platforms

## Risk Mitigation

### Technical Risks
- **GitHub API Rate Limits**: Implement caching and request batching
- **Large Repository Performance**: Use streaming and parallel processing
- **Git Command Variations**: Test across Git versions and platforms
- **Memory Usage**: Process data in chunks, avoid loading entire history

### Business Risks
- **Scope Creep**: Maintain focus on defined 38 metrics
- **Complexity**: Follow Ruby best practices strictly
- **Maintenance**: Document all metric calculations clearly
- **Adoption**: Provide clear value demonstration and examples

## Future Enhancements (Post-V1)

### Additional Data Sources
- **GitLab API**: Extend to GitLab repositories
- **Jira Integration**: Link commits to tickets for better context
- **CI/CD Data**: Jenkins, GitHub Actions build metrics
- **Code Quality**: SonarQube, CodeClimate integration

### Advanced Features
- **Trend Analysis**: Historical metric tracking over time
- **Alerting**: Threshold-based alerts for concerning metrics
- **Team Comparisons**: Benchmarking across teams
- **ML Insights**: Predictive analytics for code quality

### Platform Extensions
- **Web Dashboard**: Browser-based visualization
- **Slack Integration**: Automated metric reports
- **Export Formats**: PowerBI, Tableau connectors
- **API Server**: HTTP API for metric access

This comprehensive project plan provides a clear roadmap for building a robust, maintainable, and valuable developer metrics CLI tool using Ruby best practices.