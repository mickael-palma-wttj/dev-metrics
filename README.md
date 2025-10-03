# Developer Metrics CLI

A Ruby CLI application that analyzes developer metrics from Git repositories and GitHub APIs to provide insights into team productivity, code quality, and development health.

## Features

- **Comprehensive Metrics**: 38+ metrics across 6 categories
- **Dual Data Sources**: Git log analysis + GitHub API integration
- **Multi-Repository**: Analyze single repos or entire project directories
- **Rich Reporting**: Multiple output formats (text, JSON, CSV, HTML)
- **Ruby Best Practices**: Clean code following Sandi Metz rules

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/dev-metrics-new.git
cd dev-metrics-new

# Install dependencies (RSpec for testing)
gem install rspec
```

## Quick Start

```bash
# Analyze current repository
./bin/dev-metrics analyze .

# Interactive multi-repo analysis
./bin/dev-metrics scan /path/to/projects --interactive

# Generate JSON report
./bin/dev-metrics analyze . --format=json --output=metrics.json
```

## Metrics Categories

- **Commit Activity**: Commits per developer, commit size, frequency patterns
- **Code Churn**: File hotspots, ownership distribution, coupling analysis
- **Reliability**: Revert rates, bugfix ratios, large commit detection
- **Flow/Delivery**: Lead times, deployment frequency (DORA metrics)
- **PR Throughput**: Cycle times, review responsiveness, batch sizes
- **Team Health**: Off-hours activity, pickup gaps, change failure rates

## Development

```bash
# Run tests
rspec

# Run specific test
rspec spec/lib/metrics/git/commit_activity/commits_per_developer_spec.rb

# Check code coverage
rspec --format documentation
```

## Architecture

The application follows Ruby best practices with:
- Single Responsibility Principle (one metric per file)
- Strategy pattern for different metric calculations
- Template method pattern for common workflows
- Clean separation between Git and GitHub API metrics

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-metric`)
3. Follow Ruby best practices and ensure tests pass
4. Commit your changes (`git commit -am 'Add amazing metric'`)
5. Push to the branch (`git push origin feature/amazing-metric`)
6. Create a Pull Request

## License

MIT License - see LICENSE file for details.