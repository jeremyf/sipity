require 'spec_helper'

module Sipity
  module Forms
    RSpec.describe ProcessingForm do
      let(:entity) { double }
      let(:form) do
        double(
          entity: entity, base_class: Models::Work, valid?: true, class: double(name: 'StartForm'), errors: true,
          model_name: true, param_key: true, processing_action_name: true, translate: true,
          to_processing_entity: true, to_processing_action: true, to_work_area: true, template: true
        )
      end
      let(:repository) { CommandRepositoryInterface.new }
      let(:translator) { double(call: true) }
      let(:user) { double }
      subject { described_class.new(form: form, repository: repository, translator: translator) }

      context '.configure' do
        let(:form_class) do
          Class.new do
            def self.name
              'HelloWorld'
            end

            def base_class
              Class
            end
            include ActiveModel::Validations
          end
        end
        subject { form_class.new.tap { |obj| obj.send(:processing_action_form=, described_class.new(form: obj, repository: double)) } }
        before { described_class.configure(form_class: form_class, base_class: Models::Work, attribute_names: [:title, :job]) }
        it { should respond_to :work }
        it { should respond_to :entity }
        it { should respond_to :title }
        it { should respond_to :job }
        its(:processing_subject_name) { should eq('work') }
        its(:attribute_names) { should eq([:title, :job]) }
        its(:base_class) { should eq(Models::Work) }
        its(:policy_enforcer) { should eq(Policies::WorkPolicy) }
        its(:template) { should eq('hello_world') }
        it { should_not be_persisted }
        it { should delegate_method(:param_key).to(:model_name) }
        it { should delegate_method(:to_processing_entity).to(:processing_action_form) }
        it { should delegate_method(:to_processing_action).to(:processing_action_form) }
        it { should delegate_method(:to_work_area).to(:processing_action_form) }
        it { should delegate_method(:processing_action_name).to(:processing_action_form) }
        it 'will delegate repository to processing_action_form' do
          expect(subject.send(:repository)).to eq(subject.send(:processing_action_form).send(:repository))
        end
      end

      it { should delegate_method(:valid?).to(:form) }

      its(:default_repository) { should respond_to :register_action_taken_on_entity }
      its(:default_translator) { should respond_to :call }

      context '#translate' do
        it 'should delegate translation to the translator' do
          subject.translate('name', scope: 'panel_headings')
          expect(translator).to have_received(:call).with(scope: 'panel_headings', object: 'name', predicate: :label, subject: entity)
        end
        it 'will default the identifier to the processing_action_name' do
          subject.translate('name')
          expect(translator).to have_received(:call).
            with(scope: "processing_actions.#{subject.processing_action_name}", object: 'name', predicate: :label, subject: entity)
        end
      end

      it 'should convert the underlying entity to a processing entity' do
        expect(Conversions::ConvertToProcessingEntity).to receive(:call).with(entity).and_return(:converted)
        expect(subject.to_processing_entity).to eq(:converted)
      end

      it 'should convert the underlying entity to a work area' do
        expect(PowerConverter).to receive(:convert_to_work_area).with(entity).and_return(:converted)
        expect(subject.to_work_area).to eq(:converted)
      end

      it 'should convert the underlying processing action name to a processing_action' do
        expect(Conversions::ConvertToProcessingAction).to receive(:call).
          with(subject.processing_action_name, scope: entity).and_return(:converted)
        expect(subject.to_processing_action).to eq(:converted)
      end

      context '#submit' do
        context 'when invalid' do
          before { allow(form).to receive(:valid?).and_return(false) }
          it 'will return false' do
            expect(subject.submit(requested_by: user)).to be_falsey
          end
          it 'will not yield control' do
            expect { |b| subject.submit(requested_by: user, &b) }.to_not yield_control
          end
        end

        context 'when valid' do
          let(:an_action) { double(resulting_strategy_state: double) }
          before do
            allow(subject).to receive(:to_processing_action).and_return(an_action)
            allow(form).to receive(:valid?).and_return(true)
          end

          it 'will return the underlying entity' do
            expect(subject.submit(requested_by: user)).to eq(entity)
          end

          it 'will yield with the repository' do
            expect { |b| subject.submit(requested_by: user, &b) }.to yield_with_no_args
          end

          it 'will register the action that was taken' do
            expect(repository).to receive(:register_action_taken_on_entity).and_call_original
            subject.submit(requested_by: user)
          end

          it 'will register the action that was taken' do
            expect(repository).to receive(:update_processing_state!).
              with(entity: entity, to: an_action.resulting_strategy_state).and_call_original
            subject.submit(requested_by: user)
          end
        end
      end
    end
  end
end
