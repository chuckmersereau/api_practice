if Rails.env.development? || Rails.env.test? || Rails.env.cucumber?
  CarrierWave.configure do |config|
    config.storage = :file
    # config.enable_processing = false
  end
else
  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider: 'AWS', # required
      aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'), # required
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY') # required
    }
    config.fog_directory  = ENV.fetch('AWS_BUCKET') # required
    config.fog_public     = false # optional, defaults to true
    config.fog_attributes = { 'x-amz-storage-class' => 'REDUCED_REDUNDANCY' }
    config.fog_authenticated_url_expiration = 1.day
    config.storage :fog
  end
end
