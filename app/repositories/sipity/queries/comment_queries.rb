module Sipity
  module Queries
    # Queries
    module CommentQueries
      def find_comments_for_work(work:)
        entity = Conversions::ConvertToProcessingEntity.call(work)
        Sipity::Models::Processing::Comment.where(entity_id: entity.id).order('created_at DESC')
      end

      def find_current_comments_for_work(work:)
        entity = Conversions::ConvertToProcessingEntity.call(work)
        comments = Models::Processing::Comment.arel_table
        entities = Models::Processing::Entity.arel_table
        actions = Models::Processing::StrategyAction.arel_table

        Models::Processing::Comment.where(
          comments[:entity_id].eq(entity.id).and(
            comments[:originating_strategy_action_id].in(
              actions.project(
                actions[:id]
              ).join(entities).on(
                actions[:resulting_strategy_state_id].eq(entities[:strategy_state_id])
              ).where(entities[:id].eq(entity.id))
            )
          )
        ).order('created_at DESC')
      end
    end
  end
end
