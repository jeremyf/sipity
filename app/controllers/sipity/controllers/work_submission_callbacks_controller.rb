module Sipity
  module Controllers
    # The controller for handling callbacks for work submissions
    #
    # It is unlikely that you will need to make modifications to this
    # controller; This controller passes the received JSON document to
    # the processing form associated with the given :processing_action_name
    #
    # @note The :processing_action_name comes from the config/routes.rb file.
    class WorkSubmissionCallbacksController < AuthenticatedController
      skip_before_action :verify_authenticity_token

      class_attribute :response_handler_container
      self.runner_container = Sipity::Runners::WorkSubmissionsRunners
      self.response_handler_container = Sipity::ResponseHandlers::WorkSubmissionCallbackHandler

      def command_action
        run_and_respond_with_processing_action(work_id: work_id, attributes: command_attributes)
      end

      def initialize(*args, &block)
        super(*args, &block)
        self.processing_action_composer = ProcessingActionComposer.build_for_controller(controller: self)
      end

      delegate(
        :prepend_processing_action_view_path_with,
        :run_and_respond_with_processing_action,
        to: :processing_action_composer
      )

      attr_accessor :view_object
      helper_method :view_object
      alias model view_object
      helper_method :model

      private

      attr_accessor :processing_action_composer

      def work_id
        params.require(:work_id)
      end

      # This is a bit different as I am matching to the WEBHOOK documentation. The WEBHOOK posts the following JSON body:
      #
      # ```json
      #   { "host" : "libvirt8.library.nd.edu", "version" : "1.0.1", "job_name" : "ingest-45", "job_state" : "processing" }
      # ```
      #
      # So I need to normalize this data to pass along to the command.
      #
      # @see https://github.com/ndlib/curatend-batch/blob/master/webhook.md
      def command_attributes
        command_attributes = params.fetch(:work) { ActionController::Parameters.new }
        normalized_attributes_for_existing_callback_constraints.each_pair do |key, value|
          command_attributes[key] = value
        end
        request_body_attributes.each_pair do |key, value|
          command_attributes[key] = value
        end
        command_attributes
      end

      def normalized_attributes_for_existing_callback_constraints
        params.except(:action, :controller, :work_id, :processing_action_name, :work, :work_submission, :format)
      end

      # Because not all parameters may be coming from the query params; in fact they may be raw params from the body
      def request_body_attributes
        return {} unless request.format.json?
        return {} unless request.body.present?
        JSON.parse(request.body.read)
      ensure
        request.body.rewind if request.body.present?
      end
    end
  end
end
