class AccountListsController < ApplicationController
  def sharing
    @page_title = _('Account Sharing & Merging')
    @mergeable_accounts = current_user.account_lists - [current_account_list]
  end

  def share
    if EmailValidator.valid?(params[:email])
      AccountListInvite.send_invite(current_user, current_account_list, params[:email])

      flash[:notice] =
        _('An invitation was sent to %{email}. When they open it and log in they will get access.')
        .localize % { email: params[:email] }
    else
      flash[:alert] = _('Please specify a valid email to send the invite.')
    end

    redirect_to sharing_account_lists_path
  end

  def accept_invite
    invite = AccountListInvite.find_by(code: params[:code],
                                       account_list_id: params[:id])

    if invite && invite.accept(current_user)
      flash[:notice] =
        _('You now have access to "%{account}", and can select it in the drop down above.')
        .localize % { account: invite.account_list.name }
    else
      flash[:alert] = _('This invitation is no longer valid.')
    end

    redirect_to root_path
  end

  def cancel_invite
    invite = current_account_list.account_list_invites.find(params[:invite_id])
    if current_user.can_manage_sharing?(current_account_list)
      invite.cancel(current_user)
      flash[:notice] = _('Invite canceled.')
    else
      flash[:alert] = _('You are not allowed to manage sharing for this account.')
    end
    redirect_to sharing_account_lists_path
  end

  def remove_access
    user_to_remove = current_account_list.users.find_by(id: params[:user_id])
    if user_to_remove.nil?
      flash[:notice] = _('User already removed')
    elsif current_user.can_manage_sharing?(current_account_list)
      user_to_remove.remove_access(current_account_list)
      flash[:notice] = _('User account access removed.')
    else
      flash[:alert] = _('You are not allowed to manage sharing for this account.')
    end
    redirect_to sharing_account_lists_path
  end

  def merge
    merge_account_list = current_user.account_lists.find_by(id: params[:merge_id])

    if merge_account_list && merge_account_list != current_account_list
      current_account_list.merge(merge_account_list)

      flash[:notice] =
        _('The account %{loser} has been merged into %{winner}')
        .localize % { loser: merge_account_list.name, winner: current_account_list.name }
    end

    redirect_to sharing_account_lists_path
  end
end
