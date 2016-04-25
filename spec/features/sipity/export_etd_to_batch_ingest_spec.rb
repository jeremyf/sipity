require 'rails_helper'

feature 'Export ETD to Batch Ingest' do
  before do
    path = Rails.root.join('app/data_generators/sipity/data_generators/work_areas/etd_work_area.config.json')
    Sipity::DataGenerators::WorkAreaGenerator.call(path: path)
    group = Sipity::Models::Group.find_or_create_by!(name: Sipity::Models::Group::BATCH_INGESTORS)
    group.update!(api_key: '1234')
  end
  let(:user) { Sipity::Factories.create_user }
  let(:submission_window) { Sipity::Models::SubmissionWindow.find_by!(slug: 'start') }
  let(:repository) { Sipity::CommandRepository.new }

  # REVIEW: This draws attention to the fact that composition of objects is a little jagged.
  it 'will export an ROF file with JSON metadata, a webhook, and any attachments to the mount path' do
    work = repository.create_work!(
      submission_window: submission_window, title: 'My Work', work_type: Sipity::Models::WorkType::MASTER_THESIS
    )

    repository.grant_creating_user_permission_for!(entity: work, user: user)
    repository.attach_files_to(work: work, files: File.new(__FILE__))
    attachment = work.attachments.first
    Sipity::Jobs::Core::PerformActionForWorkJob.call(
      work_id: work.id, requested_by: user, processing_action_name: 'describe', attributes: { abstract: 'My Abstract' }
    )
    Sipity::Jobs::Core::PerformActionForWorkJob.call(
      work_id: work.id, requested_by: user, processing_action_name: 'access_policy', attributes: {
        accessible_objects_attributes: {
          "0" => { id: work.to_param, access_right_code: 'open_access', release_date: "" },
          "1" => { id: attachment.to_param, access_right_code: 'open_access', release_date: "" }
        },
        representative_attachment_id: attachment.to_param
      }
    )

    # Because translations were firing
    allow(I18n).to receive(:t).with("#{work.work_type}.label", scope: 'work_types', raise: true).and_return("Master's Thesis")

    exporter = Sipity::Exporters::BatchIngestExporter.new(work: work)
    exporter.call

    queue_path = exporter.queue_pathname

    webhook_pathname = queue_path.join('WEBHOOK')
    rof_pathname = queue_path.join("metadata-#{work.id}.rof")

    expect(webhook_pathname.exist?).to eq(true)
    expect(rof_pathname.exist?).to eq(true)
    expect(JSON.parse(rof_pathname.read).first.fetch('af-model')).to eq('Etd')
  end
end
