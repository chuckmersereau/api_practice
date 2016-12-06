shared_context :json_headers do
  header 'Content-Type', 'application/vnd.api+json'
  let(:raw_post) { JSON.pretty_generate(params) unless params.blank? }
end
