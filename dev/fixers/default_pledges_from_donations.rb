# I used this to set some basic default pledge info for a global user who had
# some trouble with MPDX. The logic it uses is very basic and likely wrong in
# many cases, but the goal was just to do a quick thing to help him out. This
# general idea could be a cool feature to add for someone who is moving to MPDX
# as a senior staff if they don't have TntMPD and want to get a general handle
# on people's commitments based on their giving history

def default_pledges!(account_list)
  puts 'defaulting pledges..'
  account_list.contacts.where(pledge_amount: nil).each(&method(:default_pledge!))
  nil
end

def default_pledge!(contact)
  if contact.pledge_amount.present?
    puts "Pledge for #{contact} ##{contact.id} already set to "\
      "#{contact.plege_amount} "\
      "#{Contact.pledge_frequencies[contact.pledge_frequency]}"
    return
  end
  frequencies = [1, 3, 12]
  frequencies.each do |frequency|
    return if try_frequency!(contact, frequency)
  end
  puts "Pledge for #{contact} ##{contact.id} not changed"
end

def try_frequency!(contact, frequency)
  look_back_period = (frequency * 3).to_i.months.ago.beginning_of_month.to_date
  donations = contact.donations.where('donation_date >= ?', look_back_period)

  # If the person gave between 3 and 4 times in the past 3 complete periods +
  # partial current period then assuming they give at this frequency.
  return false unless (3..4).cover?(donations.count) &&
                      contact.pledge_frequency.nil?

  amount = donations.first.amount
  puts "Pledge for #{contact} ##{contact.id} set to #{amount} "\
    "#{Contact.pledge_frequencies[frequency.to_d]}"
  contact.update!(
    status: 'Partner - Financial', pledge_frequency: frequency,
    pledge_amount: amount, pledge_received: true)
  true
end
