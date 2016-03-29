module Sipity
  module Conversions
    module ToRofHash
      # Responsible for converting a work to an ROF hash. This is a bit more
      # complicated as the work's work_type defines the data structure.
      class WorkConverter
        # @api public
        #
        # @param attachment [Sipity::Models::Attachment]
        def self.call(work:, **keywords)
          new(work: work, **keywords).call
        end

        def initialize(work:, repository: default_repository)
          self.work = work
          self.repository = repository
        end

        private

        attr_accessor :work, :repository

        def default_repository
          Sipity::QueryRepository.new
        end

        public

        def call
          {
            'type' => 'fobject',
            'pid' => namespaced_pid(context: work),
            'af-model' => af_model,
            'rights' => access_rights,
            'metadata' => metadata,
            'rels-ext' => rels_ext,
            'properties-meta' => properties_meta,
            'properties' => properties
          }
        end

        private

        def namespaced_pid(context: work)
          "und:#{context.id}"
        end

        def af_model
          # Consider a PowerConverter? What is the rules for this?
          'Etd'
        end

        def access_rights
          AccessRightsBuilder.call(work: work, access_rights_data: work.access_right, repository: repository)
        end

        def metadata
          {
            "@context" => jsonld_context
          }
        end

        def jsonld_context
          {
            "dc" => 'http://purl.org/dc/terms/',
            "rdfs" => 'http://www.w3.org/2000/01/rdf-schema#',
            "ms" => 'http://www.ndltd.org/standards/metadata/etdms/1.1/',
            "ths" => 'http://id.loc.gov/vocabulary/relators/',
            "hydramata-rel" => "http://projecthydra.org/ns/relations#"
          }
        end

        def rels_ext
          {
            "@context" => jsonld_context,
            'hydramata-rel:hasEditor' => [Figaro.env.curate_batch_user_pid!],
            'hydramata-rel:hasEditorGroup' => [Figaro.env.curate_grad_school_editing_group_pid!]
          }
        end

        def properties_meta
          { 'mime-type' => 'text/xml' }
        end

        def properties
          "<fields><depositor>#{AccessRightsBuilder::BATCH_USER}</depositor></fields>"
        end
      end
    end
  end
end
