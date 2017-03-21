RSpec.shared_examples 'updatable_only_when_source_is_mpdx_validation_examples' do |options = {}|
  options[:attributes] ||= []

  def change_attribute(record, attribute)
    new_value = if attribute.to_s.ends_with?('date') || attribute.to_s.ends_with?('_at')
                  rand(1..100).days.ago
                else
                  "a#{record.send(attribute)}z"
                end
    record.send("#{attribute}=", new_value)
  end

  options[:attributes].each do |attribute|
    describe "#{attribute} validation" do
      context 'when source is MPDX' do
        it 'does not validate unsaved records' do
          record = build(options[:factory_type])
          record.source = 'MPDX'
          change_attribute(record, attribute)
          expect(record.valid?).to be true
          expect(record.errors[attribute]).to be_blank
        end

        it 'permits updates to existing records' do
          record = create(options[:factory_type])
          record.source = 'MPDX'
          change_attribute(record, attribute)
          expect(record.valid?).to be true
          expect(record.errors[attribute]).to be_blank
        end
      end

      context 'when source is not MPDX' do
        it 'does not validate unsaved records' do
          record = build(options[:factory_type])
          record.source = 'unknown'
          change_attribute(record, attribute)
          expect(record.valid?).to be true
          expect(record.errors[attribute]).to be_blank
        end

        it 'does not permit updates to existing records' do
          record = create(options[:factory_type])
          record.source = 'unknown'
          change_attribute(record, attribute)
          expect(record.valid?).to be false
          expect(record.errors[attribute]).to be_present
        end
      end
    end
  end
end
