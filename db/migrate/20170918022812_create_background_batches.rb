class CreateBackgroundBatches < ActiveRecord::Migration
  def change
    create_table :background_batches do |t|
      t.string :batch_id
      t.belongs_to :user, index: true
      t.uuid :uuid, null: false, index: true, default: 'uuid_generate_v4()'
      t.timestamps null: false
    end

    add_foreign_key :background_batches, :people, column: :user_id
  end
end
