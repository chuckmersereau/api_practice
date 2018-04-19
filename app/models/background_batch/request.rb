class BackgroundBatch::Request < ApplicationRecord
  belongs_to :background_batch
  validates :path, :request_method, presence: true
  validates :request_method, inclusion: { in: %w(GET POST PUT DELETE) }
  serialize :request_params, Hash
  serialize :request_headers, Hash
  serialize :response_headers
  enum status: { pending: 0, complete: 1 }
  delegate :user, to: :background_batch, prefix: true, allow_nil: true

  def response_body
    JSON.parse(super || '{}')
  end

  def formatted_path
    @formatted_path ||=
      URI(
        ENV.fetch('API_URL') + (
          if path.include? '%{default_account_list_id}'
            format(path, default_account_list_id: default_account_list_id)
          else
            path
          end
        )
      ).to_s
  end

  def formatted_request_headers
    @formatted_request_headers ||= {
      'accept' => 'application/vnd.api+json',
      'authorization' => "Bearer #{User::Authenticate.new(user: background_batch_user).json_web_token}",
      'content-type' => 'application/vnd.api+json',
      'params' => formatted_request_params
    }.merge(request_headers || {})
  end

  def formatted_request_params
    @formatted_request_params ||=
      if default_account_list && default_account_list_id
        formatted_request_params = {}
        formatted_request_params['filter'] ||= {}
        formatted_request_params['filter']['account_list_id'] = default_account_list_id
        formatted_request_params.merge(request_params || {})
      else
        request_params
      end
  end

  protected

  def default_account_list_id
    @default_account_list_id ||= AccountList.find_by(id: background_batch_user.try(:default_account_list)).try(:id)
  end
end
