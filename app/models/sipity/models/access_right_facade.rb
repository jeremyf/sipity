module Sipity
  module Models
    # Responsible for providing a bridge for managing an AccessRight indirectly.
    # That is to say, I don't want to create AccessRights for everything only
    # as needed and finalized.
    #
    # This behavior is achievable by way of ActiveRecord tomfoolery (i.e. a
    # find_by_sql or some such thing that joins multiple models but pushes it
    # onto a single ActiveRecord object). But that could be confusing.
    class AccessRightFacade
      include ActiveModel::Validations

      def initialize(accessible_object)
        self.accessible_object = accessible_object
      end

      delegate :to_param, :id, :persisted?, :to_s, to: :@accessible_object
      delegate :access_right_code, :release_date, to: :access_right_object
      alias_method :entity_id, :id
      attr_reader :entity_type
      attr_reader :accessible_object
      private :accessible_object

      def human_attribute_name(name)
        accessible_object.class.human_attribute_name(name)
      end

      def access_url
        if accessible_object.respond_to?(:file_url)
          accessible_object.file_url
        else
          view_context.polymorphic_url(accessible_object)
        end
      end

      private

      include Conversions::ConvertToPolymorphicType
      def accessible_object=(object)
        @entity_type = convert_to_polymorphic_type(object)
        @accessible_object = object
      end

      def access_right_object
        @access_right_object ||= Models::AccessRight.find_or_initialize_by(entity_id: entity_id, entity_type: entity_type)
      end

      def view_context
        Draper::ViewContext.current
      end
    end
  end
end
