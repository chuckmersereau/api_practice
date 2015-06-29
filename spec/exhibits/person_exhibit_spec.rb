require 'spec_helper'
describe PersonExhibit do
  let(:exhib) { PersonExhibit.new(person, context) }
  let(:person) { build(:person) }
  let(:context) { double(root_url: 'https://mpdx.org') }

  context '#avatar' do
    it 'should ignore images with nil content' do
      allow(person).to receive(:facebook_account).and_return(nil)
      allow(person).to receive(:primary_picture).and_return(double(image: double(url: nil)))
      allow(person).to receive(:gender).and_return(nil)

      expect(exhib.avatar).to eq('https://mpdx.org/assets/avatar.png')
    end

    it 'should make facebook image' do
      allow(person).to receive(:facebook_account).and_return(double(remote_id: 1234))
      allow(person).to receive(:primary_picture).and_return(double(image: double(url: nil)))

      expect(exhib.avatar).to eq('https://graph.facebook.com/1234/picture?type=square')
    end
  end
end
