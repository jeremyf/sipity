require 'spec_helper'
require 'sipity/data_generators/work_type_generator'

module Sipity
  RSpec.describe DataGenerators::WorkTypeGenerator do
    let(:submission_window) { Models::SubmissionWindow.new(id: 2, slug: 'start', work_area_id: 1) }
    let(:data) { JSON.parse(json) }
    let(:json) do
      doc = <<-HERE
      {
        "work_types": [
          {
            "name": "ulra_submission",
            "strategy_permissions": [{
              "group": "ULRA Review Committee",
              "role": "ulra_reviewer"
            }],
            "actions": [{
              "name": "start_a_submission",
              "transition_to": "new",
              "emails": [{
                "name": "confirmation_of_ulra_submission_started",
                "to": "creating_user"
              },{
                "name": "faculty_assigned_for_ulra_submission",
                "to": "advisor"
              }]
            },{
              "name": "start"
            }],
            "action_analogues": [{
              "action": "start_a_submission", "analogous_to": "start"
            }],
            "state_emails": [{
              "state": "new",
              "reason": "processing_hook_triggered",
              "emails": [{
                "name": "student_has_indicated_attachments_are_complete",
                "to": "ulra_reviewer"
              }]
            }]
          }
        ]
      }
      HERE
      doc.strip
    end
    let(:validator) { double(call: true) }
    let(:keywords) { { submission_window: submission_window, data: data, validator: validator } }

    subject { described_class.new(**keywords) }

    its(:default_validator) { should respond_to(:call) }
    its(:default_schema) { should respond_to(:call) }

    it 'exposes .call as a convenience method' do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.call(**keywords)
    end

    it 'validates the data against the schema' do
      subject
      expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema))
    end

    context '.generate_from_json_file' do
      # Should I be testing a production file?
      let(:path) { Rails.root.join('app/data_generators/sipity/data_generators/work_types/ulra_work_types.json').to_s }
      let(:keywords) { { submission_window: submission_window, path: path } }

      it 'will load the file and parse as JSON' do
        expect_any_instance_of(described_class).to receive(:call)
        described_class.generate_from_json_file(**keywords)
      end
    end

    context 'data generation' do
      let(:keywords) { { submission_window: submission_window, data: data } }
      it 'creates the requisite data' do
        expect(DataGenerators::StateMachineGenerator).to receive(:generate_from_schema).and_call_original.exactly(2).times
        expect(DataGenerators::EmailNotificationGenerator).to receive(:call).and_call_original.exactly(3).times
        expect do
          expect do
            expect do
              expect do
                expect do
                  expect do
                    subject.call
                  end.to change { Models::Processing::StrategyActionAnalogue.count }.by(1)
                end.to change { Models::Processing::Strategy.count }.by(1)
              end.to change { Models::Processing::StrategyUsage.count }.by(1)
            end.to change { Models::WorkType.count }.by(1)
          end.to change { Models::SubmissionWindowWorkType.count }.by(1)
        end.to change { Models::Group.count }.by(1)
      end
    end
  end
end