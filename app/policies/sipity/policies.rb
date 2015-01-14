# Because of the above `const_defined?` I'm requiring the various sipity
# policies
Dir[File.expand_path('../policies/*.rb', __FILE__)].each do |filename|
  require_relative "./policies/#{File.basename(filename)}"
end
module Sipity
  # Contains the various Policies associated with Sipity.
  #
  # A Policy is an object responsible for answering questions about actions
  # the given user is attempting to take on a given object.
  #
  # The Policy subsystem is responsible for three major concerns:
  #
  # * Given a user, entity, and policy question; Can the user do it? This is
  #   answered via a Policy object.
  # * Given a user and a policy question, what are all of the entities that
  #   can be acted upon? This is answered via a Policy::Scope object.
  # * Given a user and an entity, what are all of the actions the user can take
  #   on the entity? This is answered via a permitted_actions query.
  #   NOTE: This is a concept that is not part of the Pundit ecosystem. It is
  #   also a theoretical exercise.
  #
  # @see [Elabs' Pundit gem](http://github.com/elabs/pundit) for
  #   further explanation of Policy and Scope objects.
  module Policies
    def authorized_for?(user:, action_to_authorize:, entity:)
      policy_enforcer = find_policy_enforcer_for(entity: entity)
      policy_enforcer.call(user: user, entity: entity, action_to_authorize: action_to_authorize)
    end
    module_function :authorized_for?

    def find_policy_enforcer_for(entity:)
      return entity.policy_enforcer if entity.respond_to?(:policy_enforcer) && entity.policy_enforcer.present?
      policy_name_as_constant = "#{entity.class.to_s.demodulize}Policy"
      if const_defined?(policy_name_as_constant)
        const_get(policy_name_as_constant)
      else
        fail Exceptions::PolicyNotFoundError, name: policy_name_as_constant, container: self
      end
    end
    module_function :find_policy_enforcer_for
  end
end
