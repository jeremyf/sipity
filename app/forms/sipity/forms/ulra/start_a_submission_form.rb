module Sipity
  module Forms
    module Ulra
      # Responsible for creating a new work within the ULRA work area.
      # What goes into this is more complicated that the entity might allow.
      class StartASubmissionForm < BaseForm
        # Because creating a new work is enforced by the container in which the
        # work is to be created.
        self.policy_enforcer = Policies::SubmissionWindowPolicy

        def self.model_name
          Models::Work.model_name
        end

        def initialize(submission_window:, attributes: {}, repository: default_repository, processing_action_name: 'start_a_submission')
          self.repository = repository
          self.processing_action_name = processing_action_name
          initialize_work_area!
          self.submission_window = submission_window
          initialize_attributes(attributes)
        end

        def available_award_category
          repository.get_controlled_vocabulary_values_for_predicate_name(name: 'award_category')
        end

        attr_reader :title, :award_category, :work_publication_strategy, :advisor_netid, :work_type

        private

        attr_accessor :processing_action_name, :repository
        attr_writer :repository, :title, :award_category, :work_publication_strategy, :advisor_netid, :work_type
        attr_reader :submission_window, :work_area

        public

        delegate :to_processing_entity, :slug, :work_area_slug, to: :submission_window
        alias_method :to_model, :submission_window

        validates :title, presence: true
        validates :award_category, presence: true
        validates :advisor_netid, presence: true
        validates :work_publication_strategy, presence: true, inclusion: { in: :possible_work_publication_strategies }
        validates :work_type, presence: true
        validates :submission_window, presence: true

        def work_publication_strategies_for_select
          possible_work_publication_strategies.map { |elem| elem.first.to_sym }
        end

        def submit(requested_by:)
          return false unless valid?
          create_the_work do |work|
            # I believe this form has too much knowledge of what is going on;
            # Consider pushing some of the behavior down into the repository.
            repository.grant_creating_user_permission_for!(entity: work, user: requested_by)

            # TODO: See https://github.com/ndlib/sipity/issues/506
            repository.send_notification_for_entity_trigger(
              notification: "confirmation_of_work_created", entity: work, acting_as: 'creating_user'
            )
            repository.log_event!(entity: work, user: requested_by, event_name: event_name)
          end
        end

        private

        def initialize_attributes(attributes)
          self.title = attributes[:title]
          self.advisor_netid = attributes[:advisor_netid]
          self.award_category = attributes[:award_category]
          self.work_type = attributes[:work_type]
          self.work_publication_strategy = attributes[:work_publication_strategy]
        end

        include Conversions::SanitizeHtml
        def title=(value)
          @title = sanitize_html(value)
        end

        def create_the_work
          work = repository.create_work!(
            submission_window: submission_window,
            title: title,
            advisor_netid: advisor_netid,
            award_category: award_category,
            work_publication_strategy: work_publication_strategy,
            work_type: work_type
          )
          yield(work)
          work
        end

        def possible_work_publication_strategies
          Models::Work.work_publication_strategies
        end

        def event_name
          File.join(self.class.to_s.demodulize.underscore, 'submit')
        end

        def default_repository
          CommandRepository.new
        end

        DEFAULT_WORK_AREA_SLUG = 'ulra'.freeze
        def initialize_work_area!
          @work_area = repository.find_work_area_by(slug: DEFAULT_WORK_AREA_SLUG)
        end

        def submission_window=(input)
          @submission_window = PowerConverter.convert(input, to: :submission_window, scope: work_area)
        end
      end
    end
  end
end
