# frozen_string_literal: true

require_relative '../lib/dev_metrics'

# Load support files
Dir[File.join(__dir__, 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Focus on failures
  config.filter_run_when_matching :focus

  # Run specs in random order to surface order dependencies
  config.order = :random
  Kernel.srand config.seed

  # Clean up test data after each test
  config.after do
    # Clean up any temporary files or test repositories
    cleanup_test_repositories if respond_to?(:cleanup_test_repositories)
  end

  # Configure shared examples and helpers
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
