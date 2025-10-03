require 'zeitwerk'

# Set up Zeitwerk autoloader for DevMetrics
loader = Zeitwerk::Loader.for_gem
loader.setup

module DevMetrics
  # Main module for DevMetrics gem
end