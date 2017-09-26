class BackgroundBatch::RequestSerializer < ApplicationSerializer
  attributes :path,
             :request_body,
             :request_headers,
             :request_method,
             :request_params,
             :response_body,
             :response_headers,
             :default_account_list
  belongs_to :background_batch
end
