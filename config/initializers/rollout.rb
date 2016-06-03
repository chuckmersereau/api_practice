require Rails.root.join('config', 'initializers', 'redis').to_s
$rollout = Rollout.new(Redis.current)
RolloutUi.wrap($rollout)

$rollout.define_group(:testers) do |account_list|
  account_list.tester == true
end

$rollout.define_group(:owners) do |account_list|
  account_list.owner == true
end

$rollout.define_group(:testers_usa) do |account_list|
  account_list.tester == true && account_list.settings[:home_country] == "United States"
end
