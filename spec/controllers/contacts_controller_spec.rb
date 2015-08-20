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
        expect(response).to be_success
        expect(assigns(:contacts).length).to eq(2)
      end

      it "filters out people you don't want to contact even when no filter is set" do
        contact.update_attributes(status: 'Not Interested')
        get :index
        expect(response).to be_success
        expect(assigns(:contacts).length).to eq(1)
      end

      it 'gets people' do
        get :index, filters: { contact_type: 'person' }
        expect(response).to be_success
        expect(assigns(:contacts)).to eq([contact])
      end

      it 'gets companies' do
        get :index, filters: { contact_type: 'company' }
        expect(response).to be_success
        expect(assigns(:contacts)).to eq([contact2])
      end

      it 'filters by tag' do
        contact.update_attributes(tag_list: 'asdf')
        get :index, filters: { tags: 'asdf' }
        expect(response).to be_success
        expect(assigns(:contacts)).to eq([contact])
      end

      it "doesn't display duplicate rows when filtering by Newsletter Recipients With Mailing Address" do
        contact.update_attributes(send_newsletter: 'Physical')
        2.times do
          contact.addresses << create(:address, addressable: contact)
        end

        get :index, filters: { newsletter: 'address' }
        expect(assigns(:contacts).length).to eq(1)
      end

      it "doesn't display duplicate rows when filtering by Newsletter Recipients With Email Address" do
        contact.update_attributes(send_newsletter: 'Email')
        p = create(:person)
        contact.people << p
        2.times do
          create(:email_address, person: p)
        end

        get :index, filters: { newsletter: 'email' }
        expect(assigns(:contacts).length).to eq(1)
      end

      it 'does error if the newsletter and address info filters are combined' do
        expect do
          get :index, filters: { newsletter: 'address', contact_info_addr: 'No' }
        end.to_not raise_error
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

      it 'does not export addresses with extra line breaks' do
        address = create(:address, street: "Attn: Test\r\n123 Street")
        contact.addresses << address
        get :index, format: 'csv'
        csv = CSV.parse(response.body)
        expect(csv.second).to include "Attn: Test\n123 Street"
      end

      it 'accepts and saves per_page option' do
        get :index, per_page: 100
        view_opts = user.reload.contacts_view_options[user.account_lists.first.id.to_s]
        expect(view_opts[:per_page]).to eq '100'
      end
    end

    describe '#show' do
      it 'should find a contact in the current account list' do
        get :show, id: contact.id
        expect(response).to be_success
        expect(contact).to eq(assigns(:contact))
      end
    end

    describe '#edit' do
      it 'should edit a contact in the current account list' do
        get :edit, id: contact.id
        expect(response).to be_success
        expect(contact).to eq(assigns(:contact))
      end
    end

    describe '#new' do
      it 'should render the new template' do
        get :new
        expect(response).to be_success
        expect(response).to render_template('new')
      end
    end

    describe '#create' do
      it 'should create a good record' do
        expect do
          post :create, contact: { name: 'foo' }
          contact = assigns(:contact)
          expect(contact.errors.full_messages).to eq([])
          expect(response).to redirect_to(contact)
        end.to change(Contact, :count).by(1)
      end

      it "doesn't create a contact without a name" do
        post :create, contact: { name: '' }
        expect(assigns(:contact).errors.full_messages).to eq(["Name can't be blank"])
        expect(response).to be_success
      end
    end

    describe '#update' do
      it 'updates a contact when passed valid attributes' do
        put :update, id: contact.id, contact: { name: 'Bob' }
        contact = assigns(:contact)
        expect(contact.name).to eq('Bob')
        expect(response).to redirect_to(contact)
      end

      it "doesn't update a contact when passed invalid attributes" do
        put :update, id: contact.id, contact: { name: '' }
        expect(assigns(:contact).errors.full_messages).to eq(["Name can't be blank"])
        expect(response).to be_success
      end
    end

    describe '#destroy' do
      it 'should hide a contact' do
        delete :destroy, id: contact.id
        expect(contact.reload.status).to eq('Never Ask')
      end
    end

    describe '#bulk_destroy' do
      it 'should hide multiple contacts' do
        c2 = create(:contact, account_list: user.account_lists.first)
        delete :bulk_destroy, ids: [contact.id, c2.id]

        expect(contact.reload.status).to eq 'Never Ask'
        expect(c2.reload.status).to eq 'Never Ask'
      end
    end

    describe '#bulk_update' do
      it "doesn't error out when all the attributes to update are blank" do
        xhr :put, :bulk_update, bulk_edit_contact_ids: '1', contact: { send_newsletter: '' }
        expect(response).to be_success
      end

      it "correctly updates the 'next ask' field" do
        xhr :put, :bulk_update,  bulk_edit_contact_ids: contact.id, contact:
                    { 'next_ask(2i)': '3', 'next_ask(3i)': '3', 'next_ask(1i)': '2012' }
        expect(contact.reload.next_ask).to eq(Date.parse('2012-03-03'))
      end

      it 'queues MailChimp sync' do
        queued = false
        allow_any_instance_of(MailChimpAccount).to receive(:notify_contacts_changed)
          .with([contact.id]) { queued = true }
        create(:mail_chimp_account, account_list: user.account_lists.first)
        xhr :put, :bulk_update, bulk_edit_contact_ids: contact.id, contact: { send_newsletter: 'Email' }
        expect(queued).to be true
      end

      it "ignores a partial 'next ask' value" do
        xhr :put, :bulk_update,  bulk_edit_contact_ids: contact.id, contact:
                    { 'next_ask(3i)': '3', 'next_ask(1i)': '2012' }
        expect(contact.reload.next_ask).to be_nil
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
      it 'creates a contact and sets the referrer' do
        expect do
          xhr :post, :save_referrals, id: contact.id, account_list:
                       { contacts_attributes: { 0 => { first_name: 'John', street: '1 Way' } } }
        end.to change(Contact, :count).by(1)
        expect(Contact.last.first_name).to eq('John')
        expect(Contact.last.referrals_to_me.to_a).to eq([contact])
      end
    end

    describe '#save_multi' do
      it 'creates a contact' do
        expect do
          xhr :post, :save_multi, account_list:
                       { contacts_attributes: { 0 => { first_name: 'John', street: '1 Way' } } }
        end.to change(Contact, :count).by(1)
        expect(Contact.last.first_name).to eq('John')
      end
    end

    describe 'POST merge_sets for contact duplicates' do
      let(:contact1) { create(:contact, name: 'Joe Doe', account_list: user.account_lists.first) }
      let(:contact2) { create(:contact, name: 'Joe Doe', account_list: user.account_lists.first) }
      let(:contact_ids) { [contact1.id, contact2.id].map { |x| x }.join(',') }

      before { request.env['HTTP_REFERER'] = '/' }

      it 'merges and makes dup_contact_winner the first contact in the list' do
        params = { merge_sets: [contact_ids],
                   dup_contact_winner: { contact_ids => contact1.id } }
        post :merge, params
        expect(Contact.find_by_id(contact2.id)).to be_nil
      end

      it 'merges and makes dup_contact_winner the second contact in the list' do
        params = { merge_sets: [contact_ids],
                   dup_contact_winner: { contact_ids => contact2.id } }
        post :merge, params
        expect(Contact.find_by_id(contact1.id)).to be_nil
      end

      it 'merges when no dup_contact_winner present and contact with most people wins' do
        contact2.people << create(:person)
        post :merge, merge_sets: [contact_ids]
        expect(Contact.find_by(id: contact1.id)).to be_nil
      end
    end
  end
end
