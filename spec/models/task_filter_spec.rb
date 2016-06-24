require 'spec_helper'

RSpec.describe TaskFilter, type: :model do
  before do
    create(:task, completed: true, starred: false, no_date: false, activity_type: 'Email')
    create(:task, completed: false, starred: true, no_date: false, activity_type: 'Call')
    create(:task, completed: false, starred: false, no_date: true, activity_type: 'Call')
  end

  it 'filters through completed tasks' do
    task_filter = TaskFilter.new(:completed => true)
    filtered = task_filter.filter(Task.all)
    expect(filtered.length).to eq(1)
  end

  it 'filters through overdue tasks' do
    task_filter = TaskFilter.new(:overdue => true)
    filtered = task_filter.filter(Task.all)
    expect(filtered.length).to eq(2)
  end

  it 'filters through starred tasks' do
    task_filter = TaskFilter.new(:starred => true)
    filtered = task_filter.filter(Task.all)
    expect(filtered.length).to eq(1)
  end

  it 'filters through no_date tasks' do
    task_filter = TaskFilter.new(:no_date => true)
    filtered = task_filter.filter(Task.all)
    expect(filtered.length).to eq(1)
  end

  it 'filters through tasks by activity_type' do
    task_filter = TaskFilter.new(:activity_type => 'Email')
    filtered = task_filter.filter(Task.all)
    expect(filtered.length).to eq(1)
  end
end
