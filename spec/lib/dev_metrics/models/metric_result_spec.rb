# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DevMetrics::Models::MetricResult do
  subject(:metric_result) do
    described_class.new(
      metric_name: metric_name,
      value: value,
      repository: repository,
      time_period: time_period,
      metadata: metadata
    )
  end

  let(:metric_name) { 'test_metric' }
  let(:value) { 42 }
  let(:repository) { 'test-repo' }
  let(:time_period) { create_test_time_period }
  let(:metadata) { { total_records: 10 } }

  it_behaves_like 'a model with hash conversion'

  describe '#initialize' do
    it 'sets all attributes correctly' do
      expect(metric_result.metric_name).to eq(metric_name)
      expect(metric_result.value).to eq(value)
      expect(metric_result.repository).to eq(repository)
      expect(metric_result.time_period).to eq(time_period)
      expect(metric_result.metadata).to eq(metadata)
      expect(metric_result.error).to be_nil
    end
  end

  describe '#success?' do
    context 'when no error' do
      it 'returns true' do
        expect(metric_result.success?).to be true
      end
    end

    context 'when error present' do
      subject(:error_metric_result) do
        described_class.new(
          metric_name: metric_name,
          value: nil,
          repository: repository,
          time_period: time_period,
          error: 'Something went wrong'
        )
      end

      it 'returns false' do
        expect(error_metric_result.success?).to be false
      end
    end
  end

  describe '#failed?' do
    it 'returns opposite of success?' do
      expect(metric_result.failed?).to eq(!subject.success?)
    end
  end

  describe '#to_h' do
    it 'returns hash with all attributes' do
      hash = subject.to_h
      expect(hash[:metric_name]).to eq(metric_name)
      expect(hash[:value]).to eq(value)
      expect(hash[:repository]).to eq(repository)
      expect(hash[:time_period]).to eq(time_period.to_h)
      expect(hash[:metadata]).to eq(metadata)
      expect(hash[:error]).to be_nil
    end
  end

  describe '#to_json' do
    it 'returns valid JSON' do
      json_string = subject.to_json
      expect { JSON.parse(json_string) }.not_to raise_error
    end
  end

  describe '#==' do
    let(:other) do
      described_class.new(
        metric_name: metric_name,
        value: value,
        repository: repository,
        time_period: time_period
      )
    end

    it 'returns true for equivalent results' do
      expect(subject).to eq(other)
    end

    it 'returns false for different metric names' do
      other = described_class.new(
        metric_name: 'different_metric',
        value: value,
        repository: repository,
        time_period: time_period
      )
      expect(subject).not_to eq(other)
    end
  end

  describe '#to_s' do
    context 'when successful' do
      it 'formats value and repository' do
        expect(subject.to_s).to include(metric_name)
        expect(subject.to_s).to include(value.to_s)
        expect(subject.to_s).to include(repository)
      end
    end

    context 'when failed' do
      subject do
        described_class.new(
          metric_name: metric_name,
          value: nil,
          repository: repository,
          time_period: time_period,
          error: 'Test error'
        )
      end

      it 'shows error message' do
        expect(subject.to_s).to include('ERROR')
        expect(subject.to_s).to include('Test error')
      end
    end
  end
end
