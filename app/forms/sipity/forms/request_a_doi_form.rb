module Sipity
  module Forms
    # Submit a request for a DOI for the given Sip
    class RequestADoiForm < BaseForm
      self.policy_enforcer = Policies::EnrichSipByFormSubmissionPolicy

      def initialize(attributes = {})
        self.sip = attributes.fetch(:sip)
        @publisher, @publication_date = attributes.values_at(:publisher, :publication_date)
      end

      attr_accessor :publisher, :publication_date, :sip
      private(:sip=) # Adding parenthesis because Beautify ruby was going crazy

      delegate :title, to: :sip

      validates :sip, presence: true
      validates :publisher, presence: true
      validates :publication_date, presence: true

      def authors(decorator: Decorators::CollaboratorDecorator)
        Queries::CollaboratorQueries.sip_collaborators_for(sip: sip, role: 'author').
          map { |obj| decorator.decorate(obj) }
      end
    end
  end
end
