class AddActivitySubjectHiddenBoolean < ActiveRecord::Migration
  def change
    add_column :activities, :subject_hidden, :boolean
  end
end
