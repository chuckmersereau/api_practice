RSpec.configure do |config|
  config.before(:suite) do
    $stdout.puts("Stubbing all calls to Ruby's #sleep")

    module Kernel
      def sleep(time)
        time.round # Preserve return value.
      end
    end
  end
end
