require 'spec_helper'

module Sip
  RSpec.describe HeaderDoi do
    let(:header) { double('Header') }
    let(:decorator) { double(decorate: header) }

    subject { HeaderDoi.new(decorator: decorator, header: header) }

    it 'is not persisted' do
      expect(subject.persisted?).to eq(false)
    end

    it 'has a nil to_param' do
      expect(subject.to_param).to be_nil
    end

    it 'has an empty to_key' do
      expect(subject.to_key).to eq([])
    end

    it 'requires an identifer' do
      subject.valid?
      expect(subject.errors[:identifier]).to_not be_empty
    end

    it 'formats an identifier'

    it 'decorates the header' do
      subject
      expect(decorator).to have_received(:decorate).with(header)
    end

    context '#submit' do
      context 'when not valid' do
        it 'will return false' do
          expect(subject.submit).to be_falsey
        end
        it 'will not append data to the header'
      end

      context 'when valid' do
        let(:identifier) { 'doi:1234' }
        subject { HeaderDoi.new(decorator: decorator, header: header, identifier: identifier) }
        it 'will return true' do
          expect(subject.submit).to be_truthy
        end
        it 'will append the DOI to the header'
      end
    end
  end
end
