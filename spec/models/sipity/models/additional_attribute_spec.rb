require 'rails_helper'

module Sipity
  module Models
    RSpec.describe AdditionalAttribute, type: :model do
      it 'belongs to :work' do
        expect(described_class.reflect_on_association(:work)).
          to be_a(ActiveRecord::Reflection::AssociationReflection)
      end

      it 'will raise an ArgumentError if you provide an invalid key' do
        expect { subject.key = '__incorrect_strategy__' }.to raise_error(ArgumentError)
      end

    end
  end
end
