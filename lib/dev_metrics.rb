require 'zeitwerk'

# Set up Zeitwerk autoloader for DevMetrics
loader = Zeitwerk::Loader.for_gem

# Configure inflections for proper module naming
loader.inflector.inflect(
  'api' => 'API',
  'cli' => 'CLI',
  'csv' => 'CSV',
  'html' => 'HTML',
  'http' => 'HTTP',
  'https' => 'HTTPS',
  'json' => 'JSON',
  'pdf' => 'PDF',
  'pr' => 'PR',
  'rest' => 'REST',
  'sql' => 'SQL',
  'ssh' => 'SSH',
  'ssl' => 'SSL',
  'tls' => 'TLS',
  'ui' => 'UI',
  'url' => 'URL',
  'uuid' => 'UUID',
  'xml' => 'XML',
  'yaml' => 'YAML'
)

loader.setup

module DevMetrics
  # Main module for DevMetrics gem
end
