require 'spec_helper'

describe Api::V1::MailChimpAccountsController do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:chimp) { create(:mail_chimp_account, account_list: account_list) }

  before do
    sign_in(:user, user)
    allow(controller).to receive(:current_account_list).and_return(account_list)

    stub_request(:post, 'https://us4.api.mailchimp.com/1.3/?method=lists')
      .with(body: '%7B%22apikey%22%3A%22fake-us4%22%7D')
      .to_return(body: '{"total":2,"data":['\
      '{"id":"1e72b58b72","web_id":97593,"name":"MPDX","date_created":"2012-10-09 13:50:12","email_type_option":false,"use_awesomebar":true,'\
      '"default_from_name":"MPDX","default_from_email":"support@mpdx.org","default_subject":"","default_language":"en","list_rating":3,'\
      '"subscribe_url_short":"http:\/\/eepurl.com\/qnY35",'\
      '"subscribe_url_long":"http:\/\/26am.us4.list-manage1.com\/subscribe?u=720971c5830c5228bdf461524&id=1e72b58b72",'\
      '"beamer_address":"NzIwOTcxYzU4MzBjNTIyOGJkZjQ2MTUyNC1iYmNlYzBkNS05ZDhlLTQ5NDctYTg1OC00ZjQzYTAzOGI3ZGM=@campaigns.mailchimp.com","visibility":"pub",'\
      '"stats":{"member_count":159,"unsubscribe_count":0,"cleaned_count":0,"member_count_since_send":159,"unsubscribe_count_since_send":0,'\
      '"cleaned_count_since_send":0,"campaign_count":0,"grouping_count":1,"group_count":4,"merge_var_count":2,"avg_sub_rate":null,"avg_unsub_rate":null,'\
      '"target_sub_rate":null,"open_rate":null,"click_rate":null},"modules":[]},'\
      '{"id":"29a77ba541","web_id":97493,"name":"Appeals List","date_created":"2012-10-09 00:32:44","email_type_option":true,"use_awesomebar":true,'\
      '"default_from_name":"MPDX User","default_from_email":"mpdx@cru.org","default_subject":"","default_language":"en","list_rating":0,'\
      '"subscribe_url_short":"http:\/\/eepurl.com\/qmAWn",'\
      '"subscribe_url_long":"http:\/\/26am.us4.list-manage.com\/subscribe?u=720971c5830c5228bdf461524&id=29a77ba541",'\
      '"beamer_address":"NzIwOTcxYzU4MzBjNTIyOGJkZjQ2MTUyNC02ZmZiZDJhOS0zNWFmLTQ1YzQtOWE0ZC1iOTZhMmRlMTQ0ZDc=@campaigns.mailchimp.com","visibility":"pub",'\
      '"stats":{"member_count":75,"unsubscribe_count":0,"cleaned_count":0,"member_count_since_send":75,"unsubscribe_count_since_send":0,'\
      '"cleaned_count_since_send":0,"campaign_count":0,"grouping_count":1,"group_count":3,"merge_var_count":2,"avg_sub_rate":null,"avg_unsub_rate":null,'\
      '"target_sub_rate":null,"open_rate":null,"click_rate":null},"modules":[]}]}')

    allow(account_list).to receive(:mail_chimp_account).and_return(chimp)
  end

  context 'available_appeal_lists' do
    it 'returns an array of available appeal lists' do
      expect(chimp.lists.length).to eq(2)
    end

    it 'should return lists available for appeals' do
      get :available_appeal_lists
      expect(response).to be_success
      json = JSON.parse(response.body).to_s
      expect(json).to include 'MPDX'
      expect(json).to include 'Appeals List'
    end
  end
end
