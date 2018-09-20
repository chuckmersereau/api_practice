class AddAnswerAndRecordIdToWeeklies < ActiveRecord::Migration
  def change
    add_column :weeklies, :answer, :text
    add_column :weeklies, :question_id, :integer
  end
end
