require 'rails_helper'
load 'db/migrate/20170307220854_update_all_timestamp_columns_to_be_non_null.rb'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe UpdateAllTimestampColumnsToBeNonNull, type: :migration do
  describe 'TIMESTAMP_COLUMN_NAMES' do
    subject { UpdateAllTimestampColumnsToBeNonNull::TIMESTAMP_COLUMN_NAMES }

    it 'should contain exactly created_at and updated_at' do
      is_expected.to contain_exactly('created_at', 'updated_at')
    end
  end

  describe '#up' do
    let(:model) do
      Class.new(ActiveRecord::Base) do
        self.table_name = 'my_test_table'
      end
    end

    context 'with a table that has nullable timestamp fields' do
      before { prep_database_for_spec(allow_null_values: true) }

      it 'should make the timestamp columns non-null' do
        timestamp_names = UpdateAllTimestampColumnsToBeNonNull::TIMESTAMP_COLUMN_NAMES

        expect { run_migration_being_tested }
          .to change {
            model
              .columns
              .select { |column| column.name.in?(timestamp_names) }
              .all? { |column| column.null == false }
          }.from(false).to(true)
      end

      it 'should not modify the data in the timestamp columns if it is not null' do
        record = model.create!
        record.reload

        expect do
          run_migration_being_tested
          record.reload
        end.to not_change(record, :created_at).and(not_change(record, :updated_at))
      end

      context 'and when the columns have null data in them' do
        let!(:record) do
          model.record_timestamps = false
          model.create!(created_at: nil, updated_at: nil).tap do
            model.record_timestamps = true
          end
        end

        it 'should update the data to the current timestamp' do
          expect do
            run_migration_being_tested
            record.reload
          end.to(
            change(record, :created_at)
              .from(nil)
              .to(be_an(ActiveSupport::TimeWithZone))
              .and(
                change(record, :updated_at)
                  .from(nil)
                  .to(be_an(ActiveSupport::TimeWithZone))
              )
          )
        end
      end
    end

    context 'with a table that has non-null timestamp fields' do
      before { prep_database_for_spec(allow_null_values: false) }

      it 'should not modify the table columns' do
        timestamp_names = UpdateAllTimestampColumnsToBeNonNull::TIMESTAMP_COLUMN_NAMES

        expect { run_migration_being_tested }
          .to_not change {
            model
              .columns
              .select { |column| column.name.in?(timestamp_names) }
              .all? { |column| column.null == false }
          }
      end

      it 'should not modify the data in the columns' do
        record = model.create!
        record.reload

        expect do
          run_migration_being_tested
          record.reload
        end.to(
          not_change(record, :created_at)
          .and(
            not_change(record, :updated_at)
          )
        )
      end
    end
  end

  describe '#down' do
    it 'raises IrreversibleMigration' do
      migration = UpdateAllTimestampColumnsToBeNonNull.new

      expect { migration.down }
        .to raise_error(ActiveRecord::IrreversibleMigration)
    end
  end

  private

  def run_migration_being_tested
    migration = UpdateAllTimestampColumnsToBeNonNull.new
    migration.up

    model.reset_column_information
  end

  def new_test_setup_migration(null:)
    Class.new(ActiveRecord::Migration) do
      def initialize(null)
        @null = null
      end

      def up
        create_table 'my_test_table' do |t|
          t.timestamps null: @null
        end
      end
    end.new(null)
  end

  def prep_database_for_spec(allow_null_values:)
    ActiveRecord::Migration.verbose = false
    migration = new_test_setup_migration(null: allow_null_values)

    migration.up
    model.reset_column_information
  end
end
