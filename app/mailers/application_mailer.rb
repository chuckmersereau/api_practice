class ApplicationMailer < ActionMailer::Base
  append_view_path Rails.root.join('app', 'views', 'mailers')
  default from: 'support@mpdx.org'

  class << self
    alias sidekiq_delay delay
    alias sidekiq_delay_until delay_until

    # Redefine the delay method with a default queue.
    def delay(*args)
      args << { queue: :mailers } if args.blank?
      sidekiq_delay(*args)
    end

    def delay_until(timestamp, options = {})
      options[:queue] = :mailers if options.with_indifferent_access[:queue].blank?
      sidekiq_delay_until(timestamp, options)
    end
  end
end
