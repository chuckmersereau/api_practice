# This prevents the "Running via Spring preloader messages"
Spring.quiet = true if Rails.env.test? || Rails.env.development?
