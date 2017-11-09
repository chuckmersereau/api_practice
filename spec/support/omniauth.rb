OmniAuth.config.test_mode = true

google_mock_response = {
  provider: 'google_oauth2',
  uid: '123456789',
  info: {
    name: 'John Doe',
    email: 'john@company_name.com',
    first_name: 'John',
    last_name: 'Doe',
    image: 'https://lh3.googleusercontent.com/url/photo.jpg'
  },
  credentials: {
    token: 'token',
    refresh_token: 'another_token',
    expires_at: (Time.current + 1.day).to_i,
    expires: true
  },
  extra: {
    raw_info: {
      id: '123456789',
      email: 'user@domain.example.com',
      email_verified: true,
      name: 'John Doe',
      given_name: 'John',
      family_name: 'Doe',
      link: 'https://plus.google.com/123456789',
      picture: 'https://lh3.googleusercontent.com/url/photo.jpg',
      gender: 'male',
      birthday: '0000-06-25',
      locale: 'en',
      hd: 'company_name.com'
    }
  }
}

prayer_letters_mock_response = {
  credentials: {
    token: 'token'
  }
}

donorhub_mock_response = {
  credentials: {
    token: 'token'
  }
}

mail_chimp_mock_response = {
  extra: {
    api_token_with_dc: 'token-us5'
  }
}

OmniAuth.config.add_mock(:google, google_mock_response)
OmniAuth.config.add_mock(:prayer_letters, prayer_letters_mock_response)
OmniAuth.config.add_mock(:mailchimp, mail_chimp_mock_response)
OmniAuth.config.add_mock(:donorhub, donorhub_mock_response)
