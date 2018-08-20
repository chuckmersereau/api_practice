require 'rails_helper'

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
      family_relationship_attributes = family_relationship.attributes
                                                          .with_indifferent_access
                                                          .except(:id, :person_id, :created_at, :updated_at)
      expect do
        person.family_relationships_attributes = { '0' => family_relationship_attributes }
      end.to change(FamilyRelationship, :count).by(1)
    end
    it 'should destroy a family relationship' do
      family_relationship = create(:family_relationship, person: person, related_person: create(:person))
      expect do
        family_relationship_attributes = family_relationship.attributes.merge(_destroy: '1').with_indifferent_access
        person.family_relationships_attributes = { '0' => family_relationship_attributes }
      end.to change(FamilyRelationship, :count).from(1).to(0)
    end
    it 'should update a family relationship' do
      family_relationship = create(:family_relationship, person: person)
      family_relationship_attributes = family_relationship
                                       .attributes
                                       .merge!(relationship: family_relationship.relationship + 'boo')
                                       .with_indifferent_access
                                       .except(:person_id, :updated_at, :created_at)
      person.family_relationships_attributes = { '0' => family_relationship_attributes }
      expect(person.family_relationships.first.relationship).to eq(family_relationship.relationship + 'boo')
    end
  end

  describe '.save' do
    it 'gracefully handles having the same FB account assigned twice by id' do
      fb_account = create(:facebook_account, person: person)
      person.update_attributes('facebook_accounts_attributes' => {
                                 '0' => {
                                   '_destroy' => 'false',
                                   'username' => 'random_username'
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

    it 'gracefully handles having the same FB account assigned twice a hash of usernames' do
      fb_account = create(:facebook_account, person: person)

      attributes = {
        facebook_accounts_attributes: {
          '0' => {
            '_destroy' => 'false',
            'username' => 'same_username'
          },
          '1' => {
            '_destroy' => 'false',
            'username' => 'same_username'
          },
          '1354203866590' => {
            '_destroy' => 'false',
            'id' => fb_account.id,
            'url' => fb_account.url
          }
        }
      }

      person.update(attributes)
      expect(person.reload.facebook_accounts.length).to eq(2)
    end

    it 'gracefully handles having the same FB account assigned twice an array of usernames' do
      fb_account = create(:facebook_account, person: person)

      attributes = {
        facebook_accounts_attributes: [
          {
            '_destroy' => 'false',
            'username' => 'same_username'
          },
          {
            '_destroy' => 'false',
            'username' => 'same_username'
          },
          {
            '_destroy' => 'false',
            'id' => fb_account.id,
            'url' => fb_account.url
          }
        ]
      }

      person.update(attributes)
      expect(person.reload.facebook_accounts.length).to eq(2)
    end

    it 'gracefully handles having an fb account with a blank username' do
      person.update_attributes('facebook_accounts_attributes' => {
                                 '0' => {
                                   '_destroy' => 'false',
                                   'username' => ''
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

    context 'when all people of the contact are deceased' do
      let!(:contact) { create(:contact, name: 'Smith, Jack', status: 'Not Interested', no_appeals: false, send_newsletter: 'Email') }

      before do
        contact.people << person
        contact.save
        person.update(deceased: true, first_name: 'Jack', last_name: 'Smith')
        contact.reload
      end

      it 'should set the partner status to Never Ask' do
        expect(contact.status).to eq 'Never Ask'
      end

      it 'should set the no appeals to true' do
        expect(contact.no_appeals).to be true
      end

      it 'should set the send newsletter to none' do
        expect(contact.send_newsletter).to eq 'None'
      end
    end

    context 'when only some people of a contact are deceased' do
      let!(:contact) { create(:contact, name: 'Smith, Jack', status: 'Not Interested', no_appeals: false, send_newsletter: 'Email') }
      let!(:bob) { create(:person) }

      before do
        contact.people << bob
        contact.people << person
        contact.save
        person.update(deceased: true, first_name: 'Jack', last_name: 'Smith')
        contact.reload
      end

      it 'should not set the partner status to Never Ask' do
        expect(contact.status).to eq 'Not Interested'
      end

      it 'should not set the no appeals to true' do
        expect(contact.no_appeals).to be false
      end

      it 'should not set the send newsletter to none' do
        expect(contact.send_newsletter).to eq 'Email'
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
      expect(MasterPerson.find_by(id: loser_master_person_id)).to be_nil
    end

    it 'merges two people correctly if they have the same master person' do
      loser.update(master_person: winner.master_person)
      expect(loser.master_person).to_not be_nil
      orig_winner_master_person_id = winner.master_person_id
      expect { winner.merge(loser) }.to_not raise_error
      expect(winner.master_person_id).to eq(orig_winner_master_person_id)
      expect(winner.master_person).to_not be_nil
    end

    it 'deletes a DuplicateRecordPair if it exists' do
      winner.contacts << create(:contact)
      loser.contacts << winner.contacts.first
      expect(winner.account_lists).to eq(loser.account_lists)
      dup_pair_id = DuplicateRecordPair.create!(account_list: winner.account_lists.order(:created_at).first,
                                                record_one: winner,
                                                record_two: loser,
                                                reason: 'Testing').id
      expect { winner.merge(loser) }.to change { DuplicateRecordPair.exists?(dup_pair_id) }.from(true).to(false)
    end

    it 'does not override primary email_address' do
      loser = create(:person_with_email)
      primary_email = winner.create_primary_email_address(email: 'best@email.com')

      expect { winner.merge(loser) }.to_not change { winner.primary_email_address(true) }.from(primary_email)
    end
  end

  context '#anniversary_year' do
    it 'outputs a 4 digits year' do
      person.anniversary_year = 76
      expect(person.anniversary_year).to eq(1976)
      person.anniversary_year = 3
      expect(person.anniversary_year).to eq(2003)
      person.anniversary_year = 15
      expect(person.anniversary_year).to eq(2015)
      person.anniversary_year = 1988
      expect(person.anniversary_year).to eq(1988)
    end

    it 'returns a placeholder for a missing year' do
      person.anniversary_day = 1
      person.anniversary_month = 1
      person.anniversary_year = nil
      expect(person.anniversary_year).to eq(1900)
    end

    it 'does not return a placeholder year if day and month are also missing' do
      person.anniversary_day = nil
      person.anniversary_month = nil
      person.anniversary_year = nil
      expect(person.anniversary_year).to eq(nil)
      person.anniversary_day = 1
      expect(person.anniversary_year).to eq(nil)
      person.anniversary_day = nil
      person.anniversary_month = 1
      expect(person.anniversary_year).to eq(nil)
    end
  end

  context '#birthday_year' do
    it 'outputs a 4 digits year' do
      person.birthday_year = 76
      expect(person.birthday_year).to eq(1976)
      person.birthday_year = 3
      expect(person.birthday_year).to eq(2003)
      person.birthday_year = 15
      expect(person.birthday_year).to eq(2015)
      person.birthday_year = 1988
      expect(person.birthday_year).to eq(1988)
    end

    it 'returns a placeholder for a missing year' do
      person.birthday_day = 1
      person.birthday_month = 1
      person.birthday_year = nil
      expect(person.birthday_year).to eq(1900)
    end

    it 'does not return a placeholder year if day and month are also missing' do
      person.birthday_day = nil
      person.birthday_month = nil
      person.birthday_year = nil
      expect(person.birthday_year).to eq(nil)
      person.birthday_day = 1
      expect(person.birthday_year).to eq(nil)
      person.birthday_day = nil
      person.birthday_month = 1
      expect(person.birthday_year).to eq(nil)
    end
  end

  describe '#sync_with_mail_chimp_account' do
    let!(:person) { create(:person, primary_email_address: build(:email_address), optout_enewsletter: false) }

    it 'syncs the contact when a person optout_enewsletter changes' do
      expect(person).to receive(:trigger_mail_chimp_syncs_to_relevant_contacts)

      person.update(optout_enewsletter: true)
    end

    it 'does not sync the contact another field is changed' do
      expect(person).not_to receive(:trigger_mail_chimp_syncs_to_relevant_contacts)

      person.update(last_name: 'Boykin')
    end
  end

  describe 'title=' do
    context 'blank title' do
      it 'clears title' do
        expect { person.title = '' }.to change { person.title }.to('')
        expect { person.title = nil }.to change { person.title }.to(nil)
      end
    end

    context 'title with period' do
      it 'saves as-is' do
        expect { person.title = 'Ms.' }.to change { person.title }.to('Ms.')
      end
    end

    context 'title missing period' do
      it 'adds trailing period' do
        expect { person.title = 'Mr' }.to change { person.title }.to('Mr.')
      end
    end

    context 'title not matching pre-defined' do
      it 'saves as-is' do
        expect { person.title = 'Pastor' }.to change { person.title }.to('Pastor')
      end
    end
  end

  describe 'suffix=' do
    context 'blank suffix' do
      it 'clears suffix' do
        expect { person.suffix = '' }.to change { person.suffix }.to('')
        expect { person.suffix = nil }.to change { person.suffix }.to(nil)
      end
    end

    context 'suffix with period' do
      it 'saves as-is' do
        expect { person.suffix = 'Jr.' }.to change { person.suffix }.to('Jr.')
      end
    end

    context 'suffix missing period' do
      it 'adds trailing period' do
        expect { person.suffix = 'Sr' }.to change { person.suffix }.to('Sr.')
      end
    end

    context 'suffix not matching pre-defined' do
      it 'saves as-is' do
        expect { person.suffix = 'III' }.to change { person.suffix }.to('III')
      end
    end
  end

  describe 'profession=' do
    context 'blank occupation' do
      before { person.occupation = nil }

      it 'updates occupation field' do
        expect { person.profession = 'qwer' }.to change { person.occupation }
      end
    end

    context 'occupation is set' do
      before { person.occupation = 'asdf' }

      it 'does not update occupation field' do
        expect { person.profession = 'qwer' }.to_not change { person.occupation }
      end
    end
  end
end
