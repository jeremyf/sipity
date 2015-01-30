module Sipity
  module Services
    # A service object to help query and build a heterogeneous set of actions
    # based on event_names.
    class ActionSet
      include Enumerable
      Action = Struct.new(:name, :availability_state)

      UNKNOWN_CURRENT_ACTION = '__unknown_current_action__'.freeze
      ANALOGOUS_NAMED_ACTIONS = {
        'show' => ['show'],
        'update' => ['edit', 'update'],
        'edit' => ['edit', 'update'],
        'create' => ['new', 'create'],
        'new' => ['new', 'create'],
        'destroy' => ['destroy']
      }.freeze
      INTRA_STATE_ACTIONS = ANALOGOUS_NAMED_ACTIONS.keys

      attr_reader :entity, :current_action, :event_names, :repository, :actions
      def initialize(options = {})
        @entity = options.fetch(:entity)
        @event_names = Array.wrap(options.fetch(:event_names))
        @current_action = options.fetch(:current_action) { UNKNOWN_CURRENT_ACTION }
        @repository = options.fetch(:repository) { default_repository }
        build_actions!
      end

      def each
        actions.each {|action| yield(action) }
      end

      private

      def build_actions!
        @actions = []
        event_names_without_current_event.each do |event_name|
          availability_state = determine_availability_state_for(event_name)
          @actions << Action.new(event_name, availability_state)
        end
      end

      def event_names_without_current_event
        event_names - Array.wrap(ANALOGOUS_NAMED_ACTIONS[current_action])
      end

      def default_repository
        QueryRepository.new
      end

      def determine_availability_state_for(event_name)
        return 'available' if INTRA_STATE_ACTIONS.include?(event_name)
        return 'available' if repository.are_all_of_the_required_todo_items_done_for_work?(work: entity)
        'unavailable'
      end
    end
  end
end
