class DonationImports::Siebel
  class DonorImporter
    class PersonImporter
      attr_reader :siebel_import

      delegate :organization, to: :siebel_import

      def initialize(siebel_import)
        @siebel_import = siebel_import
      end

      def add_or_update_person_on_contact(siebel_person:, contact:, donor_account:, date_from: nil)
        @siebel_person = siebel_person
        @contact = contact
        @donor_account = donor_account
        @date_from = date_from

        add_person
        add_or_update_phone_numbers
        add_or_update_email_addresses

        true
      end

      private

      def add_person
        find_and_set_master_person_from_siebel_person

        @mpdx_person = find_mpdx_person_from_siebel_person

        @mpdx_person.attributes = generate_new_mpdx_person_attributes if @mpdx_person.new_record?
        @mpdx_person.master_person_id ||=
          MasterPerson.find_or_create_for_person(@mpdx_person, donor_account: @donor_account).try(:id)

        @mpdx_person.save

        @donor_account.people << @mpdx_person unless @donor_account.people.exists?(@mpdx_person&.id)

        existing_master_person = @donor_account.master_people.exists?(@mpdx_person&.master_person&.id)
        @donor_account.master_people << @mpdx_person.master_person unless existing_master_person

        @contact.people << @mpdx_person unless @contact.people.exists?(@mpdx_person&.id)
        create_master_person_if_needed
      end

      def generate_new_mpdx_person_attributes
        {
          legal_first_name: @siebel_person.first_name,
          first_name: @siebel_person.preferred_name || @siebel_person.first_name,
          last_name: @siebel_person.last_name,
          middle_name: @siebel_person.middle_name,
          title: @siebel_person.title,
          suffix: @siebel_person.suffix,
          gender: gender_from_siebel_person
        }
      end

      def find_and_set_master_person_from_siebel_person
        @master_person_from_source =
          organization.master_people.find_by('master_person_sources.remote_id' => @siebel_person.id)

        return if @master_person_from_source

        remote_id = @siebel_person.primary ? "#{@donor_account.account_number}-1" : "#{@donor_account.account_number}-2"

        @master_person_from_source = organization.master_people.find_by('master_person_sources.remote_id' => remote_id)
        if @master_person_from_source
          MasterPersonSource.where(organization_id: organization.id, remote_id: remote_id)
                            .update_all(remote_id: siebel_person.id)
        end
      end

      def find_mpdx_person_from_siebel_person
        @mpdx_person =
          @contact.people.find_by(first_name: @siebel_person.first_name, last_name: @siebel_person.last_name)
        @mpdx_person ||=
          @contact.people.find_by(master_person_id: @master_person_from_source.id) if @master_person_from_source
        @mpdx_person || Person.new(master_person: @master_person_from_source)
      end

      def create_master_person_if_needed
        return if @master_person_from_source

        organization.master_person_sources.where(remote_id: @siebel_person.id)
                    .first_or_create(master_person_id: @mpdx_person.master_person.id)
      end

      def gender_from_siebel_person
        if @siebel_person.sex == 'F'
          'female'
        elsif @siebel_person.sex == 'M'
          'male'
        end
      end

      def add_or_update_phone_numbers
        @siebel_person.phone_numbers&.each do |siebel_phone_number|
          next if siebel_phone_number_irrelevant?(siebel_phone_number)

          add_or_update_phone_number(siebel_phone_number)
        end
      end

      def add_or_update_email_addresses
        @siebel_person.email_addresses&.each do |siebel_email_address|
          next if siebel_phone_number_irrelevant?(siebel_email_address)

          add_or_update_email_address(siebel_email_address)
        end
      end

      def siebel_phone_number_irrelevant?(siebel_phone_number)
        siebel_object_irrelevant?(siebel_phone_number) && @mpdx_person.phone_numbers.present?
      end

      def siebel_email_address_irrelevant?(siebel_email_address)
        siebel_object_irrelevant?(siebel_email_address) && @mpdx_person.email_addresses.present?
      end

      def siebel_object_irrelevant?(siebel_object)
        @date_from.present? &&
          siebel_object.updated_at &&
          DateTime.parse(siebel_object.updated_at) < @date_from
      end

      def add_or_update_phone_number(siebel_phone_number)
        attributes = {
          number: siebel_phone_number.phone,
          location: siebel_phone_number.type.try(:downcase),
          primary: siebel_phone_number.primary,
          remote_id: siebel_phone_number.id
        }

        existing_phone = @mpdx_person.phone_numbers.find do |person_phone_number|
          person_phone_number.remote_id == siebel_phone_number.id
        end

        if existing_phone
          existing_phone.update_attributes(attributes)
        else
          @mpdx_person.phone_numbers.create(attributes)
        end
      end

      def add_or_update_email_address(siebel_email_address)
        attributes = {
          email: siebel_email_address.email,
          primary: siebel_email_address.primary,
          location: siebel_email_address.type,
          remote_id: siebel_email_address.id
        }

        existing_email = @mpdx_person.email_addresses.find do |person_email_address|
          person_email_address.remote_id == siebel_email_address.id
        end

        if existing_email
          begin
            existing_email.update_attributes(attributes)
          rescue StandardError
            ActiveRecord::RecordNotUnique
          end
          # If they already have the email address we're trying to update to, don't do anything
        else
          @mpdx_person.email_addresses.create(attributes)
        end
      end
    end
  end
end
