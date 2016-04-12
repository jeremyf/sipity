require 'spec_helper'
require 'sipity/conversions/to_rof/work_converters/ulra_converters'
require 'support/shared_examples/an_ulra_submission_converted_to_rof'

module Sipity
  module Conversions
    module ToRof
      module WorkConverters
        RSpec.describe UlraSeniorThesisConverter do
          it_behaves_like 'an ulra submission converted to ROF', af_model: 'SeniorThesis'
        end

        RSpec.describe UlraDocumentConverter do
          it_behaves_like 'an ulra submission converted to ROF', af_model: 'Document'
        end
      end
    end
  end
end
