require 'rails_helper'

describe Concerns::TntImport::TaskHelpers do
  let(:test_class) do
    Class.new do
      include Concerns::TntImport::TaskHelpers
    end
  end

  let(:task) { create(:task) }

  let(:unsupported_tnt_task_id) { TntImport::TntCodes::UNSUPPORTED_TNT_TASK_CODES.keys.first }

  it 'does not add comments if no extra args are given' do
    expect do
      test_class.new.send(:import_comments_for_task, task: task)
    end.to_not change { task.reload.comments.count }
  end

  it 'adds a comment for a tnt notes' do
    expect do
      test_class.new.send(:import_comments_for_task, task: task, notes: 'A non-notable note')
    end.to change { task.reload.comments.where(body: 'A non-notable note').count }.from(0).to(1)
  end

  it 'does not add a duplicate comment for a note' do
    test_class.new.send(:import_comments_for_task, task: task, notes: 'A non-notable note')
    expect do
      test_class.new.send(:import_comments_for_task, task: task, notes: 'A non-notable note')
    end.to_not change { task.reload.comments.count }.from(1)
  end

  it 'adds a comment for an unsupported tnt task type' do
    expect do
      test_class.new.send(:import_comments_for_task, task: task, tnt_task_type_id: unsupported_tnt_task_id)
    end.to change { task.reload.comments.count }.from(0).to(1)
    expect(task.comments.where(body: 'This task was given the type "Present" in TntConnect.').count).to eq(1)
  end

  it 'returns the added comments' do
    result = test_class.new.send(:import_comments_for_task,
                                 task: task,
                                 notes: 'Hello',
                                 tnt_task_type_id: unsupported_tnt_task_id)
    expect(result.size).to eq(2)
    expect(result.all? { |item| item.is_a?(ActivityComment) }).to eq(true)
  end
end
