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
end
