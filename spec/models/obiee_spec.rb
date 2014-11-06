require "spec_helper"
# require the helper module
require "savon/mock/spec_helper"

describe Obiee do

  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  describe "#login" do
    it 'tests user login' do
      creds = { name: "MPDXWEBAPPSTAGE", password: "NTBnPAlAVgV9ZThpT7M8L" }
      fixture = File.read("spec/fixtures/obieeWsdl.xml")

      #expectation
      savon.expects(:logon).with(message: creds).returns(fixture)

      #create and call wsdl
      ob = Obiee.new
      client = ob.get_client(true,'http://slobia02.ccci.org:9704/analytics-ws/saw.dll/wsdl/v7')
      response = client.call( :logon, message: creds)
      expect(response).to be_successful

    end
  end
end