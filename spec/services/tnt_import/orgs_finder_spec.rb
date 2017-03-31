require 'rails_helper'

describe TntImport::OrgsFinder, '#orgs_by_tnt_id' do
  it 'looks up the organizations by code' do
    ptc_canada = Organization.find_by(code: 'PTC-CAN') ||
                 create(:organization, code: 'PTC-CAN')

    xml = TntImport::Xml.new('Database' => {
                               'Tables' => {
                                 'Organization' => {
                                   'row' => { 'id' => '2', 'Code' => 'PTC-CAN' }
                                 }
                               }
                             })

    orgs = TntImport::OrgsFinder.orgs_by_tnt_id(xml, nil)

    expect(orgs).to eq('2' => ptc_canada)
  end

  it 'uses the passed default org if none found by code' do
    default_org = double

    xml = TntImport::Xml.new('Database' => {
                               'Tables' => {
                                 'Organization' => {
                                   'row' => { 'id' => '2', 'Code' => 'RANDOM_NEW_ORG' }
                                 }
                               }
                             })

    orgs = TntImport::OrgsFinder.orgs_by_tnt_id(xml, default_org)

    expect(orgs).to eq('2' => default_org)
  end
end
