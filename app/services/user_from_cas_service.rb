class UserFromCasService
  def self.find_or_create(cas_attributes)
    new(cas_attributes).find_or_create
  end

  attr_reader :cas_attributes

  def initialize(cas_attributes)
    @cas_attributes = cas_attributes
  end

  def find_or_create
    find_user || create_user
  end

  def guids
    [
      cas_attributes[:ssoGuid],
      cas_attributes[:theKeyGuid],
      cas_attributes[:relayGuid]
    ].uniq
  end

  # The goal of this method is to return a mirror of how the CAS Omniauth system
  # returns the CAS data, that way we can leverage the already existing code
  # from the legacy system to create user accounts, etc.
  #
  # This, however, does not include the `credentials` data as only the CAS
  # account attributes are being sent on initialize, and the ticket is not
  # needed for user creation
  #
  def omniauth_attributes_hash
    @omniauth_attributes_hash ||= Hashie::Mash.new(
      provider: 'key',
      uid: cas_attributes[:email],
      extra: {
        user: cas_attributes[:email],
        attributes: [
          {
            ssoGuid: cas_attributes[:ssoGuid],
            firstName: cas_attributes[:firstName],
            lastName: cas_attributes[:lastName],
            theKeyGuid: cas_attributes[:theKeyGuid],
            relayGuid: cas_attributes[:relayGuid],
            email: cas_attributes[:email]
          }
        ]
      }
    )
  end

  private

  # Since the legacy system already knows how to create a new User and their
  # associated relationships, queue up imports, etc - via Omniauth Data - we can
  # just leverage that old code until the time comes for a refactor
  #
  # The basic logic here is being pulled from the legacy
  # `app/controllers/auth/accounts_controller`.
  #
  # Specifically, the internals of this: https://github.com/CruGlobal/mpdx/blob/8d2f74a9955ad4eb2c2e3faa3c1caca50a7ce97e/app/controllers/auth/accounts_controller.rb#L23
  # and this: https://github.com/CruGlobal/mpdx/blob/8d2f74a9955ad4eb2c2e3faa3c1caca50a7ce97e/app/controllers/auth/accounts_controller.rb#L32
  def create_user
    user = Person::KeyAccount.create_user_from_auth(omniauth_attributes_hash)

    Person::KeyAccount.find_or_create_from_auth(omniauth_attributes_hash, user)

    user
  end

  def find_user
    User.find_by_guid(guids)
  end
end
