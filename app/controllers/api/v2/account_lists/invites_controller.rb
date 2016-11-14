module Api
  module V2
    module AccountLists
      class InvitesController < AccountListsController
        before_action :authorize_management, except: [:destroy]

        def create
          return show if save_resource
          render json: { success: false, errors: ['Could not send invite'] }, status: 400
        end

        def destroy
          load_resource
          authorize @resource
          @resource.cancel(current_user)
          render_200
        end

        def save_resource
          return false unless EmailValidator.valid?(resource_params['recipient_email'])
          @resource = AccountListInvite.send_invite(current_user, current_account_list, resource_params['recipient_email'])
        end

        def resource_attributes
          AccountListInvite::PERMITTED_ATTRIBUTES
        end

        def resource_scope
          current_account_list.account_list_invites
        end

        private

        def authorize_management
          authorize AccountListInvite.new
        end
      end
    end
  end
end
