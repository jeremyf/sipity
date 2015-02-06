require 'rails_helper'

module Sipity
  module Commands
    RSpec.describe WorkCommands, type: :command_with_related_query do
      before do
        # TODO: Remove this once the deprecation for granting permission is done
        allow(Services::GrantProcessingPermission).to receive(:call)
      end

      context '#assign_collaborators_to' do
        let(:work) { Models::Work.new(id: 123) }
        let(:collaborator) do
          Models::Collaborator.new(responsible_for_review: is_responsible_for_review?, name: 'Jeremy', role: 'advisor', netid: 'somebody')
        end
        context 'when a collaborator is responsible_for_review' do
          let(:is_responsible_for_review?) { false }
          it 'will create a collaborator but not a user nor permission' do
            expect do
              expect do
                expect do
                  test_repository.assign_collaborators_to(work: work, collaborators: collaborator)
                end.to change(Models::Collaborator, :count).by(1)
              end.to_not change(Models::Permission, :count)
            end.to_not change(User, :count)
          end
        end

        context 'when a collaborator is responsible_for_review' do
          let(:is_responsible_for_review?) { true }
          it 'will create a collaborator, user, and permission' do
            expect do
              expect do
                expect do
                  test_repository.assign_collaborators_to(work: work, collaborators: collaborator)
                end.to change(Models::Collaborator, :count).by(1)
              end.to change(Models::Permission, :count).by(1)
            end.to change(User, :count).by(1)
          end
        end
      end

      context '#create_work!' do
        let(:attributes) { { title: 'Hello', work_publication_strategy: 'do_not_know', work_type: 'etd' } }
        it 'will create a work object' do
          expect do
            expect do
              test_repository.create_work!(attributes)
            end.to change { Models::Work.count }.by(1)
          end.to change { Models::Processing::Entity.count }.by(1)
        end
      end

      context '#default_pid_minter' do
        subject { test_repository.default_pid_minter }
        it { should respond_to(:call) }
        its(:call) { should be_a(String) }
      end

      context '#create_sipity_user_from' do
        it 'will create a user from the given netid if one does not exist' do
          expect { test_repository.create_sipity_user_from(netid: 'helloworld') }.
            to change { User.count }.by(1)
        end
        it 'will skip user creation of the netID exists' do
          test_repository.create_sipity_user_from(netid: 'helloworld')

          expect { test_repository.create_sipity_user_from(netid: 'helloworld') }.
            to_not change { User.count }
        end

        it 'will skip user creation if no netid is given' do
          expect { test_repository.create_sipity_user_from(netid: '') }.
            to_not change { User.count }
        end
      end

      context '#update_processing_state!' do
        let(:work) { Models::Work.create! }
        it 'will update the underlying state of the object' do
          expect(Services::UpdateEntityProcessingState).to receive(:call)
          expect { test_repository.update_processing_state!(entity: work, to: 'hello') }.
            to change { work.processing_state }.to('hello')
        end
      end

      context '#attach_file_to' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        it 'will increment the number of attachments in the system' do
          expect { test_repository.attach_file_to(work: work, file: file, user: user, pid_minter: pid_minter) }.
            to change { Models::Attachment.where(pid: 'abc123').count }.by(1)
        end
      end

      context '#remove_files_form' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:file_name) { "hello-world.txt" }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        before { test_repository.attach_file_to(work: work, file: file, user: user, pid_minter: pid_minter) }
        it 'will decrease the number of attachments in the system' do
          expect { test_repository.remove_files_from(pid: pid_minter.call, user: user) }.
            to change { Models::Attachment.count }.from(1).to(0)
        end
      end

      context '#mark_as_representative' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:file_name) { "hello-world.txt" }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        before { test_repository.attach_file_to(work: work, file: file, user: user, pid_minter: pid_minter) }
        it 'will mark the given attachments as representative in the system' do
          expect { test_repository.mark_as_representative(pid: pid_minter.call, user: user) }.
            to change { Models::Attachment.where(mark_as_representative: true).count }.by(1)
        end
        it 'will not mark the given attachments as representative in the system' do
          expect { test_repository.mark_as_representative(pid: 'bogus', user: user) }.
            not_to change { Models::Attachment.where(mark_as_representative: true).count }
        end
      end
    end
  end
end
