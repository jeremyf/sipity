require 'spec_helper'
require 'hesburgh/lib/mock_runner'

module Sipity
  module Controllers
    RSpec.describe DashboardsController, type: :controller do
      context 'GET #index' do
        before { controller.runner = runner }
        let(:runner) do
          Hesburgh::Lib::MockRunner.new(
            yields: view_object, callback_name: callback_name, run_with: { processing_state: 'hello', page: nil }, context: controller
          )
        end
        let(:view_object) { double }
        let(:callback_name) { :success }
        it 'will render the new page' do
          get 'index', processing_state: 'hello'
          expect(assigns(:view)).to_not be_nil
          expect(response).to render_template('index')
        end
      end
    end
  end
end
