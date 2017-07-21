require 'rails_helper'

describe TntImport::TntCodes do
  describe '.task_status_completed?' do
    it 'returns true' do
      [2, '2'].each do |input|
        expect(described_class.task_status_completed?(input)).to eq(true)
      end
    end

    it 'returns false' do
      [0, '0', nil, 1, '1'].each do |input|
        expect(described_class.task_status_completed?(input)).to eq(false)
      end
    end
  end

  describe '.task_type' do
    it 'only includes types that are supported by MPDX' do
      types = described_class::TNT_TASK_CODES_MAPPED_TO_MPDX_TASK_TYPES.keys.collect do |tnt_type_code|
        described_class.task_type(tnt_type_code)
      end
      expect(types - Task::TASK_ACTIVITIES).to eq([])
      expect(described_class::TNT_TASK_CODES_MAPPED_TO_MPDX_TASK_TYPES.values - Task::TASK_ACTIVITIES).to eq([])
    end
  end

  describe '.task_status_completed?' do
    it 'is true for 2' do
      expect(described_class.task_status_completed?(2)).to eq(true)
    end
    it 'is false for other values' do
      [0, 1, 3, nil, 'string'].each do |test_value|
        expect(described_class.task_status_completed?(test_value)).to eq(false)
      end
    end
  end

  describe '.history_result' do
    it 'only includes results that are supported by MPDX' do
      results = described_class::TNT_TASK_RESULT_CODES_MAPPED_TO_MPDX_TASK_RESULTS.keys.collect do |tnt_result_code|
        described_class.history_result(tnt_result_code)
      end
      acceptable_result_values = Task.all_result_options.values.flatten.uniq
      expect(results - acceptable_result_values).to eq([])
      expect(described_class::TNT_TASK_RESULT_CODES_MAPPED_TO_MPDX_TASK_RESULTS.values - acceptable_result_values).to eq([])
    end
  end

  describe '.mpd_phase' do
    it 'only includes statuses that are supported by MPDX, including nil' do
      statuses = described_class::TNT_MPD_PHASE_CODES_MAPPED_TO_MPDX_CONTACT_STATUSES.keys.collect do |tnt_mpd_code|
        described_class.mpd_phase(tnt_mpd_code)
      end
      expect(statuses - Contact::ASSIGNABLE_STATUSES).to eq([nil])
      expect(described_class::TNT_MPD_PHASE_CODES_MAPPED_TO_MPDX_CONTACT_STATUSES.values - Contact::ASSIGNABLE_STATUSES).to eq([nil])
    end
  end
end
