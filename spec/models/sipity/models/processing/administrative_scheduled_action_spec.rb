require 'rails_helper'

module Sipity
  module Models
    module Processing
      RSpec.describe AdministrativeScheduledAction, type: :model do
        subject { described_class }
        its(:column_names) { is_expected.to include("scheduled_time") }
        its(:column_names) { is_expected.to include("reason") }
        its(:column_names) { is_expected.to include("entity_id") }
      end
    end
  end
end
