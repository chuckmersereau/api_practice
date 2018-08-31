#          .            .                     .
#                 _        .                          .            (
#                (_)        .       .                                     .
# .        ____.--^.
#  .      /:  /    |                               +           .         .
#        /:  `--=--'   .                                                .
# LS    /: __[\==`-.___          *           .
#      /__|\ _~~~~~~   ~~--..__            .             .
#      \   \|::::|-----.....___|~--.                                 .
#       \ _\_~~~~~-----:|:::______//---...___
#   .   [\  \  __  --     \       ~  \_      ~~~===------==-...____
#       [============================================================-
#       /         __/__   --  /__    --       /____....----''''~~~~      .
# *    /  /   ==           ____....=---='''~~~~ .
#     /____....--=-''':~~~~                      .                .
#     .       ~--~
#                    .                                   .           .
#                         .                      .             +
#       .     +              .                                       <=>
#                                              .                .      .
#  .                 *                 .                *                ` -
class AccountList::Destroyer
  def initialize(account_list_id)
    @account_list = AccountList.find(account_list_id)
  end

  def destroy!
    destroy_sync_associations # Destroy the sync associations first to prevent syncing to external services.

    @account_list.account_list_coaches.destroy_all
    @account_list.account_list_users.destroy_all
    @account_list.designation_accounts.each(&:destroy)
    @account_list.designation_profiles.destroy_all
    @account_list.imports.destroy_all
    @account_list.appeals.destroy_all

    @account_list.account_list_entries.delete_all
    @account_list.account_list_invites.delete_all
    @account_list.company_partnerships.delete_all
    @account_list.notification_preferences.delete_all

    delete_activities

    delete_people

    delete_contacts

    @account_list.reload
    @account_list.unsafe_destroy
  end

  private

  def destroy_sync_associations
    @account_list.google_integrations.each(&:destroy!)
    @account_list.mail_chimp_account&.destroy!
    @account_list.pls_account&.destroy!
    @account_list.prayer_letters_account&.destroy!
  end

  def delete_activities
    activities = @account_list.activities.to_a

    ActsAsTaggableOn::Tagging.where(taggable: activities).delete_all
    ActivityContact.where(activity: activities).delete_all
    ActivityComment.where(activity: activities).delete_all
    GoogleEmailActivity.where(activity: activities).delete_all

    Activity.where(id: activities.collect(&:id)).delete_all
  end

  def delete_people
    people = @account_list.people.to_a

    Person::GoogleAccount.where(person: people).destroy_all
    Person::OrganizationAccount.where(person: people).destroy_all
    Picture.where(picture_of: people).destroy_all
    ActivityComment.where(person: people).destroy_all

    EmailAddress.where(person: people).delete_all
    PhoneNumber.where(person: people).delete_all
    FamilyRelationship.where(person: people).delete_all
    CompanyPosition.where(person: people).delete_all
    Person::TwitterAccount.where(person: people).delete_all
    Person::FacebookAccount.where(person: people).delete_all
    Person::LinkedinAccount.where(person: people).delete_all
    Person::Website.where(person: people).delete_all
    Person::KeyAccount.where(person: people).delete_all
    ContactPerson.where(person: people).delete_all
    Message.where(from_id: people).delete_all
    Message.where(to_id: people).delete_all

    Person.where(id: people.collect(&:id)).delete_all
  end

  def delete_contacts
    contacts = @account_list.contacts

    Address.where(addressable: contacts).delete_all
    ActsAsTaggableOn::Tagging.where(taggable: contacts).delete_all
    # TODO: delete has_attributes_history
    ContactDonorAccount.where(contact: contacts).delete_all
    ContactPerson.where(contact: contacts).delete_all
    ContactReferral.where(referred_by: contacts).delete_all
    ContactReferral.where(referred_to: contacts).delete_all
    ActivityContact.where(contact: contacts).delete_all
    Notification.where(contact: contacts).delete_all
    Appeal::ExcludedAppealContact.where(contact: contacts).delete_all

    Contact.where(id: contacts.collect(&:id)).delete_all
  end
end
