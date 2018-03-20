module Concerns
  module TntImport
    module TaskHelpers
      private

      def import_comments_for_task(task:, notes: nil, tnt_task_type_id: nil)
        task.comments.where(body: notes.strip).first_or_create if notes.present?

        unsupported_type_name = ::TntImport::TntCodes.unsupported_task_type(tnt_task_type_id)
        if unsupported_type_name
          comment_body = _(%(This task was given the type "#{unsupported_type_name}" in TntConnect.))
          task.comments.where(body: comment_body).first_or_create
        end

        task.comments
      end
    end
  end
end
