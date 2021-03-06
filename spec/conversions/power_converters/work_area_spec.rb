require 'rails_helper'

RSpec.describe 'PowerConverter' do
  context 'work_area' do
    it "will convert based on the given scenarios" do

      # Putting these all in one scenario as there is a database hit that occurs
      # It breaks the "convention" of one assertion per spec, but speed is nice.

      work_area = Sipity::Models::WorkArea.create!(
        name: 'The Name', slug: 'the-slug', partial_suffix: 'the-partial-suffix', demodulized_class_prefix_name: 'TheName'
      )
      [
        { to_convert: 'The Name', expected_name: 'The Name' },
        { to_convert: 'the-slug', expected_name: 'The Name' }
      ].each do |scenario|
        to_convert = scenario.fetch(:to_convert)
        expect(PowerConverter.convert(to_convert, to: :work_area).name).to eq(scenario.fetch(:expected_name))
      end

      expect(PowerConverter.convert(work_area, to: :work_area)).to eq(work_area)
      submission_window = Sipity::Models::SubmissionWindow.new(work_area: work_area)
      expect(PowerConverter.convert(submission_window, to: :work_area)).to eq(work_area)
      work = Sipity::Models::Work.new
      allow(work).to receive(:work_area).and_return(work_area)
      expect(PowerConverter.convert(work, to: :work_area)).to eq(work_area)
      entity = Sipity::Models::Processing::Entity.new(proxy_for: work)
      expect(PowerConverter.convert(entity, to: :work_area)).to eq(work_area)

      [
        'The Missing Name'
      ].each do |to_convert_but_will_fail|
        expect { PowerConverter.convert(to_convert_but_will_fail, to: :work_area) }.to raise_error(PowerConverter::ConversionError)
      end
    end
  end
end
