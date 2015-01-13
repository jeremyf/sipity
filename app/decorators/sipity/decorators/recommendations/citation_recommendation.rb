module Sipity
  module Decorators
    module Recommendations
      # Container for the Citation Recommendation
      class CitationRecommendation < Recommendations::Base
        def state
          return :citation_already_assigned if citation_already_assigned?
          return :citation_not_assigned
        end
        alias_method :status, :state

        def path_to_recommendation
          helper.work_citation_path(work)
        end

        private

        def citation_already_assigned?
          repository.citation_already_assigned?(work)
        end
      end
    end
  end
end
