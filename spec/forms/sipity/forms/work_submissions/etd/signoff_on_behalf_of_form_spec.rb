require 'spec_helper'

module Sipity
  module Forms
    module WorkSubmissions
      module Etd
        RSpec.describe SignoffOnBehalfOfForm do
          let(:processing_entity) { Models::Processing::Entity.new(strategy_id: 1) }
          let(:work) { double('Work', to_processing_entity: processing_entity) }
          let(:repository) { CommandRepositoryInterface.new }
          let(:action) { Models::Processing::StrategyAction.new(strategy_id: processing_entity.strategy_id) }
          let(:base_options) { { work: work, processing_action_name: action, repository: repository } }

          subject { described_class.new(base_options) }

          it { should respond_to :work }
          its(:template) { should eq(Forms::STATE_ADVANCING_ACTION_CONFIRMATION_TEMPLATE_NAME) }

          let(:someone) { double(id: 'one') }

          before do
            allow_any_instance_of(Forms::ComposableElements::OnBehalfOfCollaborator).
              to receive(:valid_on_behalf_of_collaborator_ids).and_return([someone.id])
            allow_any_instance_of(Forms::ComposableElements::OnBehalfOfCollaborator).
              to receive(:valid_on_behalf_of_collaborators).and_return([someone])
            allow_any_instance_of(Forms::ComposableElements::OnBehalfOfCollaborator).
              to receive(:on_behalf_of_collaborator).and_return(someone)
          end

          context 'validation' do
            it 'will require that someone be specified for approval' do
              subject.valid?
              expect(subject.errors[:on_behalf_of_collaborator_id]).to be_present
            end
            it 'will require that someone amongst the collaborators is specified' do
              subject = described_class.new(base_options.merge(on_behalf_of_collaborator_id: '__no_one__'))
              subject.valid?
              expect(subject.errors[:on_behalf_of_collaborator_id]).to be_present
            end
          end

          context '#render' do
            it 'will expose select box' do
              form_object = double('Form Object')
              expect(form_object).to receive(:input).with(:on_behalf_of_collaborator_id, collection: [someone], value_method: :id).
                and_return("<input />")
              expect(subject.render(f: form_object)).to eq("<input />")
            end
          end

          context 'valid submission' do
            let(:user) { double('User') }
            let(:signoff_service) { double('Signoff Service', call: true) }
            let(:on_behalf_of_collaborator) { double('Collaborator') }
            subject do
              described_class.new(
                work: work, repository: repository, signoff_service: signoff_service, attributes: {
                  on_behalf_of_collaborator_id: 'someone_valid'
                }
              )
            end
            before do
              allow(subject).to receive(:on_behalf_of_collaborator).and_return(on_behalf_of_collaborator)
              allow(subject).to receive(:valid?).and_return(true)
            end

            it 'will call the signoff_service (because the logic is complicated)' do
              expect(signoff_service).to receive(:call).
                with(
                  form: subject,
                  requested_by: user,
                  repository: repository,
                  on_behalf_of: on_behalf_of_collaborator,
                  also_register_as: described_class::RELATED_ACTION_FOR_SIGNOFF
                )
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