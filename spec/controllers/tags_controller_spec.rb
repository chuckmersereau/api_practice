require 'spec_helper'

describe TagsController do
  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @contact1 = create(:contact, account_list: @user.account_lists.first)
    @contact2 = create(:contact, account_list: @user.account_lists.first)
  end

  describe "GET 'create'" do
    it 'returns http success' do
      xhr :get, 'create', add_tag_name: 'foo', add_tag_contact_ids: "#{@contact1.id},#{@contact2.id}"
      expect(response).to be_success
      expect(@contact1.tag_list).to include('foo')
      expect(@contact2.tag_list).to include('foo')
    end
  end

  describe "GET 'destroy'" do
    it 'returns http success' do
      @contact1.tag_list << 'foo'
      @contact2.tag_list << 'foo'
      @contact1.save
      @contact2.save

      xhr :get, 'destroy', id: 1, remove_tag_name: 'foo', remove_tag_contact_ids: "#{@contact1.id},#{@contact2.id}"
      expect(response).to be_success
      expect(@contact1.reload.tag_list).not_to include('foo')
      expect(@contact2.reload.tag_list).not_to include('foo')
    end
  end
end
