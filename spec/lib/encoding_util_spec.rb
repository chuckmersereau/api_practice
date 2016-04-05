require 'encoding_util'

describe EncodingUtil do
  context '.normalized_utf8' do
    it 'normalizes to uft8 without byte-order-mark, and with universal line endings' do
      [
        ['', ''],
        [1, '1'],
        [nil, ''],
        %w(USA USA),
        ["a\r\nb", "a\nb"],
        %W(a\nb a\nb),
        %w(Agapé Agapé),
        %w(Agapé Agapé),
        %w(Agapé Agapé), # ISO-8859-1
        ["Lan\xE9", 'Lané'], # ISO-8859-2
        ["\xEF\xBB\xBFAgapé".force_encoding('UTF-8'), 'Agapé'] # byte-order-mark
      ].each do |str, normalized|
        expect(EncodingUtil.normalized_utf8(str)).to eq(normalized)
      end
    end
  end
end
