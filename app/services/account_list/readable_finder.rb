# Finds [AccountList] records which a given user either has access to, or is a
# [User::Coach] of.
class AccountList::ReadableFinder
  delegate :to_sql, to: :query

  def initialize(user_or_id)
    @user_or_id = user_or_id
  end

  def user
    @user ||= @user_or_id.is_a?(User) ? @user_or_id : User.find(@user_or_id)
  end

  def relation
    AccountList.where(to_sql)
  end

  private

  def query
    arel_account_lists[:id].in(subquery)
  end

  def subquery
    join_tables(arel_account_lists).where(where_clause).project(projection)
  end

  def join_tables(arel)
    arel.join(arel_coaches, Arel::Nodes::OuterJoin)
        .on(arel[:id].eq(arel_coaches[:account_list_id]))
        .join(arel_users, Arel::Nodes::OuterJoin)
        .on(arel[:id].eq(arel_users[:account_list_id]))
  end

  def where_clause
    arel_users[:user_id].eq(user.id).or(arel_coaches[:coach_id].eq(user.id))
  end

  def projection
    arel_account_lists[:id]
  end

  def arel_account_lists
    @arel_account_lists ||= AccountList.arel_table
  end

  def arel_coaches
    @arel_coaches ||= AccountListCoach.arel_table
  end

  def arel_users
    @arel_users ||= AccountListUser.arel_table
  end
end
