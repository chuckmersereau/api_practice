require 'rails_helper'

describe DataServerStumo do
  let!(:organization) { create(:organization, name: 'Student Mobilization') }
  let!(:person)       { create(:person) }

  let!(:organization_account) do
    build(:organization_account, person: person, organization: organization)
  end

  context '.import_profiles' do
    let(:data_server) { described_class.new(organization_account) }

    it 'in US format' do
      stub_request(:post, /.*profiles/).to_return(
        body: 'ROLE_CODE,ROLE_DESCRIPTION'\
              "\n"\
              ',"Staff Account (0559826)"'
      )
      stub_request(:post, /.*accounts/).to_return(
        body: '"EMPLID","EFFDT","BALANCE","ACCT_NAME"'\
              "\n"\
              '"0000000","2012-03-23 16:01:39.0","123.45","Test Account"'\
              "\n"
      )
      expect(data_server).to receive(:import_profile_balance)

      expect do
        data_server.import_profiles
      end.to change(DesignationProfile, :count).by(1)
    end

    it 'in DataServer format' do
      stub_request(:post, /.*profiles/).to_return(
        body: "\xEF\xBB\xBF"\
              '"PROFILE_CODE","PROFILE_DESCRIPTION"'\
              "\r\n"\
              '"1769360689","MPD Coach (All Staff Donations)"'\
              "\r\n"\
              '"1769360688","My Campus Accounts"'\
              "\r\n"\
              '"","My Staff Account"'\
              "\r\n"
      )

      stub_request(:post, /.*accounts/).to_return(
        body: '"EMPLID","EFFDT","BALANCE","ACCT_NAME"'\
              "\n"\
              '"0000000","2012-03-23 16:01:39.0","123.45","Test Account"'\
              "\n"
      )

      expect do
        data_server.import_profiles
      end.to change(DesignationProfile, :count).by(3)
    end

    context 'when the code or name of a profile has changed' do
      before do
        organization.designation_profiles.create!(
          [
            {
              user_id: person.id,
              code: '1769360689',
              name: 'MPD Coach (All Staff Donations)'
            },
            {
              user_id: person.id,
              code: '1769360688',
              name: 'My Campus Accounts'
            },
            {
              user_id: person.id,
              code: '',
              name: 'My Staff Account'
            },
            {
              user_id: person.id,
              code: '1769360680',
              name: 'My Missions Account'
            }
          ]
        )

        stub_request(:post, /.*profiles/).to_return(
          body: "\xEF\xBB\xBF"\
                '"PROFILE_CODE","PROFILE_DESCRIPTION"'\
                "\r\n"\
                '"1769360689","MY NEW PROFILE NAME"'\
                "\r\n"\
                '"NEW-PROFILE-CODE","My Campus Accounts"'\
                "\r\n"\
                '"","My Staff Account"'\
                "\r\n"\
                '"1769360680",""'\
                "\r\n"
        )

        stub_request(:post, /.*accounts/).to_return(
          body: '"EMPLID","EFFDT","BALANCE","ACCT_NAME"'\
                "\n"\
                '"0000000","2012-03-23 16:01:39.0","123.45","Test Account"'\
                "\n"
        )
      end

      let(:coach_profile) do
        organization.designation_profiles.find_by(code: '1769360689')
      end

      let(:campus_profile) do
        organization.designation_profiles.find_by(code: '1769360688')
      end

      let(:missions_profile) do
        organization.designation_profiles.find_by(code: '1769360680')
      end

      it 'only makes a new profile if the code has changed' do
        expect do
          data_server.import_profiles
        end.to change(DesignationProfile, :count).by(1)
      end

      it "updates a profile's name if code exists AND name is provided" do
        expect(coach_profile.name).to    eq 'MPD Coach (All Staff Donations)'
        expect(campus_profile.name).to   eq 'My Campus Accounts'
        expect(missions_profile.name).to eq 'My Missions Account'

        data_server.import_profiles

        # gave new name
        expect(coach_profile.reload.name).to eq 'MY NEW PROFILE NAME'

        # gave diff code but same name -
        # made a new profile & didn't change existing one
        expect(campus_profile.reload.name).to eq 'My Campus Accounts'

        # same code but missing name -
        # doesn't change name of existing profile
        expect(missions_profile.reload.name).to eq 'My Missions Account'
      end
    end
  end
end
