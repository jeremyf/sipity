require 'rails_helper'

RSpec.describe 'sip/headers/new.html.erb', type: :view do
  let(:model) { Sip::Decorators::HeaderDecorator.decorate(Sip::Forms::CreateHeaderForm.new) }

  it 'renders the object and fieldsets' do
    # I want to pass the model to the view; Not using an instance variable
    render template: 'sip/headers/new', locals: { model: model }
    expect(rendered).to have_tag('form.new_sip_header[action="/sip/headers"][method="post"]') do
      with_tag('fieldset.attributes_sip_header') do
        with_tag('input', with: { name: 'sip_header[title]' })
        model.possible_work_publication_strategies.each do |name, _index|
          with_tag('input', with: { name: 'sip_header[work_publication_strategy]', value: name })
        end
      end
      with_tag('fieldset.collaborators_sip_header') do
        with_tag('input', with: { name: 'sip_header[collaborators_attributes][0][name]' })
        with_tag('select', with: { name: 'sip_header[collaborators_attributes][0][role]' })
      end
      with_tag('fieldset.attributes_sip_header') do
        with_tag('input', with: { type: 'submit' })
      end
    end
  end
end
