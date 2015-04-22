module Sipity
  module Decorators
    module Processing
      # Responsible for exposing methods required to display comments . Nothing
      # too fancy.
      class ProcessingCommentDecorator < ApplicationDecorator
        def initialize(processing_comment, _opts = {})
          self.processing_comment = processing_comment
        end

        def name_of_commentor
          actor.proxy_for.name
        end

        def work_type
          work.work_type.titleize
        end

        delegate :comment, :actor, :entity, to: :processing_comment
        private :actor, :entity

        private

        attr_accessor :processing_comment

        def work
          entity.proxy_for
        end
      end
    end
  end
end
