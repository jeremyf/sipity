require 'rails_helper'

module Sip
  RSpec.describe Repository, type: :repository do
    subject { Repository.new }
    context '#find_header' do
      it 'raises an exception if nothing is found' do
        expect { subject.find_header('8675309') }.to raise_error
      end

      it 'returns the Header when the object is found' do
        allow(Header).to receive(:find).with('8675309').and_return(:found)
        expect(subject.find_header('8675309')).to eq(:found)
      end

      let(:decorator) { double(decorate: :decorated) }
      it 'will build a decorated header if decoration is requested' do
        allow(Header).to receive(:find).with('8675309').and_return(:found)
        expect(subject.find_header('8675309', decorator: decorator)).to eq(:decorated)
        expect(decorator).to have_received(:decorate).with(:found)
      end
    end

    context '#submit_assign_a_doi_form' do
      let(:header) { FactoryGirl.build_stubbed(:sip_header, id: '1234') }
      let(:attributes) { { header: header, identifier: identifier } }
      let(:form) { Repository.new.build_assign_a_doi_form(attributes) }

      context 'on invalid data' do
        let(:identifier) { '' }
        it 'returns false and does not assign a DOI' do
          expect(subject.submit_assign_a_doi_form(form)).to eq(false)
        end
      end
      context 'on valid data' do
        let(:identifier) { 'doi:abc' }
        it 'will assign the DOI to the header' do
          expect { subject.submit_assign_a_doi_form(form) }.
            to change { subject.doi_already_assigned?(header) }.
            from(false).to(true)
        end
      end
    end

    context '#submit_assign_a_citation_form' do
      let(:header) { FactoryGirl.build_stubbed(:sip_header, id: '1234') }
      let(:attributes) { { header: header, citation: citation, type: '1234' } }
      let(:form) { Repository.new.build_assign_a_citation_form(attributes) }

      context 'on invalid data' do
        let(:citation) { '' }
        it 'returns false and does not assign a Citation' do
          expect(subject.submit_assign_a_citation_form(form)).to eq(false)
        end
      end

      context 'on valid data' do
        let(:citation) { 'citation:abc' }
        it 'will assign the Citation to the header' do
          expect { subject.submit_assign_a_citation_form(form) }.to(
            change { subject.citation_already_assigned?(header) }.from(false).to(true) &&
            change { header.additional_attributes.count }.by(2)
          )
        end
      end
    end

    context '#submit_request_a_doi_form' do
      let(:header) { FactoryGirl.build_stubbed(:sip_header, id: '1234') }
      let(:attributes) do
        { header: header, publisher: publisher, publication_date: '2014-10-11', authors: ['Frog', 'Toad'] }
      end
      let(:form) { Repository.new.build_request_a_doi_form(attributes) }

      context 'on invalid data' do
        let(:publisher) { '' }
        it 'returns false and does not create the DOI request' do
          expect(subject.submit_request_a_doi_form(form)).to eq(false)
        end
      end

      context 'on valid data' do
        let(:publisher) { 'Valid Publisher' }
        it 'returns true, creating the DOI creation request and appending the captured attributes' do
          expect { subject.submit_request_a_doi_form(form) }.to(
            change { subject.doi_request_is_pending?(header) }.from(false).to(true) &&
            change { header.additional_attributes.count }.by(2)
          )
        end
      end
    end

    context '#submit_create_header_form' do
      let(:header) do
        subject.build_create_header_form(
          attributes: {
            title: 'This is my title',
            work_publication_strategy: 'do_not_know',
            publication_date: '2014-11-12',
            collaborators_attributes: {
              "0" => { name: "The person", role: Collaborator::DEFAULT_ROLE }
            }
          }
        )
      end
      it 'will append the publication_date if one is given' do
        expect { subject.submit_create_header_form(header) }.to(
          change { Header.count }.by(1) &&
          change { header.additional_attributes.count }.by(1) &&
          change { Collaborator.count }.by(1)
        )
      end
    end

    context '#build_assign_a_doi_form object' do
      let(:header) { double }
      subject { Repository.new.build_assign_a_doi_form(header: header) }
      it { should respond_to :header }
      it { should respond_to :identifier }
      it { should respond_to :identifier_key }
      it { should respond_to :submit }
    end

    context '#build_assign_a_citation_form object' do
      let(:header) { double }
      subject { Repository.new.build_assign_a_citation_form(header: header) }
      it { should respond_to :header }
      it { should respond_to :citation }
      it { should respond_to :type }
      it { should respond_to :submit }
    end

    context '#build_request_a_doi_form object' do
      let(:header) { double }
      subject { Repository.new.build_request_a_doi_form(header: header) }
      it { should respond_to :title }
      it { should respond_to :authors }
      it { should respond_to :publication_date }
      it { should respond_to :publisher }
      it { should respond_to :submit }
    end

    context '#build_create_header_form' do
      let(:decorator) { double(decorate: :decorated) }
      it 'will build a header without decoration' do
        expect(subject.build_create_header_form).to be_a(CreateHeaderForm)
      end
      it 'will build a decorated header if decoration is requested' do
        expect(subject.build_create_header_form(decorator: decorator)).to eq(:decorated)
        expect(decorator).to have_received(:decorate).with(kind_of(CreateHeaderForm))
      end
    end

    it { should respond_to :doi_request_is_pending? }
    it { should respond_to :doi_already_assigned? }
    it { should respond_to :citation_already_assigned? }
  end
end
