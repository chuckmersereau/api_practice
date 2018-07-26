class AddDefaultValueForSubjectHidden < ActiveRecord::Migration
  def up
    change_column_default :activities, :subject_hidden, false
  end

  def down
    change_column_default :activities, :subject_hidden, nil
  end
end
