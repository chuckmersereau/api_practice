require 'rails_helper'

describe TntImport::OrgsFinder, '#orgs_by_tnt_id' do
  def build_parsed_xml(code:)
    Nokogiri::XML(
      <<~XML
        <Database>
          <Tables>
            <Organization>
              <row id="2">
                <Code>#{code}</Code>
              </row>
            </Organization>
          </Tables>
        </Database>
      XML
    )
  end

  it 'looks up the organizations by code' do
    ptc_canada = Organization.find_by(code: 'PTC-CAN') ||
                 create(:organization, code: 'PTC-CAN')

    parsed_xml  = build_parsed_xml(code: 'PTC-CAN')
    wrapped_xml = TntImport::Xml.new(parsed_xml)

    orgs = TntImport::OrgsFinder.orgs_by_tnt_id(wrapped_xml, nil)

    expect(orgs).to eq('2' => ptc_canada)
  end

  it 'uses the passed default org if none found by code' do
    default_org = double

    parsed_xml  = build_parsed_xml(code: 'RANDOM')
    wrapped_xml = TntImport::Xml.new(parsed_xml)

    orgs = TntImport::OrgsFinder.orgs_by_tnt_id(wrapped_xml, default_org)

    expect(orgs).to eq('2' => default_org)
  end
end
