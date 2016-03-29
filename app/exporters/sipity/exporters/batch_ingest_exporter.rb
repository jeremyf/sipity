require 'sipity/exporters/batch_ingest_exporter/metadata_builder'

module Sipity
  module Exporters
    # Responsible for coordinating sending a work through the batch ingest.
    class BatchIngestExporter
      DATA_PATH = Figaro.env.curate_batch_data_mount_path!

      def self.call(work:)
        new(work: work).call
      end

      def initialize(work:)
        @work = work
      end

      attr_accessor :work

      def call
        AttachmentWriter.call(exporter: self)
        work_metadata = MetadataBuilder.call(exporter: self)
        MetadataWriter.call(metadata: work_metadata, exporter: self)
        WebhookWriter.call(exporter: self)
        DirectoryMover.call(exporter: self)
      end

      def data_directory
        @data_directory ||= File.join(DATA_PATH, "/sipity-#{work.id}")
      end

      def make_data_directory
        FileUtils.mkdir_p(data_directory)
      end

      def work_id
        work.to_param
      end

      class AttachmentWriter
      end

      class MetadataWriter
      end

      # Adds a list of URLs to the WEBHOOK file that are called during the bacth
      # ingest process.
      module WebhookWriter
        module_function

        def call(exporter:)
          exporter.make_data_directory
          write_contents(
            target: output_buffer(filename: target_path(exporter: exporter)),
            content: callback_url(exporter: exporter)
          )
        end

        def write_contents(target:, content:)
          target.write(content)
          target.close_write
        end

        def output_buffer(filename:)
          file_descriptor = IO.sysopen(filename, 'w+')
          IO.new(file_descriptor)
        end

        def target_path(exporter:)
          File.join(exporter.data_directory, 'WEBHOOK')
        end

        def callback_url(exporter:)
          File.join(
            "#{Figaro.env.protocol!}://#{authorization_credentials}@#{Figaro.env.domain_name!}",
            "/work_submissions/#{exporter.work_id}/callback/ingest_completed.json"
          )
        end

        def authorization_credentials
          "#{Sipity::Models::Group::BATCH_INGESTORS}:#{Figaro.env.sipity_batch_ingester_access_key!}"
        end
      end

      class DirectoryMover
      end
    end
  end
end