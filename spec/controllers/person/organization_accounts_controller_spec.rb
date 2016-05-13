require 'spec_helper'

describe Person::OrganizationAccountsController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in(:user, @user)
    @org = FactoryGirl.create(:fake_org)
  end

  def valid_attributes
    @valid_attributes ||= { username: 'foo@example.com', password: 'foobar1', organization_id: @org.id }
  end

  describe 'GET new' do
    it 'assigns a new organization_account as @organization_account' do
      org = FactoryGirl.create(:fake_org)
      xhr :get, :new, id: org.id
      expect(assigns(:organization_account)).to be_a_new(Person::OrganizationAccount)
      expect(assigns(:organization)).to eq(org)
    end

    it 'fails gracefully on duplicate' do
      offline_org = create(:offline_org)
      @user.organization_accounts.create(organization: offline_org)

      xhr :get, :new, id: offline_org.id

      expect(response).to render_template('error')
      expect(assigns(:message_type)).to eq :duplicate
    end

    it 'gives a helpful message for an organization that uses Key auth' do
      org = create(:organization, uses_key_auth: true, api_class: 'Siebel')
      xhr :get, :new, id: org.id

      expect(response).to render_template('error')
      expect(assigns(:message_type)).to eq :requires_key
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Person::OrganizationAccount' do
        expect do
          xhr :post, :create, person_organization_account: valid_attributes
        end.to change(Person::OrganizationAccount, :count).by(1)
      end

      it 'assigns a newly created organization_account as @organization_account' do
        xhr :post, :create, person_organization_account: valid_attributes
        expect(assigns(:organization_account)).to be_a(Person::OrganizationAccount)
        expect(assigns(:organization_account)).to be_persisted
      end

      it 'redirects to the created organization_account' do
        xhr :post, :create, person_organization_account: valid_attributes
        expect(response).to render_template('create')
      end

      context 'but error on server' do
        it 'gracefully fails' do
          expect_any_instance_of(FakeApi).to receive(:validate_username_and_password).and_raise(RuntimeError)

          expect do
            xhr :post, :create, person_organization_account: valid_attributes
          end.to change(Person::OrganizationAccount, :count).by(0)

          expect(response).to render_template('new')
        end
      end

      it 'fails gracefully on duplicate' do
        @user.organization_accounts.create(valid_attributes)

        expect do
          xhr :post, :create, person_organization_account: valid_attributes
        end.to change(Person::OrganizationAccount, :count).by(0)

        expect(response).to render_template('new')
        oa = assigns(:organization_account)
        expect(oa.errors.first.last).to eq "Error connecting: you are already connected as #{@org.name}: foo@example.com"
      end

      it 'passes DataServerErrors on to the user' do
        dataserver_org = create(:organization)
        msg = 'This can really be whatever the DataServer feels like throwing at us...'
        e = DataServerError.new(msg)
        expect_any_instance_of(DataServer).to receive(:validate_username_and_password).and_raise(e)

        xhr :post, :create, person_organization_account: valid_attributes.merge(organization_id: dataserver_org.id)

        expect(response).to render_template('new')
        oa = assigns(:organization_account)
        expect(oa.errors.first.last).to eq msg
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved organization_account as @organization_account' do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Person::OrganizationAccount).to receive(:save).and_return(false)
        xhr :post, :create, person_organization_account: { username: '' }
        expect(assigns(:organization_account)).to be_a_new(Person::OrganizationAccount)
        expect(response).to render_template('new')
      end
    end
  end
end
