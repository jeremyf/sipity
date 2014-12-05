require 'sipity/models'
module Sipity
  module Models
    # Sits between a user and a subject defining the role for access.
    class Permission < ActiveRecord::Base
      self.table_name = 'sipity_permissions'
      belongs_to :user
      belongs_to :subject, polymorphic: true
    end
  end
end
