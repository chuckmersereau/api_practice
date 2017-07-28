module Concerns
  module TntImport
    module TaskHelpers
      private

      def import_comments_for_task(task:, notes: nil, tnt_task_type_id: nil)
        task.comments.where(body: notes.strip).first_or_create if notes.present?

        if ::TntImport::TntCodes::UNSUPPORTED_TNT_TASK_CODES.keys.include?(tnt_task_type_id)
          task.comments.where(body: _(%(This task was given the type "#{::TntImport::TntCodes::UNSUPPORTED_TNT_TASK_CODES[tnt_task_type_id]}" in TntConnect.))).first_or_create
        end

        task.comments
      end
    end
  end
end
