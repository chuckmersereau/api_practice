require 'spec_helper'
require 'generators/graip/controller/controller_generator'

RSpec.describe Graip::Generators::ControllerGenerator, type: :generator do
  destination Rails.root.join('tmp/generator_specs')

  before { prepare_destination }

  describe 'generated files' do
    before { run_generator ['Api/v2/EmailAddresses'] }

    describe 'the controller' do
      subject { file('app/controllers/api/v2/email_addresses_controller.rb') }

      it { is_expected.to exist }
      it { is_expected.to have_correct_syntax }

      it 'correctly generates the code' do
        example_code = fetch_example_controller
        spec_code = File.read(subject)

        expect(spec_code).to eq example_code
      end
    end

    describe 'the controller spec' do
      subject do
        filename = 'spec/controllers/api/v2/email_addresses_controller_spec.rb'
        file(filename)
      end

      it { is_expected.to exist }
      it { is_expected.to have_correct_syntax }

      it 'correctly generates the code' do
        example_code = fetch_example_controller_spec
        spec_code = File.read(subject)

        expect(spec_code).to eq example_code
      end
    end

    describe 'the acceptance spec' do
      subject { file('spec/acceptance/api/v2/email_addresses_spec.rb') }

      it { is_expected.to exist }
      it { is_expected.to have_correct_syntax }

      it 'correctly generates the code' do
        example_code = fetch_example_acceptance_spec
        spec_code = File.read(subject)

        expect(spec_code).to eq example_code
      end
    end
  end

  private

  def fetch_example_acceptance_spec
    File.read("#{support_files_root}/acceptance_spec.rb.example")
  end

  def fetch_example_controller
    File.read("#{support_files_root}/controller.rb.example")
  end

  def fetch_example_controller_spec
    File.read("#{support_files_root}/controller_spec.rb.example")
  end

  def support_files_root
    'spec/support/generators/graip/controller'
  end
end
