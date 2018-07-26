class AddSubjectHiddenIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :activities, :subject_hidden, algorithm: :concurrently
  end
end
