require 'rails_helper'

module Sipity
  module Models
    RSpec.describe TodoItemState, type: :model do
      subject { described_class.new }

      it 'belongs to a :entity' do
        expect(described_class.reflect_on_association(:entity)).
          to be_a(ActiveRecord::Reflection::AssociationReflection)
      end

      context '#enrichment_state' do
        it 'will raise an ArgumentError if you provide an invalid value' do
          expect { subject.enrichment_state = '__incorrect_state__' }.to raise_error(ArgumentError)
        end

        it 'will initialize with a default' do
          expect(subject.enrichment_state).to be_present
        end
      end
    end
  end
end
