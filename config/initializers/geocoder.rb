Geocoder.configure(
  timeout: 2,
  lookup: :google_premier,
  google_premier: {
    use_https: true,
    api_key: [
      ENV.fetch('GOOGLE_GEOCODER_KEY'),
      ENV.fetch('GOOGLE_GEOCODER_CLIENT'),
      ENV.fetch('GOOGLE_GEOCODER_CHANNEL')
    ]
  }
)
