require 'rails_helper'
require 'pundit_context'

describe PunditAuthorizer do
  let(:user) { create(:user) }
  let(:object) { create(:account_list) }

  describe 'initialize' do
    it 'initializes' do
      pundit_authorizer = PunditAuthorizer.new(user, object)
      expect(pundit_authorizer).to be_a(PunditAuthorizer)
      expect(pundit_authorizer.user).to eq(user)
      expect(pundit_authorizer.obj).to eq(object)
    end
  end

  describe '#authorize_on' do
    it 'authorizes the object, without ?' do
      pundit_authorizer = PunditAuthorizer.new(user, object)
      expect(pundit_authorizer).to receive(:authorize).with(object, 'show?').and_return(true)
      pundit_authorizer.authorize_on('show')
    end

    it 'authorizes the object, using ?' do
      pundit_authorizer = PunditAuthorizer.new(user, object)
      expect(pundit_authorizer).to receive(:authorize).with(object, 'show?').and_return(true)
      pundit_authorizer.authorize_on('show?')
    end
  end
end
