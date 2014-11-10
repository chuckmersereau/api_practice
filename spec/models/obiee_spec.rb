require "spec_helper"
# require the helper module
require "savon/mock/spec_helper"

describe Obiee do

  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  describe "#obiee_login" do

    it 'tests successful user login' do
      creds = {name: APP_CONFIG['obiee_stage_key'], password: APP_CONFIG['obiee_stage_secret'] }
      fixture = File.read("spec/fixtures/obieeWsdl.xml")

      #expectation
      savon.expects(:logon).with(message: creds).returns(fixture)

      #create and call wsdl
      ob = Obiee.new
      client = ob.get_client(APP_CONFIG['obiee_stage_base_url'])

      response = client.call( :logon, message: creds)
      expect(response).to be_successful

    end

  end
end