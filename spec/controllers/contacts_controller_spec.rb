require 'spec_helper'

describe ContactsController do
  render_views

  describe 'when signed in' do
    let(:user) { create(:user_with_account) }
    let!(:contact) { create(:contact, account_list: user.account_lists.first) }

    before(:each) do
      sign_in(:user, user)
    end

    describe '#index' do
      let(:contact2) { create(:contact, name: 'Z', account_list: user.account_lists.first) }

      before do
        donor_account = create(:donor_account, master_company: create(:master_company))
        contact2.donor_accounts << donor_account
      end

      it 'gets all' do
        get :index
        response.should be_success
        assigns(:contacts).length.should.should == 2
      end

      it "filters out people you don't want to contact even when no filter is set" do
        contact.update_attributes(status: 'Not Interested')
        get :index
        response.should be_success
        assigns(:contacts).length.should == 1
      end

      it 'gets people' do
        get :index, filters: { contact_type: 'person' }
        response.should be_success
        assigns(:contacts).should == [contact]
      end

      it 'gets companies' do
        get :index, filters: { contact_type: 'company' }
        response.should be_success
        assigns(:contacts).should == [contact2]
      end

      it 'filters by tag' do
        contact.update_attributes(tag_list: 'asdf')
        get :index, filters: { tags: 'asdf' }
        response.should be_success
        assigns(:contacts).should == [contact]
      end

      it "doesn't display duplicate rows when filtering by Newsletter Recipients With Mailing Address" do
        contact.update_attributes(send_newsletter: 'Physical')
        2.times do
          contact.addresses << create(:address, addressable: contact)
        end

        get :index, filters: { newsletter: 'address' }
        assigns(:contacts).length.should == 1
      end

      it "doesn't display duplicate rows when filtering by Newsletter Recipients With Email Address" do
        contact.update_attributes(send_newsletter: 'Email')
        p = create(:person)
        contact.people << p
        2.times do
          create(:email_address, person: p)
        end

        get :index, filters: { newsletter: 'email' }
        assigns(:contacts).length.should == 1
      end

      it 'does not cause an error for the export and still assigns contact' do
        get :index, format: 'csv'
        expect(assigns(:contacts).size).to eq(2)
      end

      it 'does not have an error when exporting after searches' do
        get :index, format: 'csv', filters: { newsletter: 'email' }
      end

      it 'does not have an error when exporting after searches' do
        get :index, format: 'csv', filters: { newsletter: 'address' }
      end
    end

    describe '#show' do
      it 'should find a contact in the current account list' do
        get :show, id: contact.id
        response.should be_success
        contact.should == assigns(:contact)
      end
    end

    describe '#edit' do
      it 'should edit a contact in the current account list' do
        get :edit, id: contact.id
        response.should be_success
        contact.should == assigns(:contact)
      end
    end

    describe '#new' do
      it 'should render the new template' do
        get :new
        response.should be_success
        response.should render_template('new')
      end
    end

    describe '#create' do
      it 'should create a good record' do
        expect do
          post :create, contact: { name: 'foo' }
          contact = assigns(:contact)
          contact.errors.full_messages.should == []
          response.should redirect_to(contact)
        end.to change(Contact, :count).by(1)
      end

      it "doesn't create a contact without a name" do
        post :create, contact: { name: '' }
        assigns(:contact).errors.full_messages.should == ["Name can't be blank"]
        response.should be_success
      end
    end

    describe '#update' do
      it 'updates a contact when passed valid attributes' do
        put :update, id: contact.id, contact: { name: 'Bob' }
        contact = assigns(:contact)
        contact.name.should == 'Bob'
        response.should redirect_to(contact)
      end

      it "doesn't update a contact when passed invalid attributes" do
        put :update, id: contact.id, contact: { name: '' }
        assigns(:contact).errors.full_messages.should == ["Name can't be blank"]
        response.should be_success
      end
    end

    describe '#destroy' do
      it 'should hide a contact' do
        contact # instantiate object
        delete :destroy, id: contact.id

        contact.reload.status.should == 'Never Ask'
      end
    end

    describe '#bulk_update' do
      it "doesn't error out when all the attributes to update are blank" do
        xhr :put, :bulk_update, bulk_edit_contact_ids: '1', contact: { send_newsletter: '' }
        response.should be_success
      end

      it "correctly updates the 'next ask' field" do
        xhr :put, :bulk_update,  'bulk_edit_contact_ids' => contact.id, 'contact' => { 'next_ask(2i)' => '3', 'next_ask(3i)' => '3', 'next_ask(1i)' => '2012' }
        contact.reload.next_ask.should == Date.parse('2012-03-03')
      end

      it "ignores a partial 'next ask' value" do
        xhr :put, :bulk_update,  'bulk_edit_contact_ids' => contact.id, 'contact' => { 'next_ask(3i)' => '3', 'next_ask(1i)' => '2012' }
        contact.reload.next_ask.should.nil?
      end
    end

    describe '#find_duplicates' do
      it 'does not assign contact_sets and people_sets' do
        contact_sets = [[contact, create(:contact)]]
        people_sets = []
        expect(ContactDuplicatesFinder).to receive(:new).with(user.account_lists.first, user)
          .and_return(double(dup_contacts_then_people: [contact_sets, people_sets]))

        xhr :get, :find_duplicates, format: :js
        expect(response).to be_success
        expect(assigns(:contact_sets)).to eq(contact_sets)
        expect(assigns(:people_sets)).to eq(people_sets)
      end
    end

    describe '#save_referrals' do
      it 'sets the address as primary for the created contact' do
        expect do
          xhr :post, :save_referrals, id: contact.id,
                                      account_list: { contacts_attributes: { nil => { first_name: 'John', street: '1 Way' } } }
        end.to change(Address, :count).from(0).to(1)
        expect(Address.first.primary_mailing_address).to be_true
      end
    end

    describe 'POST merge_sets for contact duplicates' do
      let(:contact1) { create(:contact, name: 'Joe Doe', account_list: user.account_lists.first) }
      let(:contact2) { create(:contact, name: 'Joe Doe', account_list: user.account_lists.first) }
      let(:contact_ids) { [contact1.id, contact2.id].map { |x| x }.join(',') }

      before { request.env['HTTP_REFERER'] = '/' }

      it 'merges two contacts  where the winner is the first in the list' do
        params = { merge_sets: [contact_ids],
                   dup_contact_winner: { contact_ids => contact1.id } }
        post :merge, params
        expect(Contact.find_by_id(contact2.id)).to be_nil
      end

      it 'merges two contacts where the winner is the second in the list' do
        params = { merge_sets: [contact_ids],
                   dup_contact_winner: { contact_ids => contact2.id } }
        post :merge, params
        expect(Contact.find_by_id(contact1.id)).to be_nil
      end
    end
  end
end
