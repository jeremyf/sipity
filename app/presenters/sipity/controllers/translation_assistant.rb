module Sipity
  module Controllers
    # Responsible for assisting in the normalization of the translations in a
    # predictable and repeatable manner.
    module TranslationAssistant
      module_function

      # This .call is ultimately resonsible for building the strategy for
      # looking up translation options and injecting appropriate information.
      #
      # Below is the sequence of keys that we will attempt to translate.
      #
      # 1. :<scope>.work_area/<work_area>.work_type/<work_type>.<object>.<predicate>
      # 2. :<scope>.work_type/<work_type>.<object>.<predicate>
      # 3. :<scope>.<object>.<predicate>
      # 4. <object.to_s.humanize>
      def call(scope:, subject:, object: subject, predicate:)
        scope = scope.to_s.pluralize
        defaults = [:"#{object}.#{predicate}", object.to_s.humanize]
        options = { scope: scope, default: defaults }

        inject_work_type(scope: scope, subject: subject, options: options, defaults: defaults)
        inject_work_area(scope: scope, subject: subject, options: options, defaults: defaults)

        first_key_to_try = defaults.shift
        I18n.translate(first_key_to_try, options).html_safe
      rescue I18n::MissingInterpolationArgument => e
        Rails.logger.debug("#{e.class}: #{e.message}. Falling back to default.")
        object.to_s.humanize
      end

      def inject_work_type(scope:, subject:, options:, defaults:)
        return if scope == 'work_types'
        # TODO: I could leverage power converter, but the work_type has not yet
        # been fully migrated to a relationship.
        return unless subject.respond_to?(:work_type)
        return if subject == subject.work_type
        defaults.unshift(:"work_type/#{subject.work_type}.#{defaults.first}")
        options[:work_type] = call(
          scope: 'work_types', subject: subject.work_type, predicate: :label
        )
      end
      private_class_method :inject_work_type

      def inject_work_area(scope:, subject:, options:, defaults:)
        return if scope == 'work_areas'
        begin
          work_area = PowerConverter.convert_to_work_area(subject)
          defaults.unshift(:"work_area/#{work_area.slug}.#{defaults.first}")
          options[:work_area] = work_area.name
        rescue PowerConverter::ConversionError
          nil
          # No need to do anything; We just don't have a work area type of object
        end
      end
      private_class_method :inject_work_area
    end
  end
end
