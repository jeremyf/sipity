require 'rails_helper'
require 'sipity/models/processing/comment'

module Sipity
  module Models
    module Processing
      RSpec.describe Comment do

        context 'database configuration' do
          subject { described_class }
          its(:column_names) { is_expected.to include('entity_id') }
          its(:column_names) { is_expected.to include('actor_id') }
          its(:column_names) { is_expected.to include('comment') }
          its(:column_names) { is_expected.to include('originating_strategy_action_id') }
          its(:column_names) { is_expected.to include('originating_strategy_state_id') }
          its(:column_names) { is_expected.to include('stale') }
        end

        subject { described_class.new }
        it 'will expose #name_of_commentor' do
          expect(subject).to receive_message_chain(:actor, :proxy_for, :name).and_return('Hiya')
          expect(subject.name_of_commentor).to eq('Hiya')
        end
      end
    end
  end
end
