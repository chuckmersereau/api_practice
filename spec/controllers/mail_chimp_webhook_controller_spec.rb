require 'spec_helper'

describe MailChimpWebhookController do
  let(:account_list) { create(:account_list) }
  let!(:account) do
    create(:mail_chimp_account, account_list: account_list, webhook_token: 'token', active: true)
  end
  let(:unsubscribe_params) do
    {
      type: 'unsubscribe', fired_at: '2009-03-26 21:40:57',
      data: {
        action: 'unsub', id: '8a25ff1d98', list_id: 'MyString',
        email: 'api+unsub@mailchimp.com', email_type: 'html',
        merges: { EMAIL: 'api+unsub@mailchimp.com', FNAME: 'MailChimp',
                  LNAME: 'API', INTERESTS: 'Group1,Group2' },
        ip_opt: '10.20.10.30', campaign_id: 'cb398d21d2', reason: 'hard'
      }
    }
  end
  let(:campaign_params) do
    { type: 'campaign', fired_at: '2009-03-26 21:31:21',
      data: { id: 'campaign1', subject: 'Subject', status: 'sent', reason: '', list_id: 'MyString' } }
  end
  let(:handler) { double }

  before do
    allow(MailChimpAccount::PrimaryListHookHandler).to receive(:new) { handler }
  end

  it 'returns 200 if you get the webhook index for a valid token' do
    get :index, token: 'token'
    expect(response).to be_success
  end

  it 'returns 401 if you get the webhook index for an invalid token' do
    get :index, token: 'invalid'
    expect(response.status).to eq(401)
  end

  it 'returns 401 if a post request does not match the webhook token' do
    post :hook, token: 'invalid'
    expect(response.status).to eq(401)
  end

  def post_and_expect_success(params)
    post :hook, params.merge(token: 'token')
    expect(response).to be_success
    expect(account).to eq(assigns(:account))
  end

  it 'calls handler hook on unsubscribe' do
    expect(handler).to receive(:unsubscribe_hook).with('api+unsub@mailchimp.com')
    post_and_expect_success(unsubscribe_params)
  end

  it 'does not error on profile update' do
    params = {
      type: 'profile', fired_at: '2009-03-26 21:31:21',
      data: {
        id: '8a25ff1d98', list_id: 'MyString', email: 'api@mailchimp.com', email_type: 'html',
        merges: { EMAIL: 'api+unsub@mailchimp.com', FNAME: 'MailChimp',
                  LNAME: 'API', INTERESTS: 'Group1,Group2' },
        ip_opt: '10.20.10.30'
      }
    }
    post_and_expect_success(params)
  end

  it 'calls account hook on email update' do
    params = {
      type: 'upemail', fired_at: '2009-03-26 22:15:09',
      data: {
        list_id: 'MyString', new_id: '51da8c3259',
        new_email: 'api+new@mailchimp.com', old_email: 'api+old@mailchimp.com'
      }
    }
    expect(handler).to receive(:email_update_hook)
      .with('api+old@mailchimp.com', 'api+new@mailchimp.com')
    post_and_expect_success(params)
  end

  it 'calls account hook on email cleaned' do
    params = {
      type: 'cleaned', fired_at: '2009-03-26 22:01:00',
      data: { list_id: 'MyString', campaign_id: '4f', reason: 'hard', email: 'cleaned@mailchimp.com' }
    }
    expect(handler).to receive(:email_cleaned_hook)
      .with('cleaned@mailchimp.com', 'hard')
    post_and_expect_success(params)
  end

  it 'calls account hook on campaign sent' do
    expect(handler).to receive(:campaign_status_hook).with('campaign1', 'sent', 'Subject')
    post_and_expect_success(campaign_params)
  end

  it 'calls handler on subscribe' do
    params = {
      type: 'subscribe', fired_at: '2009-03-26 22:01:00',
      data: { list_id: 'MyString', email: 'j@t.co', email_type: 'html' }
    }
    expect(handler).to receive(:subscribe_hook).with('j@t.co')
    post_and_expect_success(params)
  end

  it 'renders success but does not call account hook method if for non-primary list' do
    unsubscribe_params[:data][:list_id] = 'other-list'
    expect(handler).to_not receive(:unsubscribe_hook)
    post_and_expect_success(unsubscribe_params)
  end

  it 'renders success but does not call account hook method if account is inactive' do
    account.update(active: false)
    expect(handler).to_not receive(:unsubscribe_hook)
    post_and_expect_success(unsubscribe_params)
  end

  it 'calls the appeal hook handler for an appeal list' do
    appeal = create(:appeal)
    account.create_mail_chimp_appeal_list(appeal: appeal,
                                          appeal_list_id: 'appeal_list')
    appeal_handler = double('appeal hook handler', email_cleaned_hook: nil)
    allow(MailChimpAccount::AppealListHookHandler).to receive(:new)
      .and_return(appeal_handler)
    params = {
      type: 'cleaned', fired_at: '2009-03-26 22:01:00',
      data: { list_id: 'appeal_list', campaign_id: '4f', reason: 'hard',
              email: 'cleaned@mailchimp.com' }
    }
    post_and_expect_success(params)

    expect(appeal_handler).to have_received(:email_cleaned_hook)
      .with('cleaned@mailchimp.com', 'hard')
  end
end
