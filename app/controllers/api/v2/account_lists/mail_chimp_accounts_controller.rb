module Api
  module V2
    module AccountLists
      class MailChimpAccountsController < AccountListsController
        def pundit_user
          current_user
        end

        def sync
          load_resource
          authorize @resource
          @resource.queue_export_to_primary_list
          render_200
        end

        def load_resource
          @resource ||= resource_scope
          raise ActiveRecord::RecordNotFound unless @resource
        end

        def build_resource
          @resource = current_account_list.build_mail_chimp_account(auto_log_campaigns: true)
          @resource.assign_attributes(resource_params)
        end

        def resource_attributes
          MailChimpAccount::PERMITTED_ATTRIBUTES
        end

        def resource_scope
          current_account_list.mail_chimp_account
        end

        def render_resource
          render json: @resource, scope: { current_account_list: current_account_list }
        end
      end
    end
  end
end
