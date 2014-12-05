require 'spec_helper'
require 'sip/runners/citation_runners'

module Sipity
  module Runners
    module CitationRunners
      RSpec.describe Show do
        let(:header) { double }
        let(:header_id) { 1234 }
        let(:context) { double(repository: repository) }
        let(:repository) { double(find_header: header, citation_already_assigned?: citation_already_assigned) }
        let(:citation_already_assigned) { true }
        let(:handler) { double(invoked: true) }
        subject do
          described_class.new(context, requires_authentication: false) do |on|
            on.citation_not_assigned { |header| handler.invoked("CITATION_NOT_ASSIGNED", header) }
            on.citation_assigned { |header| handler.invoked("CITATION_ASSIGNED", header) }
          end
        end

        it 'requires authentication' do
          expect(context).to receive(:authenticate_user!).and_return(true)
          described_class.new(context)
        end

        context 'when a citation is not assigned' do
          let(:citation_already_assigned) { false }
          it 'issues the :citation_not_assigned callback' do
            response = subject.run(header_id: header_id)
            expect(handler).to have_received(:invoked).with("CITATION_NOT_ASSIGNED", header)
            expect(response).to eq([:citation_not_assigned, header])
          end
        end

        context 'when a citation is already assigned' do
          let(:citation_already_assigned) { true }
          it 'issues the :citation_assigned callback' do
            response = subject.run(header_id: header_id)
            expect(handler).to have_received(:invoked).with("CITATION_ASSIGNED", header)
            expect(response).to eq([:citation_assigned, header])
          end
        end
      end

      RSpec.describe New do
        let(:header) { double('Header') }
        let(:header_id) { 1234 }
        let(:context) { double('Context', repository: repository) }
        let(:form) { double('Form') }
        let(:citation_assigned) { nil }
        let(:repository) do
          double('Repository',
                 find_header: header, build_assign_a_citation_form: form, citation_already_assigned?: citation_assigned
                 )
        end
        let(:handler) { double('Handler', invoked: true) }
        subject do
          described_class.new(context, requires_authentication: false) do |on|
            on.citation_not_assigned { |header| handler.invoked("CITATION_NOT_ASSIGNED", header) }
            on.citation_assigned { |header| handler.invoked("CITATION_ASSIGNED", header) }
          end
        end

        it 'requires authentication' do
          expect(context).to receive(:authenticate_user!).and_return(true)
          described_class.new(context)
        end

        context 'when a citation is not assigned' do
          let(:citation_assigned) { false }
          it 'issues the :citation_not_assigned callback with the form' do
            response = subject.run(header_id: header_id)
            expect(handler).to have_received(:invoked).with("CITATION_NOT_ASSIGNED", form)
            expect(response).to eq([:citation_not_assigned, form])
          end
        end

        context 'when a citation is already assigned' do
          let(:citation_assigned) { true }
          it 'issues the :citation_assigned callback with the header' do
            response = subject.run(header_id: header_id)
            expect(handler).to have_received(:invoked).with("CITATION_ASSIGNED", header)
            expect(response).to eq([:citation_assigned, header])
          end
        end
      end

      RSpec.describe Create do
        let(:header) { double }
        let(:header_id) { 1234 }
        let(:attributes) { { key: 'abc:123' } }
        let(:context) { double('Context', repository: repository) }
        let(:form) { double('Form') }
        let(:repository) do
          double('Repository', find_header: header, build_assign_a_citation_form: form, submit_assign_a_citation_form: true)
        end
        let(:handler) { double('Handler', invoked: true) }
        subject do
          described_class.new(context, requires_authentication: false) do |on|
            on.success { |a| handler.invoked("SUCCESS", a) }
            on.failure { |a| handler.invoked("FAILURE", a) }
          end
        end

        it 'requires authentication' do
          expect(context).to receive(:authenticate_user!).and_return(true)
          described_class.new(context)
        end

        context 'when the form submission fails' do
          it 'issues the :failure callback' do
            expect(repository).to receive(:submit_assign_a_citation_form).with(form).and_return(false)
            response = subject.run(header_id: header_id, attributes: attributes)
            expect(handler).to have_received(:invoked).with("FAILURE", form)
            expect(response).to eq([:failure, form])
          end
        end

        context 'when the form submission succeeds' do
          it 'issues the :success callback' do
            expect(repository).to receive(:submit_assign_a_citation_form).with(form).and_return(true)
            response = subject.run(header_id: header_id, attributes: attributes)
            expect(handler).to have_received(:invoked).with("SUCCESS", header)
            expect(response).to eq([:success, header])
          end
        end
      end
    end
  end
end
