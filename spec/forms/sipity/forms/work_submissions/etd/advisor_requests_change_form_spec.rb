require 'spec_helper'

module Sipity
  module Forms
    module WorkSubmissions
      module Etd
        RSpec.describe AdvisorRequestsChangeForm do
          let(:processing_entity) { Models::Processing::Entity.new(strategy_id: 1) }
          let(:work) { double('Work', to_processing_entity: processing_entity) }
          let(:repository) { CommandRepositoryInterface.new }
          let(:user) { User.new(id: 1) }
          subject { described_class.new(work: work, repository: repository) }

          its(:processing_action_name) { should eq('advisor_requests_change') }

          context '#render' do
            let(:f) { double }
            it 'will return an input text area' do
              expect(f).to receive(:input).with(:comment, hash_including(as: :text))
              subject.render(f: f)
            end
          end

          its(:comment_legend) { should be_html_safe }
          it { should_not be_persisted }

          it 'will validate the presence of the :comment' do
            subject.valid?
            expect(subject.errors[:comment]).to be_present
          end

          context 'without valid data' do
            it 'will not save the form' do
              expect(subject).to receive(:valid?).and_return(false)
              expect(subject).to_not receive(:save)
              expect(subject.submit(requested_by: user)).to eq(false)
            end
          end

          context 'with valid data' do
            before do
              expect(subject).to receive(:valid?).and_return(true)
              allow(Services::RequestChangesViaCommentService).to receive(:call)
            end

            it 'will delegate to Services::RequestChangesViaCommentService' do
              expect(Services::RequestChangesViaCommentService).to receive(:call)
              subject.submit(requested_by: user)
            end

            it 'will return the work' do
              expect(subject.submit(requested_by: user)).to eq(work)
            end
          end
        end
      end
    end
  end
end
