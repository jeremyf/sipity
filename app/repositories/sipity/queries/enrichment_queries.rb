require 'sipity/forms/work_enrichments'

module Sipity
  module Queries
    # Queries
    module EnrichmentQueries
      def build_enrichment_form(attributes = {})
        # REVIEW: Should this entire behavior be delegated to the
        #   Form::WorkEnrichments module?
        enrichment_type = attributes.fetch(:enrichment_type)
        builder = Forms::WorkEnrichments.find_enrichment_form_builder(enrichment_type: enrichment_type)
        builder.new(attributes)
      end

      def todo_list_for_current_processing_state_of_work(work:, processing_state: work.processing_state)
        # TODO: Can I tease apart the collaborator? I'd like to send a builder object
        # as a parameter. It would ease the entaglement that is happening here.
        Decorators::TodoList.new(entity: work) do |list|
          Models::TodoItemState.where(entity: work, entity_processing_state: processing_state).each do |todo_item|
            # REVIEW: Why is this the 'required' set; It should be based on something else.
            # For now, however, it stands.
            list.add_to(set: 'required', name: todo_item.enrichment_type, state: todo_item.enrichment_state)
          end
        end
      end
      module_function :todo_list_for_current_processing_state_of_work
      public :todo_list_for_current_processing_state_of_work
    end
  end
end
