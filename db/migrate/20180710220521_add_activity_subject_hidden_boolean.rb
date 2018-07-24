class AddActivitySubjectHiddenBoolean < ActiveRecord::Migration
  def change
    add_column :activities, :subject_hidden, :boolean, default: false, nil: false
    add_index :activities, :subject_hidden
  end
end
