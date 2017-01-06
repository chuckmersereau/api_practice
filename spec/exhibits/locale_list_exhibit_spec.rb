require 'spec_helper'

describe LocaleListExhibit do
  let(:context) { double }
  let(:exhibit) { LocaleListExhibit.new(locale_list, context) }
  let(:locale_list) { Constants::LocaleList.new }

  context '.applicable_to?' do
    it 'applies only to LocaleList and not other stuff' do
      expect(LocaleListExhibit.applicable_to?(Constants::LocaleList.new)).to be true
      expect(LocaleListExhibit.applicable_to?(Address.new)).to be false
    end
  end

  context '#display_name' do
    it 'renders the code in parentheses' do
      expect(exhibit.display_name('Urdu', 'ur')).to eq 'Urdu (ur)'
      expect(exhibit.display_name('Thai', :th)).to eq 'Thai (th)'
    end
  end
end
