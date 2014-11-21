require 'spec_helper'

module Sip
  describe DoiRunners::Show do
    let(:header) { double }
    let(:header_id) { 1234 }
    let(:context) { double(repository: repository) }
    let(:repository) { double(find_header: header, doi_already_assigned?: false, doi_request_is_pending?: false) }
    let(:handler) { double(invoked: true) }
    subject do
      DoiRunners::Show.new(context) do |on|
        on.doi_already_assigned { |header| handler.invoked("DOI_ALREADY_ASSIGNED", header) }
        on.doi_not_assigned { |header| handler.invoked("DOI_NOT_ASSIGNED", header) }
        on.doi_request_is_pending { |header| handler.invoked("DOI_REQUEST_IS_PENDING", header) }
      end
    end

    context 'when a DOI is assigned' do
      it 'issues the :doi_already_assigned callback' do
        expect(repository).to receive(:doi_already_assigned?).and_return true
        response = subject.run(header_id: header_id)
        expect(handler).to have_received(:invoked).with("DOI_ALREADY_ASSIGNED", header)
        expect(response).to eq([header])
      end
    end

    context 'when a DOI is not assigned' do
      it 'issues the :doi_not_assigned callback' do
        response = subject.run(header_id: header_id)
        expect(handler).to have_received(:invoked).with("DOI_NOT_ASSIGNED", header)
        expect(response).to eq([header])
      end
    end

    context 'when a DOI request has been made but not yet completed' do
      it 'issues the :pending_doi_assignment callback' do
        expect(repository).to receive(:doi_request_is_pending?).and_return(true)
        response = subject.run(header_id: header_id)
        expect(handler).to have_received(:invoked).with("DOI_REQUEST_IS_PENDING", header)
        expect(response).to eq([header])
      end
    end
  end
end
