class CreateBackgroundBatchRequests < ActiveRecord::Migration
  def change
    create_table :background_batch_requests do |t|
      t.belongs_to :background_batch, index: true, foreign_key: true
      t.string :path
      t.string :request_params
      t.string :request_body
      t.string :request_headers
      t.string :request_method, default: 'GET'
      t.string :response_headers
      t.string :response_body
      t.string :response_status
      t.integer :status, default: 0
      t.boolean :default_account_list, default: false
      t.uuid :uuid, null: false, index: true, default: 'uuid_generate_v4()'

      t.timestamps null: false
    end
  end
end
