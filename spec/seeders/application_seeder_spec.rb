require 'rails_helper'

describe ApplicationSeeder do
  let!(:seeder) { ApplicationSeeder.new }

  it 'seeds all models without error' do
    expect(seeder.all_models_seeded?).to be_falsey
    expect { seeder.seed }.to_not raise_error
    seeder.quiet = false # Print out missing seeds.
    expect(seeder.all_models_seeded?).to be_truthy, "If you've created a new model, please make "\
                                                    'sure that you add a corresponding factory, '\
                                                    "and add your seeds to #{described_class}"
  end

  context 'staging env' do
    before do
      allow(Rails).to receive(:env).and_return('staging')
    end

    it 'fails to run' do
      expect { seeder.seed }.to raise_exception RuntimeError
    end
  end
end
