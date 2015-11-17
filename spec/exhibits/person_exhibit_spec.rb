require 'spec_helper'
describe PersonExhibit do
  let(:exhib) { PersonExhibit.new(person, context) }
  let(:person) { build(:person) }
  let(:context) { double(root_url: 'https://mpdx.org') }

  context '#avatar' do
    it 'ignores images with nil content' do
      allow(person).to receive(:facebook_account).and_return(nil)
      allow(person).to receive(:primary_picture).and_return(double(image: double(url: nil)))
      allow(person).to receive(:gender).and_return(nil)

      expect(exhib.avatar).to eq('https://mpdx.org/assets/avatar.png')
    end

    it 'uses facebook image if remote_id set' do
      allow(person).to receive(:facebook_account).and_return(double(remote_id: 1234))
      allow(person).to receive(:primary_picture).and_return(double(image: double(url: nil)))

      expect(exhib.avatar).to eq('https://graph.facebook.com/1234/picture?type=square')
    end

    it 'uses default avatar if remote_id not present' do
      allow(person).to receive(:facebook_account).and_return(double(remote_id: nil))
      allow(person).to receive(:primary_picture).and_return(double(image: double(url: nil)))
      allow(person).to receive(:gender).and_return(nil)

      expect(exhib.avatar).to eq('https://mpdx.org/assets/avatar.png')
    end
  end

  context '#facebook_link' do
    it 'gives blank if person has no facebook account' do
      expect(exhib.facebook_link).to be_blank
    end

    it 'links to the facebook account url if person has an account' do
      exhib = PersonExhibit.new(person, ActionView::Base.new)
      allow(person).to receive(:facebook_account) { double(url: 'facebook.com/joe') }
      expect(exhib.facebook_link).to eq '<a target="_blank" class="fa fa-facebook-square" href="facebook.com/joe"></a>'
    end
  end

  context '#twitter_link' do
    it 'gives blank if person has no twitter account' do
      expect(exhib.twitter_link).to be_blank
    end

    it 'links to the twitter account url if the person has a twitter account' do
      exhib = PersonExhibit.new(person, ActionView::Base.new)
      allow(person).to receive(:twitter_account) { double(url: 'twitter.com/joe') }
      expect(exhib.twitter_link).to eq '<a target="_blank" class="fa fa-twitter-square" href="twitter.com/joe"></a>'
    end
  end

  context '#email_link' do
    it 'gives blank if person has no primary email address' do
      expect(exhib.email_link).to be_blank
    end

    it 'links to the email mailto url if person has a primary email' do
      person.email_address = { email: 'joe@example.com', primary: true }
      person.save
      exhib = PersonExhibit.new(person, ActionView::Base.new)
      expect(exhib.email_link).to eq '<a class="fa fa-envelope" href="mailto:joe@example.com"></a>'
    end
  end
end
