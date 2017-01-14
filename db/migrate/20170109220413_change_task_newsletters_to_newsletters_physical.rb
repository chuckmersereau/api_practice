class ChangeTaskNewslettersToNewslettersPhysical < ActiveRecord::Migration
  def up
    Task.of_type('Newsletter').update_all(activity_type: 'Newsletter - Physical')
  end

  def down
    Task.of_type('Newsletter - Physical').update_all(activity_type: 'Newsletter')
  end
end
