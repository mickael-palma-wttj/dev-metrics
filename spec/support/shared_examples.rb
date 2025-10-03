# Shared examples for metric classes
RSpec.shared_examples "a metric" do
  it "responds to calculate" do
    expect(subject).to respond_to(:calculate)
  end

  it "returns a MetricResult" do
    result = subject.calculate
    expect(result).to be_a(DevMetrics::MetricResult)
  end

  it "has a metric name" do
    expect(subject.metric_name).to be_a(String)
    expect(subject.metric_name).not_to be_empty
  end

  it "has a description" do
    expect(subject.description).to be_a(String)
    expect(subject.description).not_to be_empty
  end

  it "includes repository information in result" do
    result = subject.calculate
    expect(result.repository).to eq(repository.name)
  end

  it "includes time period in result" do
    result = subject.calculate
    expect(result.time_period).to eq(time_period)
  end
end

# Shared examples for collector classes
RSpec.shared_examples "a collector" do
  it "responds to collect" do
    expect(subject).to respond_to(:collect)
  end

  it "returns an array from collect" do
    result = subject.collect
    expect(result).to be_a(Array)
  end

  it "handles repository validation" do
    expect(subject).to respond_to(:validate_repository, true)
  end

  it "has repository and options attributes" do
    expect(subject.repository).to eq(repository)
    expect(subject.options).to be_a(Hash)
  end
end

# Shared examples for model classes
RSpec.shared_examples "a model with hash conversion" do
  it "responds to to_h" do
    expect(subject).to respond_to(:to_h)
  end

  it "returns a hash from to_h" do
    expect(subject.to_h).to be_a(Hash)
  end

  it "supports equality comparison" do
    expect(subject).to respond_to(:==)
  end
end