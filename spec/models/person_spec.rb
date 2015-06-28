require 'spec_helper'

describe Person do
  let(:person) { create(:person) }

  describe 'creating a person' do
    it 'should set master_person_id' do
      person = Person.create!(build(:person, master_person: nil).attributes.slice('first_name'))
      expect(person.master_person_id).not_to be_nil
    end
  end

  describe 'saving family relationships' do
    it 'should create a family relationship' do
      family_relationship = build(:family_relationship, person: nil, related_person: create(:person))
      expect do
        person.family_relationships_attributes = { '0' => family_relationship.attributes.with_indifferent_access.except(:id, :person_id, :created_at, :updated_at) }
      end.to change(FamilyRelationship, :count).by(1)
    end
    it 'should destroy a family relationship' do
      family_relationship = create(:family_relationship, person: person, related_person: create(:person))
      expect do
        person.family_relationships_attributes = { '0' => family_relationship.attributes.merge(_destroy: '1').with_indifferent_access }
      end.to change(FamilyRelationship, :count).from(1).to(0)
    end
    it 'should update a family relationship' do
      family_relationship = create(:family_relationship, person: person)
      family_relationship_attributes = family_relationship.attributes.merge!(relationship: family_relationship.relationship + 'boo')
                                       .with_indifferent_access.except(:person_id, :updated_at, :created_at)
      person.family_relationships_attributes = { '0' => family_relationship_attributes }
      expect(person.family_relationships.first.relationship).to eq(family_relationship.relationship + 'boo')
    end
  end

  describe '.save' do
    it 'gracefully handles having the same FB account assigned twice' do
      fb_account = create(:facebook_account, person: person)
      person.update_attributes('facebook_accounts_attributes' => {
                                 '0' => {
                                   '_destroy' => 'false',
                                   'url' => 'http://facebook.com/profile.php?id=500015648'
                                 },
                                 '1' => {
                                   '_destroy' => 'false',
                                   'url' => 'http://facebook.com/profile.php?id=500015648'
                                 },
                                 '1354203866590' => {
                                   '_destroy' => 'false',
                                   'id' => fb_account.id,
                                   'url' => fb_account.url
                                 }
                               })
      expect(person.facebook_accounts.length).to eq(2)
    end

    it 'gracefully handles having an fb account with a blank url' do
      person.update_attributes('facebook_accounts_attributes' => {
                                 '0' => {
                                   '_destroy' => 'false',
                                   'url' => ''
                                 }
                               })
      expect(person.facebook_accounts.length).to eq(0)
    end

    describe 'saving deceased person' do
      it 'should remove persons name from greeting' do
        contact = create(:contact)
        person.first_name = 'Jack'
        contact.people << person
        contact.people << create(:person, first_name: 'Jill')
        contact.name = 'Smith, Jack and Jill'
        contact.save!
        person.reload
        person.deceased = true
        person.save!
        contact.reload
        expect(contact.name).to_not include('Jack')
      end

      it "keeps a single deceased person's greeting and name" do
        contact = create(:contact)
        person.first_name = 'Jack'
        person.last_name = 'Smith'
        contact.people << person
        contact.name = 'Smith, Jack'
        contact.save
        person.reload
        person.deceased = true
        person.save!
        contact.reload
        expect(contact.name).to eq('Smith, Jack')
        expect(contact.greeting).to eq('Jack')
      end

      it 'has no stack overflow if deceased person modified, and keeps single deceased person in greeting, etc.' do
        contact = create(:contact)
        person.first_name = 'Jack'
        contact.people << person
        contact.name = 'Smith, Jack'
        contact.save!
        person.reload
        person.deceased = true
        person.save!
        contact.reload

        expect(contact.name).to eq('Smith, Jack')
        expect(contact.greeting).to eq('Jack')
        expect(contact.primary_person).to eq(person)

        person.reload
        person.occupation = 'random change'
        person.save # Used to cause a stack overflow
      end

      it 'has no stack overflow if person in deceased couple is modified' do
        person.first_name = 'Jack'
        person.last_name = 'Smith'
        person.deceased = true
        person.save!

        contact = create(:contact)
        contact.people << person
        contact.people << create(:person, deceased: true, first_name: 'Jill', last_name: 'Smith')
        contact.name = 'Smith, Jack and Jill'
        contact.save

        contact.update_column(:greeting, '')

        person.reload
        person.occupation = 'random change'
        contact.save # Used to cause a stack overflow
      end
    end
  end

  context '#email=' do
    let(:email) { 'test@example.com' }

    it 'creates an email' do
      expect do
        person.email = email
        expect(person.email_addresses.first.email).to eq(email)
      end.to change(EmailAddress, :count).from(0).to(1)
    end
  end

  context '#email_address=' do
    it "doesn't barf when someone puts in the same email address twice" do
      person = build(:person)

      email_addresses_attributes = {
        '1378494030167' => {
          '_destroy' => 'false',
          'email' => 'monfortcody@yahoo.com',
          'primary' => '0'
        },
        '1378494031857' => {
          '_destroy' => 'false',
          'email' => 'monfortcody@yahoo.com',
          'primary' => '0'
        }
      }

      person.email_addresses_attributes = email_addresses_attributes

      person.save
    end
  end

  context '#email_addresses_attributes=' do
    let(:person) { create(:person) }
    let(:email) { create(:email_address, person: person) }

    it 'deletes nested email address' do
      email_addresses_attributes = {
        '0' => {
          '_destroy' => '1',
          'email' => 'monfortcody@yahoo.com',
          'primary' => '0',
          'id' => email.id.to_s
        }
      }

      expect do
        person.email_addresses_attributes = email_addresses_attributes

        person.save
      end.to change(person.email_addresses, :count).by(-1)
    end

    it 'updates an existing email address' do
      email_addresses_attributes = {
        '0' => {
          '_destroy' => '0',
          'email' => 'asdf' + email.email,
          'primary' => '1',
          'id' => email.id.to_s
        }
      }

      expect do
        person.email_addresses_attributes = email_addresses_attributes

        person.save
      end.to_not change(person.email_addresses, :count)
    end

    it "doesn't create a duplicate if updating to an address that already exists" do
      email2 = create(:email_address)
      person.email_addresses << email2

      email_addresses_attributes = {
        '0' => {
          '_destroy' => '0',
          'email' => email.email,
          'primary' => '0',
          'id' => email2.id.to_s
        }
      }

      expect do
        person.email_addresses_attributes = email_addresses_attributes

        person.save
      end.to change(person.email_addresses, :count).by(-1)
    end
  end

  context '#merge' do
    let(:winner) { create(:person) }
    let(:loser) { create(:person) }

    it "shouldn't fail if the winner has the same facebook account as the loser" do
      fb_account = create(:facebook_account, person: winner)
      create(:facebook_account, person: loser, remote_id: fb_account.remote_id)

      # this shouldn't blow up
      expect do
        winner.merge(loser)
      end.to change(Person::FacebookAccount, :count)
    end

    it "should move loser's facebook over" do
      loser = create(:person)
      fb = create(:facebook_account, person: loser)

      winner.merge(loser)
      expect(winner.facebook_accounts).to eq([fb])
    end

    it "should move loser's twitter over" do
      loser = create(:person)
      create(:twitter_account, person: loser)

      winner.merge(loser)
      expect(winner.twitter_accounts).not_to be_empty
    end

    it 'moves pictures over' do
      picture = create(:picture, picture_of: loser)
      winner.merge(loser)
      expect(winner.pictures).to include(picture)
    end

    it 'copies over master person sources' do
      loser.master_person.master_person_sources.create(organization_id: 1, remote_id: 2)
      expect do
        winner.merge(loser)
      end.to change(winner.master_person.master_person_sources, :count).from(0).to(1)
    end

    it 'merges the master people of unrelated people so master person source stays unique per org' do
      loser.master_person.master_person_sources.create(organization_id: 1, remote_id: 2)
      loser_master_person_id = loser.master_person.id
      other_person_loser_master = create(:person, master_person: loser.master_person)
      expect { winner.merge(loser) }.to_not raise_error
      expect(other_person_loser_master.reload.master_person).to eq(winner.master_person)
      expect(MasterPerson.find_by_id(loser_master_person_id)).to be_nil
    end

    it 'merges two people correctly if they have the same master person' do
      loser.update(master_person: winner.master_person)
      expect(loser.master_person).to_not be_nil
      orig_winner_master_person_id = winner.master_person_id
      expect { winner.merge(loser) }.to_not raise_error
      expect(winner.master_person_id).to eq(orig_winner_master_person_id)
      expect(winner.master_person).to_not be_nil
    end

    it 'creates a Version with a related_object_id', versioning: true do
      p1 = create(:person)
      p2 = create(:person)
      c = create(:contact)
      p1.contacts << c
      p2.contacts << c
      expect do
        p1.merge(p2)
      end.to change(Version, :count).by(2) # 2 from the .destroy call and then the transaction commit I think

      v = Version.last
      expect(v.related_object_id).to eq(c.id)
    end
  end

  context '#not_same_as?' do
    it 'considers two people different unless not_duplicated_with is set' do
      p1 = create(:person)
      p2 = create(:person)
      expect(p1.not_same_as?(p2)).to be false
      expect(p2.not_same_as?(p1)).to be false

      p1.not_duplicated_with = p2.id.to_s

      expect(p1.not_same_as?(p2)).to be true
      expect(p2.not_same_as?(p1)).to be true
    end
  end

  context '#sync_with_mailchimp' do
    let(:mail_chimp_account) { build(:mail_chimp_account) }
    let(:contact) { create(:contact, send_newsletter: 'Email') }

    before do
      expect(person).to receive(:mail_chimp_account).at_least(:once).and_return(mail_chimp_account)
      contact.people << person
      person.email_address = { email: 'test@example.com' }
      person.save
      person.reload
    end

    it 'does not subscribe when a non-related field is updated' do
      expect(mail_chimp_account).to_not receive(:queue_subscribe_person).with(person)
      expect(mail_chimp_account).to_not receive(:queue_unsubscribe_person).with(person)
      person.update(occupation: 'not mailchimp related')
    end

    it 'subscribes (to update) a person when their first name changes' do
      expect_subscribe_on_update(first_name: 'new-first-name')
    end

    it 'subscribes (to update) a person when their last name changes' do
      expect_subscribe_on_update(last_name: 'new-last-name')
    end

    it 'subscribes a previously opted-out person if they are opted back in' do
      person.update_column(:optout_enewsletter, true)
      expect_subscribe_on_update(optout_enewsletter: false)
    end

    it 'unsubscribes a person if they are updated to opt out of the newsletter' do
      expect_unsubscribe_on_update(optout_enewsletter: true)
    end

    it 'works using nested email attributes (contact update had trouble with that)' do
      expect_unsubscribe_on_update(optout_enewsletter: true,
                                   email_addresses_attributes: [{ id: person.email_addresses.first.id,
                                                                  email: 'update@test.com' }])
    end

    # This is commented out because the current solution for MailChimp sync that uses callbacks
    # does not work for this case (and similar cases where you delete one email and create another).
    #
    # it 'updates an email if one no longer valid and one new via nested attributes' do
    #  email = person.email_addresses.first
    #  update_attrs = {
    #    email_addresses_attributes: [
    #      { email: email.email, primary: 0, historic: 1, id: email.id },
    #      { email: 'new@example.com', primary: 0 }
    #    ]
    #  }
    #  person.update(update_attrs)
    #  person.reload
    #  email.reload
    #  email2 = person.email_addresses.find_by(email: 'new@example.com')
    #  expect(email.historic).to be_true
    #  expect(email.primary).to be_false
    #  expect(email2.primary).to be_true
    #
    #  expect(mail_chimp_account).to receive(:queue_update_email).with('test@example.com', 'new@example.com')
    # end

    def expect_unsubscribe_on_update(update_args)
      expect(mail_chimp_account).to receive(:queue_unsubscribe_person).with(person)
      person.update(update_args)
    end

    def expect_subscribe_on_update(update_args)
      expect(mail_chimp_account).to receive(:queue_subscribe_person).with(person)
      person.update(update_args)
    end
  end
end
