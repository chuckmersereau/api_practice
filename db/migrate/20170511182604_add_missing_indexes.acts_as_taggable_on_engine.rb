# This migration comes from acts_as_taggable_on_engine (originally 6)
class AddMissingIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :taggings, :tag_id, algorithm: :concurrently
    add_index :taggings, :taggable_type, algorithm: :concurrently
    add_index :taggings, :tagger_id, algorithm: :concurrently
    add_index :taggings, :context, algorithm: :concurrently

    add_index :taggings, [:tagger_id, :tagger_type], algorithm: :concurrently
    add_index :taggings, [:taggable_id, :taggable_type, :tagger_id, :context], name: 'taggings_idy', algorithm: :concurrently
  end
end
