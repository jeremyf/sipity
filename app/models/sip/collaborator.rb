module Sip
  # A collaborator (as per metadata not improving on the SIP) for the underlying
  # work's SIP.
  class Collaborator < ActiveRecord::Base
    DEFAULT_ROLE = 'author'.freeze

    def self.build_default
      new(role: DEFAULT_ROLE)
    end

    self.table_name = 'sip_collaborators'

    validates :name, presence: true
    validates :role, inclusion: { in: ->(obj) { obj.class.roles } }

    # While this make look ridiculous, if I use an Array, the enum declaration
    # insists on persisting the value as the index instead of the key. While
    # this might make more sense from a storage standpoint, it is not as clear
    # and leverages a more opaque assumption.
    enum(
      role:
      {
        'advisor' => 'advisor',
        'author' => 'author',
        'contributor' => 'contributor'
      }
    )
  end
end
