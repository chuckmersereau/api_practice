require 'rails_helper'

describe ImportMailer do
  before do
    Sidekiq::Testing.inline!
    stub_smarty_streets
  end

  describe '#failed' do
    let(:import) { create(:csv_import_with_mappings) }

    it 'assigns expected params' do
      mail = ImportMailer.failed(import)
      expect(mail.to).to eq([import.user.email.email])
      expect(mail.subject).to eq('[MPDX] Importing your CSV contacts failed')
    end

    context 'import source csv' do
      before do
        import.in_preview = false
        allow_any_instance_of(ImportUploader).to receive(:path).and_return(Rails.root.join('spec/fixtures/sample_csv_with_some_invalid_rows.csv').to_s)
        CsvImport.new(import).import
        import.reload
      end

      it 'attaches a csv file containing the failed rows' do
        mail = ImportMailer.failed(import)
        expect(mail.attachments.size).to eq(1)
        expect(mail.attachments.first.content_type).to eq('text/comma-separated-values; filename="MPDX Import Failures.csv"')
        expect(mail.attachments.first.body.to_s).to eq('Error Message,fullname,fname,lname,Spouse-fname,Spouse-lname,greeting,mailing-greeting,church,' \
                                                                   'street,city,province,zip-code,country,status,amount,frequency,currency,newsletter,tags,' \
                                                                   'email-address,Spouse-email-address,phone,Spouse-phone-number,extra-notes,skip,likely-giver' \
                                                                   ",metro,region,appeals,website,referred_by\n\"Validation failed: Email is invalid, Email is invalid\",Bob" \
                                                                   ',Park,Sara,Kim,Hello!,,,123 Street West,A Small Town,Quebec,L8D 3B9,Canada,Praying and giving' \
                                                                   ',10,Monthly,,Both,bob,this is not a valid email,this is also not a valid email,+12345678901' \
                                                                   ",+10987654321,,Yes,No,metro,region,No,website\n\"Validation failed: First name can't be blank, " \
                                                                   "Name can't be blank\",,,,,,,,\"Apartment, Unit 123\",Big City,BC,,CA,Praying,,,,Both,,joe@inter.net" \
                                                                   ",,123.456.7890,,notes,,Yes,metro,region,Yes,website\n")
      end
    end

    context 'import source tnt' do
      let(:import) { create(:tnt_import) }

      before do
        import.in_preview = false
        allow_any_instance_of(TntImport::ContactsImport).to receive(:import_contacts).and_raise(StandardError)
        begin
          TntImport.new(import).import
        rescue StandardError
        end
        import.reload
      end

      it 'does not generate any attachments' do
        mail = ImportMailer.failed(import)
        expect(mail.attachments.size).to eq(0)
      end
    end
  end

  describe '#success' do
    it 'assigns to field correctly' do
      email_address = build(:email_address, email: 't@t.co')
      user = double(email: email_address, locale: 'en')
      import = double(user: user, user_friendly_source: 'tnt')

      mail = ImportMailer.success(import)

      expect(mail.to).to eq ['t@t.co']
    end
  end
end
