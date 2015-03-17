require 'spec_helper'

module Sipity
  module Services
    RSpec.describe RemoteNetidValidator do
      subject { described_class }
      context 'valid_netid?' do
        it 'will return false when the request returns a 404 status' do
          expect(subject).to receive(:open).and_raise(OpenURI::HTTPError.new('', ''))
          expect(subject.valid_netid?('a_netid')).to eq(false)
        end

        it 'will return false when the requested NetID is not found for a person'do
          expect(subject).to receive(:open).and_return(StringIO.new(valid_response_but_not_for_a_user))
          expect(subject.valid_netid?('a_netid')).to eq(false)
        end
        it 'will return the NetID when the document contains the NetID' do
          expect(subject).to receive(:open).and_return(StringIO.new(valid_response_with_netid))
          expect(subject.valid_netid?('a_netid')).to eq('a_netid')
        end
        it 'will raise an exception if the returned document is malformed' do
          expect(subject).to receive(:open).and_return(StringIO.new(invalid_document))
          expect { subject.valid_netid?('a_netid') }.to raise_error(NoMethodError)
        end
      end

      let(:valid_response_with_netid) do
        <<-DOCUMENT
        {
          "people":[
            {
              "id":"a_netid","identifier_contexts":{
                "ldap":"uid","staff_directory":"email"
              },"identifier":"by_netid","netid":"a_netid","first_name":"Bob","last_name":"the Builder"
            }
          ]
        }
        DOCUMENT
      end
      let(:valid_response_but_not_for_a_user) do
        <<-DOCUMENT
        {
          "people":[
            {
              "id":"a_netid","identifier_contexts":{
                "ldap":"uid","staff_directory":"email"
              },"identifier":"by_netid","contact_information":{}
            }
          ]
        }
        DOCUMENT
      end

      let(:invalid_document) do
        <<-DOCUMENT
        {
          "people": null
        }
        DOCUMENT
      end
    end
  end
end
