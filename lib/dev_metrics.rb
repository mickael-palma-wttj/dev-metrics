require 'zeitwerk'

# Set up Zeitwerk autoloader for DevMetrics
loader = Zeitwerk::Loader.for_gem

# Configure inflections for proper module naming
loader.inflector.inflect(
  "cli" => "CLI"
)

loader.setup

module DevMetrics
  # Main module for DevMetrics gem
end