module Sipity
  # :nodoc:
  module Commands
    # REVIEW: Is this the best place to put this information? Do I want to
    #   persist this in a database? Does that make sense?
    #
    # REVIEW: Considere that some enrichments are not required. This associates
    #   the enrichments with the entity, but does not assert policies related to
    #   each enrichment; I believe that is the correct way to do things.
    WORK_TYPE_PROCESSING_STATE_TODO_LIST_ITEMS = {
      'etd' => {
        'new' => ['attach', 'describe']
      }
    }.freeze

    # Responsible for interaction with the todo list.
    module TodoListCommands
      def create_work_todo_list_for_current_state(work:, processing_state: work.processing_state, work_type: work.work_type)
        WORK_TYPE_PROCESSING_STATE_TODO_LIST_ITEMS.fetch(work_type).fetch(processing_state).each do |item_name|
          Models::TodoItemState.create!(entity: work, entity_processing_state: processing_state, enrichment_type: item_name)
        end
      end
    end
    private_constant :TodoListCommands
  end
end
