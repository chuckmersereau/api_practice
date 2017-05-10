require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Batch' do
  include_context :json_headers
  documentation_scope = :requests

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  context 'authorized user' do
    before { api_login(user) }
    let(:first_response) { JSON.parse(response_body).first }
    let(:second_response) { JSON.parse(response_body).second }
    let(:second_response_attributes) { JSON.parse(second_response['body'])['data']['attributes'] }
    let!(:task) { create(:task, account_list: account_list) }

    # Activities
    post '/api/v2/batch' do
      with_options scope: :requests do
        parameter :method, 'GET, POST, PATCH, PUT or DELETE'
        parameter :path, 'The path (URL) of the request'
        parameter :body, 'The JSON body of the request'
      end
      example 'Batch', document: documentation_scope do
        explanation 'A batch endpoint that allows you to send an array of requests. It expects a JSON payload with a requests key that has an array of request objects. ' \
                    'A request object needs to have a method key and a path key. It may also have a body key. The response will be a JSON array of response objects. ' \
                    'A response object has a status key, a headers key, and a body key. The body is a string of the server response. ' \
                    'In addition to the requests key in the payload, you may also specify a on_error key which may be set to CONTINUE, or ABORT. CONTINUE is the default, ' \
                    'and it will return a 200 no matter what, and give a response for every request, no matter if they errored or not. ABORT will end the batch request early ' \
                    'if one of the requests fails. The batch response will have the status code of the failing request, and the response will include responses up to and including ' \
                    'the errored request, but no more. Some endpoints are unable to be used within a batch request. At this time, only bulk endpoints are disallowed from being used in ' \
                    'a batch request.'

        do_request requests: [
          { method: 'GET', path: "/api/v2/account_lists/#{account_list.uuid}/donations" },
          { method: 'PATCH', path: "/api/v2/tasks/#{task.uuid}", body: {
            data: {
              id: task.uuid,
              type: 'tasks',
              attributes: {
                subject: 'Random Task Subject',
                overwrite: true
              }
            }
          }
          }
        ]
        expect(response_status).to eq 200
        expect(first_response['status']).to eq(200)
        expect(first_response['body']['data']).to be_present
        expect(first_response['body']['meta']).to be_present
        expect(first_response['headers']).to be_present
        expect(second_response['status']).to eq(200)
        expect(second_response_attributes['subject']).to eq 'Random Task Subject'
      end
    end
  end
end
