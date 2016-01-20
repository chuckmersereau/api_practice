require 'spec_helper'

describe PeopleController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    @contact = create(:contact, account_list: @account_list)
  end

  def valid_attributes
    @valid_attributes ||= build(:person).attributes.except(*%w(id created_at updated_at sign_in_count current_sign_in_at
                                                               last_sign_in_at current_sign_in_ip last_sign_in_ip
                                                               master_person_id access_token))
  end

  describe 'GET show' do
    it 'assigns the requested person as @person' do
      person = @contact.people.create! valid_attributes
      get :show, id: person.to_param
      expect(assigns(:person)).to eq(person)
    end
  end

  describe 'GET new' do
    it 'assigns a new person as @person' do
      get :new, {}
      expect(assigns(:person)).to be_a_new(Person)
    end
  end

  describe 'GET edit' do
    it 'assigns the requested person as @person' do
      person = @contact.people.create! valid_attributes
      get :edit, id: person.to_param
      expect(assigns(:person)).to eq(person)
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Person' do
        expect do
          post :create,  contact_id: @contact.id, person: valid_attributes
        end.to change(Person, :count).by(1)
      end

      it 'creates a nested email' do
        expect do
          post :create,  contact_id: @contact.id,
                         person: valid_attributes.merge('email_address' => { 'email' => 'john.doe@example.com' })
        end.to change(EmailAddress, :count).by(1)
        expect(assigns(:person).email.to_s).to eq('john.doe@example.com')
      end

      it 'creates a nested phone number' do
        expect do
          post :create,  contact_id: @contact.id,
                         person: valid_attributes.merge('phone_number' => { 'number' => '213-312-2134' })
        end.to change(PhoneNumber, :count).by(1)
        expect(assigns(:person).phone_number.number).to eq('213-312-2134')
      end

      # it "creates a nested address" do
      # expect {
      # post :create, {contact_id: @contact.id,
      #      :person => valid_attributes.merge("addresses_attributes"=>{'0' => {"street"=>"boo"}})}
      # }.to change(Address, :count).by(1)
      # expect(assigns(:person).address.street).to eq("boo")
      # end

      it 'assigns a newly created person as @person' do
        post :create, contact_id: @contact.id, person: valid_attributes
        expect(assigns(:person)).to be_a(Person)
        expect(assigns(:person)).to be_persisted
      end

      it 'redirects back to the contact' do
        post :create, contact_id: @contact.id, person: valid_attributes
        expect(response).to redirect_to(@contact)
      end
    end

    describe 'with invalid params' do
      it 'assigns a newly created but unsaved person as @person' do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Person).to receive(:save).and_return(false)
        post :create, contact_id: @contact.id, person: { first_name: '' }
        expect(assigns(:person)).to be_a_new(Person)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Person).to receive(:save).and_return(false)
        post :create, contact_id: @contact.id, person: { first_name: '' }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT update' do
    describe 'with valid params' do
      it 'updates the requested person' do
        person = @contact.people.create! valid_attributes
        # Assuming there are no other people in the database, this
        # specifies that the Person created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        expect_any_instance_of(Person).to receive(:update_attributes).with('first_name' => 'params')
        put :update, id: person.to_param, person: { 'first_name' => 'params' }
      end

      it 'assigns the requested person as @person' do
        person = @contact.people.create! valid_attributes
        put :update, id: person.to_param, person: valid_attributes
        expect(assigns(:person)).to eq(person)
      end

      it 'redirects to the person' do
        person = @contact.people.create! valid_attributes
        put :update, id: person.to_param, person: valid_attributes
        expect(response).to redirect_to(person)
      end
    end

    describe 'with invalid params' do
      it 'assigns the person as @person' do
        person = @contact.people.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Person).to receive(:save).and_return(false)
        put :update, id: person.to_param, person: { first_name: '' }
        expect(assigns(:person)).to eq(person)
      end

      it "re-renders the 'edit' template" do
        person = @contact.people.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Person).to receive(:save).and_return(false)
        put :update, id: person.to_param, person: { first_name: '' }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the requested person' do
      person = @contact.people.create! valid_attributes
      expect do
        delete :destroy, id: person.to_param
      end.to change(Person, :count).by(-1)
    end

    it 'redirects to the people list' do
      person = @contact.people.create! valid_attributes
      delete :destroy, id: person.to_param
      expect(response).to redirect_to(people_url)
    end
  end

  describe 'PUT not_duplicates' do
    it 'adds the passed in ids to each persons not_duplicated_with field' do
      person1 = @contact.people.create! valid_attributes
      person2 = @contact.people.create! valid_attributes
      person3 = @contact.people.create! valid_attributes

      person1.update_column(:not_duplicated_with, person3.id.to_s)
      person2.update_column(:not_duplicated_with, person3.id.to_s)

      put :not_duplicates, ids: "#{person1.id},#{person2.id}", format: :js

      person1.reload
      person2.reload

      expect(person1.not_duplicated_with.split(',')).to include(person3.id.to_s)
      expect(person1.not_duplicated_with.split(',')).to include(person2.id.to_s)

      expect(person2.not_duplicated_with.split(',')).to include(person3.id.to_s)
      expect(person2.not_duplicated_with.split(',')).to include(person1.id.to_s)
    end
  end

  describe 'POST merge_sets for person duplicates' do
    let(:person1) { @contact.people.create! valid_attributes }
    let(:person2) { @contact.people.create! valid_attributes }
    let(:person_ids) { [person1.id, person2.id].map { |x| x }.join(',') }

    before { request.env['HTTP_REFERER'] = '/' }

    it 'merges two people  where the winner is the first in the list' do
      person2.email = 'test_merge_person2@example.com'
      person2.save
      params = { merge_sets: [person_ids],
                 dup_person_winner: { person_ids => person1.id } }
      post :merge_sets, params
      expect(Person.find_by_id(person2.id)).to be_nil
      expect(person1.email.email).to eq('test_merge_person2@example.com')
    end

    it 'merges two people where the winner is the second in the list' do
      person1.email = 'test_merge_person1@example.com'
      person1.save
      params = { merge_sets: [person_ids],
                 dup_person_winner: { person_ids => person2.id } }
      post :merge_sets, params
      expect(Person.find_by_id(person1.id)).to be_nil
      expect(person2.email.email).to eq('test_merge_person1@example.com')
    end

    it 'merges two people when no dup_person_winner is present the winner is the first ID in the dup set' do
      person2.email = 'test_merge_person2@example.com'
      person2.save
      first_person = Person.find_by_id(person_ids.split(',').first)
      params = { merge_sets: [person_ids] }
      post :merge_sets, params
      expect(Person.find_by_id(person1.id)).to eq(first_person)
      expect(Person.find_by_id(person2.id)).to be_nil
      expect(person1.email.email).to eq('test_merge_person2@example.com')
    end
  end
end
