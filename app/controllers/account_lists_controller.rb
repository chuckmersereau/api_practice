class AccountListsController < ApplicationController
  def sharing
    @page_title = _('Account Sharing & Merging')
    @mergeable_accounts = current_user.account_lists - [current_account_list]
  end

  def share
    if EmailValidator.valid?(params[:email])
      current_user.send_account_list_invite(current_account_list, params[:email])

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

    if invite
      invite.accept_and_destroy(current_user)
      flash[:notice] =
        _('You now have access "%{account}", and select it in the drop down above.')
        .localize % { account: invite.account_list.name }
    else
      flash[:alert] = _('This invitation is no longer valid.')
    end

    redirect_to root_path
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
