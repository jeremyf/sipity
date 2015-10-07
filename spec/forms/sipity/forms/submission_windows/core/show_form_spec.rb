require 'spec_helper'
require 'sipity/forms/submission_windows/core/show_form'
require 'sipity/forms/submission_windows/core/show_form'

module Sipity
  module Forms
    module SubmissionWindows
      module Core
        RSpec.describe ShowForm do
          let(:processing_action_name) { 'show' }
          let(:submission_window) { double }
          subject { described_class.new(submission_window: submission_window, processing_action_name: processing_action_name) }

          its(:policy_enforcer) { should eq Sipity::Policies::SubmissionWindowPolicy }
          its(:processing_action_name) { should eq processing_action_name }

          it { should be_a(Models::SubmissionWindow) }
        end
      end
    end
  end
end
