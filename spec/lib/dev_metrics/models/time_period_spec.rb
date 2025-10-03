# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Models::TimePeriod do
  subject { described_class.new(start_date, end_date) }

  let(:start_date) { Time.now - (30 * 24 * 60 * 60) }
  let(:end_date) { Time.now }

  it_behaves_like 'a model with hash conversion'

  describe '#initialize' do
    it 'sets start and end dates' do
      expect(subject.start_date).to be_within(1).of(start_date)
      expect(subject.end_date).to be_within(1).of(end_date)
    end

    context 'with string dates' do
      let(:start_date) { '2024-01-01' }
      let(:end_date) { '2024-01-31' }

      it 'parses string dates correctly' do
        expect(subject.start_date).to be_a(Time)
        expect(subject.end_date).to be_a(Time)
      end
    end

    context 'with integer (days ago)' do
      let(:start_date) { 30 }
      let(:end_date) { nil }

      it 'converts days ago to time' do
        expect(subject.start_date).to be < Time.now
        expect(subject.end_date).to be_within(60).of(Time.now)
      end
    end

    context 'with invalid dates' do
      it 'raises error for nil start date' do
        expect { described_class.new(nil, end_date) }.to raise_error(ArgumentError)
      end

      it 'raises error when start date is after end date' do
        expect { described_class.new(end_date, start_date) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.default' do
    it 'creates 30-day period ending now' do
      period = described_class.default
      expect(period.end_date).to be_within(60).of(Time.now)
      expect(period.duration_days).to be_within(1).of(30)
    end
  end

  describe '.last_week' do
    it 'creates 7-day period' do
      period = described_class.last_week
      expect(period.duration_days).to be_within(1).of(7)
    end
  end

  describe '.last_month' do
    it 'creates 30-day period' do
      period = described_class.last_month
      expect(period.duration_days).to be_within(1).of(30)
    end
  end

  describe '#duration_days' do
    it 'calculates correct duration' do
      expected_days = ((end_date - start_date) / (24 * 60 * 60)).round
      expect(subject.duration_days).to eq(expected_days)
    end
  end

  describe '#contains?' do
    let(:middle_date) { start_date + ((end_date - start_date) / 2) }
    let(:before_date) { start_date - (24 * 60 * 60) }
    let(:after_date) { end_date + (24 * 60 * 60) }

    it 'returns true for date within period' do
      expect(subject.contains?(middle_date)).to be true
    end

    it 'returns false for date before period' do
      expect(subject.contains?(before_date)).to be false
    end

    it 'returns false for date after period' do
      expect(subject.contains?(after_date)).to be false
    end

    it 'handles string dates' do
      middle_string = middle_date.strftime('%Y-%m-%d %H:%M:%S')
      expect(subject.contains?(middle_string)).to be true
    end
  end

  describe '#git_since_format' do
    it 'returns date in Git format' do
      expect(subject.git_since_format).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end

  describe '#git_until_format' do
    it 'returns date in Git format' do
      expect(subject.git_until_format).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end

  describe '#to_h' do
    it 'includes all relevant information' do
      hash = subject.to_h
      expect(hash[:start_date]).to eq(subject.start_date)
      expect(hash[:end_date]).to eq(subject.end_date)
      expect(hash[:duration_days]).to eq(subject.duration_days)
    end
  end

  describe '#to_s' do
    it 'formats dates nicely' do
      string_repr = subject.to_s
      expect(string_repr).to include(subject.start_date.strftime('%Y-%m-%d'))
      expect(string_repr).to include(subject.end_date.strftime('%Y-%m-%d'))
      expect(string_repr).to include('to')
    end
  end

  describe '#==' do
    let(:same_period) { described_class.new(start_date, end_date) }
    let(:different_period) { described_class.new(start_date - 86_400, end_date) }

    it 'returns true for same periods' do
      expect(subject).to eq(same_period)
    end

    it 'returns false for different periods' do
      expect(subject).not_to eq(different_period)
    end
  end
end
