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

  # describe "GET index" do
  # it "assigns all person_organization_accounts as @person_organization_accounts" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # get :index, {}
  # expect(assigns(:person_organization_accounts)).to eq([organization_account])
  # end
  # end

  # describe "GET show" do
  # it "assigns the requested organization_account as @organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # get :show, {:id => organization_account.to_param}
  # expect(assigns(:organization_account)).to eq(organization_account)
  # end
  # end

  describe 'GET new' do
    it 'assigns a new organization_account as @organization_account' do
      org = FactoryGirl.create(:fake_org)
      xhr :get, :new, id: org.id
      expect(assigns(:organization_account)).to be_a_new(Person::OrganizationAccount)
      expect(assigns(:organization)).to eq(org)
    end
  end

  # describe "GET edit" do
  # it "assigns the requested organization_account as @organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # get :edit, {:id => organization_account.to_param}
  # expect(assigns(:organization_account)).to eq(organization_account)
  # end
  # end

  describe 'POST create' do
    before(:each) do
      # allow(@org).to receive(:api).and_return(FakeApi.new)
    end
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
        expect(oa.errors.first.last).to eq 'Error connecting: you are already connected as Organization1: foo@example.com'
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

  # describe "PUT update" do
  # describe "with valid params" do
  # it "updates the requested organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  ## Assuming there are no other person_organization_accounts in the database, this
  ## specifies that the Person::OrganizationAccount created on the previous line
  ## receives the :update_attributes message with whatever params are
  ## submitted in the request.
  # expect_any_instance_of(Person::OrganizationAccount).to receive(:update_attributes).with({'these' => 'params'})
  # put :update, {:id => organization_account.to_param, :organization_account => {'these' => 'params'}}
  # end

  # it "assigns the requested organization_account as @organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # put :update, {:id => organization_account.to_param, :organization_account => valid_attributes}
  # expect(assigns(:organization_account)).to eq(organization_account)
  # end

  # it "redirects to the organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # put :update, {:id => organization_account.to_param, :organization_account => valid_attributes}
  # expect(response).to redirect_to(organization_account)
  # end
  # end

  # describe "with invalid params" do
  # it "assigns the organization_account as @organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  ## Trigger the behavior that occurs when invalid params are submitted
  # allow_any_instance_of(Person::OrganizationAccount).to receive(:save).and_return(false)
  # put :update, {:id => organization_account.to_param, :organization_account => {}}
  # expect(assigns(:organization_account)).to eq(organization_account)
  # end

  # it "re-renders the 'edit' template" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  ## Trigger the behavior that occurs when invalid params are submitted
  # allow_any_instance_of(Person::OrganizationAccount).to receive(:save).and_return(false)
  # put :update, {:id => organization_account.to_param, :organization_account => {}}
  # expect(response).to render_template("edit")
  # end
  # end
  # end

  # describe "DELETE destroy" do
  # it "destroys the requested organization_account" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # expect {
  # delete :destroy, {:id => organization_account.to_param}
  # }.to change(Person::OrganizationAccount, :count).by(-1)
  # end

  # it "redirects to the person_organization_accounts list" do
  # organization_account = Person::OrganizationAccount.create! valid_attributes
  # delete :destroy, {:id => organization_account.to_param}
  # expect(response).to redirect_to(person_organization_accounts_url)
  # end
  # end
end
