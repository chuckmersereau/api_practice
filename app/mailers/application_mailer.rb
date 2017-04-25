class ApplicationMailer < ActionMailer::Base
  append_view_path Rails.root.join('app', 'views', 'mailers')
  default from: 'support@mpdx.org'

  class << self
    alias sidekiq_delay delay

    # Redefine the delay method with a default queue.
    def delay(*args)
      args << { queue: :mailers } if args.blank?
      sidekiq_delay(*args)
    end
  end
end
