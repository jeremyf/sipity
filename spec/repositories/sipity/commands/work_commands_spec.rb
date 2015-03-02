require 'rails_helper'

module Sipity
  module Commands
    RSpec.describe WorkCommands, type: :command_with_related_query do
      before do
        # TODO: Remove this once the deprecation for granting permission is done
        allow(Services::GrantProcessingPermission).to receive(:call)
      end

      context '#destroy_a_work' do
        let(:work) { Models::Work.new }
        it 'will destroy the work in question' do
          work.save! # so it is persisted
          expect { test_repository.destroy_a_work(work: work) }.
            to change { Models::Work.count }.by(-1)
          expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
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
                test_repository.assign_collaborators_to(work: work, collaborators: collaborator)
              end.to change(Models::Collaborator, :count).by(1)
            end.to_not change(User, :count)
          end
        end

        context 'when a collaborator is responsible_for_review' do
          let(:is_responsible_for_review?) { true }
          it 'will create a collaborator, user, and permission' do
            expect do
              expect do
                test_repository.assign_collaborators_to(work: work, collaborators: collaborator)
              end.to change(Models::Collaborator, :count).by(1)
            end.to change(User, :count).by(1)
          end
        end
      end

      context '#create_work!' do
        let(:attributes) { { title: 'Hello', work_publication_strategy: 'do_not_know', work_type: 'doctoral_dissertation' } }
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
        it 'will update update the entity processing state' do
          expect(Services::UpdateEntityProcessingState).to receive(:call)
          test_repository.update_processing_state!(entity: work, to: 'hello')
        end
      end

      context '#attach_files_to' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        it 'will increment the number of attachments in the system' do
          expect { test_repository.attach_files_to(work: work, files: file, user: user, pid_minter: pid_minter) }.
            to change { Models::Attachment.where(pid: 'abc123').count }.by(1)
        end
      end

      context '#remove_files_form' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:file_name) { "hello-world.txt" }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        before { test_repository.attach_files_to(work: work, files: file, user: user, pid_minter: pid_minter) }
        it 'will decrease the number of attachments in the system' do
          expect { test_repository.remove_files_from(pids: pid_minter.call, work: work, user: user) }.
            to change { Models::Attachment.count }.by(-1)
        end
      end

      context '#mark_as_representative' do
        let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
        let(:file_name) { "hello-world.txt" }
        let(:user) { User.new(id: 1234) }
        let(:work) { Models::Work.create! }
        let(:pid_minter) { -> { 'abc123' } }
        before { test_repository.attach_files_to(work: work, files: file, user: user, pid_minter: pid_minter) }
        it 'will mark the given attachments as representative in the system' do
          expect { test_repository.mark_as_representative(work: work, pid: pid_minter.call, user: user) }.
            to change { Models::Attachment.where(is_representative_file: true).count }.by(1)
        end
        it 'will not mark the given attachments as representative in the system' do
          expect { test_repository.mark_as_representative(work: work, pid: 'bogus', user: user) }.
            not_to change { Models::Attachment.where(is_representative_file: true).count }
        end
      end
    end
  end
end
