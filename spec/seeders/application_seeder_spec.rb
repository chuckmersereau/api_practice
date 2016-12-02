require 'spec_helper'

require Rails.root.join('db/seeders/application_seeder.rb')

describe ApplicationSeeder do
  let!(:seeder) { ApplicationSeeder.new }

  it 'seeds all models without error' do
    expect(seeder.all_models_seeded?).to be_falsey
    expect { seeder.seed }.to_not raise_error
    seeder.quiet = false # Print out missing seeds.
    expect(seeder.all_models_seeded?).to be_truthy, "If you've created a new model, please make sure that you add a corresponding factory, and add your seeds to #{described_class}"
  end
end
