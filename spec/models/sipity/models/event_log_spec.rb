require 'rails_helper'

module Sipity
  module Models
    RSpec.describe EventLog, type: :model do

      it { should belong_to(:user) }
      it { should belong_to(:entity) }
      it { should belong_to(:requested_by) }

      # This is a "stop-gap" for validations going forward. Once the database
      # constraint is added this should go away.
      it { should validate_presence_of(:requested_by_id).on(:create) }
      it { should validate_presence_of(:requested_by_type).on(:create) }

      it 'relies on the database to enforce the requirement of an :event_name' do
        expect do
          EventLog.create!(
            user_id: '1', requested_by_id: '1', requested_by_type: 'User', entity_id: '2', entity_type: 'Sipity::Models::Work'
          )
        end.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
