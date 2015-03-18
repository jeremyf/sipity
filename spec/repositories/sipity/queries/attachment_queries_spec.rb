require 'spec_helper'

module Sipity
  module Queries
    RSpec.describe AttachmentQueries, type: :isolated_repository_module do
      let(:work) { Models::Work.new(id: '123') }
      let(:work_two) { Models::Work.new(id: '456') }
      let(:file) { FileUpload.fixture_file_upload('attachments/hello-world.txt') }
      subject { test_repository }

      context '#find_or_initialize_attachments' do
        subject { test_repository.find_or_initialize_attachments_by(work: work, pid: '12') }
        it 'will initialize a attachment based on the work id' do
          expect(subject.work_id).to eq(work.id.to_s)
        end
      end

      context '#work_attachments' do
        it 'returns the attachments for the given work and role' do
          Models::Attachment.create!(work_id: work.id, pid: 'attach1', predicate_name: 'attachment', file: file)
          expect(subject.work_attachments(work: work).count).to eq(1)
        end
      end

      context '#accessible_objects' do
        it 'returns the attachments for the given work and role' do
          attachment = Models::Attachment.create!(work_id: work.id, pid: 'attach1', predicate_name: 'attachment', file: file)
          expect(subject.accessible_objects(work: work)).to eq([work, attachment])
        end
      end

      context '#representative_attachment_for' do
        it 'returns attachment marked as representative for work' do
          attachment = Models::Attachment.create!(
            work_id: work.id, pid: 'attach1', predicate_name: 'attachment',
            file: file, is_representative_file: true
          )
          expect(subject.representative_attachment_for(work: work)).to eq(attachment)
        end
      end

      context '#access_rights_for_accessible_objects' do
        let(:attachment) { Models::Attachment.new(id: 'abc') }
        it 'returns an enumerable of AccessRight objects' do
          allow(test_repository).to receive(:accessible_objects).and_return([work, attachment])
          access_rights = test_repository.access_rights_for_accessible_objects_of(work: work)
          expect(access_rights.size).to eq(2)
          expect(access_rights[0]).to be_a(Models::AccessRightFacade)
          expect(access_rights[1]).to be_a(Models::AccessRightFacade)
        end
      end
    end
  end
end
