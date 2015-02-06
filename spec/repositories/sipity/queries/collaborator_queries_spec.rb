require 'spec_helper'

module Sipity
  module Queries
    RSpec.describe CollaboratorQueries, type: :isolated_repository_module do
      let(:work) { Models::Work.new(id: '123') }
      let(:work_two) { Models::Work.new(id: '456') }
      subject { test_repository }

      context '#find_or_initialize_collaborators' do
        subject { test_repository.find_or_initialize_collaborators_by(work: work, id: '12') }
        it 'will initialize a collaborator based on the work id' do
          expect(subject.work_id).to eq(work.id)
        end
      end

      context '.work_collaborators_for' do
        it 'returns the collaborators for the given work and role' do
          Models::Collaborator.create!(work: work, role: 'author', name: 'jeremy')
          expect(subject.work_collaborators_for(work: work, role: 'author').count).to eq(1)
        end
        it 'returns the collaborators for the given work' do
          one = Models::Collaborator.create!(work: work, role: 'author', name: 'jeremy')
          two = Models::Collaborator.create!(work: work, role: 'advisor', name: 'jeremy')
          three = Models::Collaborator.create!(work: work_two, role: 'advisor', name: 'jeremy')
          expect(subject.work_collaborators_for(work: work)).to eq([one, two])
          expect(subject.work_collaborators_for(role: 'advisor')).to eq([two, three])
        end
      end

      context '.work_collaborator_names_for' do
        it 'returns only the names' do
          Models::Collaborator.create!(work: work, role: 'author', name: 'John')
          expect(subject.work_collaborator_names_for(work: work)).to eq(['John'])
        end
      end
    end
  end
end
