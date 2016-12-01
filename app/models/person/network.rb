class Person::Network
	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :person_id

	def id
		1
	end

	def created_at
		Date.new
	end

	def updated_at
		Date.new
	end

  def facebook_accounts
  	person.facebook_accounts
  end

  def linkedin_accounts
  	person.linkedin_accounts
  end

  def twitter_accounts
  	person.twitter_accounts
  end

  def websites
  	person.websites
  end

  def person
  	@person ||= Person.find(self.person_id)
  end

  # def self.attributes
  # 	[ :authenticated,
  #     :created_at,
  #     :first_name,
  #     :id,
  #     :last_name,
  #     :person_id,
  #     :primary,
  #     :public_url,
  #     :remote_id,
  #     :screen_name,
  #     :type,
  #     :updated_at,
  #     :url,
  #     :username
  #   ]
  # end

  # attr_accessor *self.attributes
  
  # def load_networks
  # 	facebook_accounts + linkedin_accounts + twitter_accounts + websites
  # end

  # private

  # def facebook_accounts
  # 	create_networks_from_results(person.facebook_accounts, 'facebook')
  # end

  # def linkedin_accounts
  # 	create_networks_from_results(person.linkedin_accounts, 'linkedin')
  # end

  # def twitter_accounts
  # 	create_networks_from_results(person.twitter_accounts, 'twitter')
  # end

  # def websites
  # 	create_networks_from_results(person.websites, 'website')
  # end

  # def person
  # 	@person ||= Person.find(self.person_id)
  # end

  # def create_networks_from_results(results, type)
  # 	results.map{ |o| Person::Network.new(o.attributes.keep_if{ |k, _| self.class.attributes.include? k.to_sym }.merge(type: type)) }
  # end
end