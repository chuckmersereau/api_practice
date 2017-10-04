class PopulateContactsStatusConfirmedAt < ActiveRecord::Migration
  def up
    current_time = Time.current

    # If the contact was updated after the status was validated and the contact status_valid is true then assume it doesn't need to be confirmed for another year.
    Contact.where.not(status_validated_at: nil, suggested_changes: nil).where('updated_at > status_validated_at').where(status_valid: true).update_all(status_confirmed_at: current_time)

    # If the contact has suggested_changes but the status_valid is true then it implies that the user already confirmed the status.
    Contact.where.not(suggested_changes: [nil, {}]).where(status_valid: true).update_all(status_confirmed_at: current_time)
  end

  def down
    Contact.update_all(status_confirmed_at: nil)
  end
end
