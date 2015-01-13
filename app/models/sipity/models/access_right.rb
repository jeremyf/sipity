module Sipity
  module Models
    # Responsible for defining a range of time in which the access right is
    # in effect for a given entity.
    #
    # For the date range both the  enforcement start date and end date is
    # inclusive. That is to say Jan 1, 2015 to Feb 1, 2015 will be
    # all of January 2015 and the first day of February 2015.
    #
    # It is envisioned that the AccessRights will be contiguous non-overlapping
    # date ranges.
    class AccessRight < ActiveRecord::Base
      # @attr_accessor [Date] enforcement_start_date the first day in which the
      #   given access_right enforcement is in effect
      # @attr_accessor [Date] enforcement_end_date the last day in which the
      #   given access_right enforcement is in effect
      self.table_name = 'sipity_access_rights'

      OPEN_ACCESS = 'open_access'.freeze
      RESTRICTED_ACSESS = 'restricted_access'.freeze
      PRIVATE_ACCESS = 'private_access'.freeze

      enum(
        acccess_right_code: {
          OPEN_ACCESS => OPEN_ACCESS,
          RESTRICTED_ACSESS => RESTRICTED_ACSESS,
          PRIVATE_ACCESS => PRIVATE_ACCESS
        }
      )
    end
  end
end
