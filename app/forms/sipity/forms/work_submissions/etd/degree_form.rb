module Sipity
  module Forms
    module WorkSubmissions
      module Etd
        # Responsible for capturing and validating information for degree.
        class DegreeForm < WorkEnrichments::DegreeForm
          def initialize(work:, repository:, attributes:, processing_action_name:)
            super(attributes.merge(work: work, repository: repository, enrichment_type: processing_action_name))
          end
        end
      end
    end
  end
end
