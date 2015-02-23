require 'spec_helper'

# Welcome intrepid developer. You have stumbled into some complex data
# interactions. There are a lot of data collaborators regarding these tests.
# I would love this to be more in isolation, but that is not in the cards as
# there are at least 16 database tables interacting to ultimately answer the
# following question:
#
# * What actions can a given user take on an entity?
#
# I don't know how we'll be interacting with these tests going forward, but I'm
# hoping a sane pattern will emerge. This may be a case for data fixtures, to
# help offload the mental processing of all of these blood let statements.
#
# But that is a future concern.
#
# REVIEW: How can we move towards testing the database seeds for ETDs?
module Sipity
  module Queries
    RSpec.describe ProcessingQueries, type: :isolated_repository_module do
      include Conversions::ConvertToPolymorphicType
      let(:user) { User.find_or_create_by!(username: 'user') }
      let(:group) { Models::Group.find_or_create_by!(name: 'group') }
      let(:role) { Models::Role.find_or_create_by!(name: Models::Role.valid_names.first) }
      let(:strategy) { Models::Processing::Strategy.find_or_create_by!(name: 'strategy', proxy_for_id: '1', proxy_for_type: 'AnWorkType') }
      let(:entity) do
        Models::Processing::Entity.find_or_create_by!(
          proxy_for_id: 1, proxy_for_type: 'AnEntity', strategy: strategy, strategy_state: originating_state
        )
      end
      let(:user_processing_actor) do
        Models::Processing::Actor.find_or_create_by!(proxy_for: user)
      end
      let(:group_processing_actor) do
        Models::Processing::Actor.find_or_create_by!(proxy_for: group)
      end
      let(:strategy_role) { Models::Processing::StrategyRole.find_or_create_by!(role: role, strategy: strategy) }
      let(:user_strategy_responsibility) do
        Models::Processing::StrategyResponsibility.find_or_create_by!(strategy_role: strategy_role, actor: user_processing_actor)
      end
      let(:entity_specific_responsibility) do
        Models::Processing::EntitySpecificResponsibility.find_or_create_by!(
          strategy_role: strategy_role, actor: user_processing_actor, entity: entity
        )
      end
      let(:action) { Models::Processing::StrategyAction.find_or_create_by!(strategy: strategy, name: 'complete') }
      let(:originating_state) { Models::Processing::StrategyState.find_or_create_by!(strategy: strategy, name: 'new') }
      let(:resulting_state) { Models::Processing::StrategyState.find_or_create_by!(strategy: strategy, name: 'done') }
      let(:strategy_state_action) do
        Models::Processing::StrategyStateAction.find_or_create_by!(originating_strategy_state: originating_state, strategy_action: action)
      end
      let(:action_permission) do
        Models::Processing::StrategyStateActionPermission.find_or_create_by!(
          strategy_role: strategy_role, strategy_state_action: strategy_state_action
        )
      end

      context '#scope_processing_strategy_roles_for_user_and_entity' do
        subject { test_repository.scope_processing_strategy_roles_for_user_and_entity(user: user, entity: entity) }
        it "will include the strategy specific roles for the given user" do
          user_processing_actor
          user_strategy_responsibility
          expect(subject).to eq([strategy_role])
        end
        it "will include the entity specific specific roles for the given user" do
          user_processing_actor
          entity_specific_responsibility
          expect(subject).to eq([strategy_role])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_processing_actors_for' do
        subject { test_repository.scope_processing_actors_for(user: user) }
        it 'will return an array of both user and group' do
          user_processing_actor
          group_processing_actor
          Models::GroupMembership.create(user_id: user.id, group_id: group.id)
          expect(subject).to eq([user_processing_actor, group_processing_actor])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_processing_entities_for_the_user_and_proxy_for_type' do
        before do
          Sipity::SpecSupport.load_database_seeds!(
            seeds_path: 'spec/fixtures/seeds/scope_processing_entities_for_the_user_and_proxy_for_type.rb'
          )
        end
        subject do
          test_repository.scope_proxied_objects_for_the_user_and_proxy_for_type(user: user, proxy_for_type: Sipity::Models::Work)
        end
        let(:user) { User.create!(username: 'user') }
        let(:advisor) { User.create!(username: 'advisor') }
        let(:no_access) { User.create!(username: 'no_access') }
        let(:commands) { CommandRepository.new }

        it "will resolve to an array of entities" do
          work_one = commands.create_work!(title: 'Book', work_type: 'etd', work_publication_strategy: 'will_not_publish')
          work_two = commands.create_work!(title: 'Book', work_type: 'etd', work_publication_strategy: 'will_not_publish')

          commands.grant_creating_user_permission_for!(entity: work_one, user: user)
          commands.grant_creating_user_permission_for!(entity: work_two, user: user)

          commands.grant_processing_permission_for!(entity: work_one, actor: advisor, role: 'advisor')

          expect(
            test_repository.scope_proxied_objects_for_the_user_and_proxy_for_type(user: user, proxy_for_type: Sipity::Models::Work)
          ).to eq([work_one, work_two])

          expect(
            test_repository.scope_proxied_objects_for_the_user_and_proxy_for_type(user: advisor, proxy_for_type: Sipity::Models::Work)
          ).to eq([work_one])

          expect(
            test_repository.scope_proxied_objects_for_the_user_and_proxy_for_type(user: no_access, proxy_for_type: Sipity::Models::Work)
          ).to eq([])
        end

        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_proxied_objects_for_the_user_and_proxy_for_type' do
        before do
          Sipity::SpecSupport.load_database_seeds!(seeds_path: 'spec/fixtures/seeds/trigger_work_state_change.rb')
        end
        let(:strategy) { Models::Processing::Strategy.first! }
        let(:originating_state) { Models::Processing::StrategyState.first! }
        let(:user) { User.create!(username: 'user') }
        subject do
          test_repository.scope_proxied_objects_for_the_user_and_proxy_for_type(user: user, proxy_for_type: Sipity::Models::Work)
        end

        it "will resolve to an array of entities" do
          work = Models::Work.create!
          entity = Models::Processing::Entity.find_or_create_by!(proxy_for: work, strategy: strategy, strategy_state: originating_state)
          user_actor = Models::Processing::Actor.find_or_create_by!(proxy_for: user)
          Models::Processing::EntitySpecificResponsibility.find_or_create_by!(
            strategy_role: strategy_role, actor: user_actor, entity: entity
          )
          Models::Processing::StrategyResponsibility.find_or_create_by!(strategy_role: strategy_role, actor: user_actor)

          expect(subject).to eq([work])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_users_for_entity_and_roles' do
        subject { test_repository.scope_users_for_entity_and_roles(entity: entity, roles: role) }
        it "will resolve to an array of users" do
          user = User.create!(username: 'user')
          group_user = User.create!(username: 'group')
          _other_user = User.create!(username: 'other')
          group = Models::Group.find_or_create_by!(name: 'group')
          group_actor = Models::Processing::Actor.find_or_create_by!(proxy_for: group)
          user_actor = Models::Processing::Actor.find_or_create_by!(proxy_for: user)
          Models::GroupMembership.create!(user: group_user, group: group)
          Models::Processing::EntitySpecificResponsibility.find_or_create_by!(
            strategy_role: strategy_role, actor: group_actor, entity: entity
          )
          Models::Processing::StrategyResponsibility.find_or_create_by!(strategy_role: strategy_role, actor: user_actor)

          expect(subject).to eq([user, group_user])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_users_from_actors' do
        subject { test_repository.scope_users_from_actors(actors: [group_processing_actor, user_processing_actor]) }
        it "will resolve to an array of users" do
          group_user = User.create!(username: 'another')
          _skip_this_user = User.create!(username: 'skip')
          Models::GroupMembership.create(user: group_user, group: group)
          user_processing_actor
          group_processing_actor
          user_processing_actor
          expect(subject).to eq([user, group_user])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_strategy_actions_that_are_prerequisites' do
        subject { test_repository.scope_strategy_actions_that_are_prerequisites(entity: entity) }
        let(:guarded_action) { Models::Processing::StrategyAction.find_or_create_by!(strategy_id: strategy.id, name: 'guarded_action') }

        it 'will return an array of actions' do
          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: guarded_action.id, prerequisite_strategy_action_id: action.id
          )
          expect(subject).to eq([action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_processing_strategy_roles_for_user_and_strategy' do
        subject { test_repository.scope_processing_strategy_roles_for_user_and_strategy(user: user, strategy: strategy) }
        it "will include the associated strategy roles for the given user" do
          user_processing_actor
          user_strategy_responsibility
          expect(subject).to eq([strategy_role])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_processing_strategy_roles_for_user_and_entity_specific' do
        subject { test_repository.scope_processing_strategy_roles_for_user_and_entity_specific(user: user, entity: entity) }
        it "will include the associated strategy roles for the given user" do
          user_processing_actor
          entity_specific_responsibility
          expect(subject).to eq([strategy_role])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_permitted_entity_strategy_actions_for_current_state' do
        subject { test_repository.scope_permitted_entity_strategy_actions_for_current_state(user: user, entity: entity) }
        it "will include permitted strategy_state_actions" do
          user_processing_actor
          entity_specific_responsibility
          action_permission
          expect(subject).to eq([action_permission.strategy_state_action.strategy_action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_strategy_actions_with_completed_prerequisites' do
        subject { test_repository.scope_strategy_actions_with_completed_prerequisites(entity: entity) }
        it "will include permitted strategy_state_actions" do
          other_guarded_action = Models::Processing::StrategyAction.find_or_create_by!(
            strategy_id: strategy.id, name: 'without_completed_prereq'
          )
          guarded_action = Models::Processing::StrategyAction.find_or_create_by!(strategy_id: strategy.id, name: 'with_completed_prereq')
          action.save unless action.persisted?
          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: guarded_action.id, prerequisite_strategy_action_id: action.id
          )
          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action, requested_by: user)
          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: other_guarded_action.id, prerequisite_strategy_action_id: guarded_action.id
          )
          expect(subject).to eq([guarded_action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_strategy_actions_with_incomplete_prerequisites' do
        subject { test_repository.scope_strategy_actions_with_incomplete_prerequisites(entity: entity) }
        context 'with some but not all of the prerequisites completed' do
          before do
            Sipity::SpecSupport.load_database_seeds!(
              seeds_path: 'spec/fixtures/seeds/scope_strategy_actions_with_incomplete_prerequisites.rb'
            )
          end
          let(:entity) { Sipity::Models::Processing::Entity.first! }
          let(:incomplete_action) do
            Sipity::Models::Processing::StrategyAction.find_by(name: 'submit_for_review', strategy_id: entity.strategy_id)
          end
          it 'will return only the actions with all prerequisites completed' do
            expect(subject).to eq([incomplete_action])
          end
          it "will be a chainable scope" do
            expect(subject).to be_a(ActiveRecord::Relation)
          end
        end
      end

      context '#scope_strategy_actions_without_prerequisites' do
        subject { test_repository.scope_strategy_actions_without_prerequisites(entity: entity) }
        let(:guarded_action) { Models::Processing::StrategyAction.find_or_create_by!(strategy_id: strategy.id, name: 'with_prereq') }
        it "will include actions that do not have prerequisites" do
          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: guarded_action.id, prerequisite_strategy_action_id: action.id
          )
          action.save! unless action.persisted?
          expect(subject).to eq([action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_statetegy_actions_that_have_occurred' do
        subject { test_repository.scope_statetegy_actions_that_have_occurred(entity: entity) }
        it "will include actions that do not have prerequisites" do
          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action, requested_by: user)
          expect(subject).to eq([action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#scope_strategy_actions_available_for_current_state' do
        subject { test_repository.scope_strategy_actions_available_for_current_state(entity: entity) }
        let(:guarded_action) do
          Models::Processing::StrategyAction.find_or_create_by!(strategy_id: strategy.id, name: 'with_completed_prereq')
        end
        let(:other_guarded_action) do
          Models::Processing::StrategyAction.find_or_create_by!(strategy_id: strategy.id, name: 'without_completed_prereq')
        end
        it "will include permitted strategy_state_actions" do
          action.save unless action.persisted?
          [action, guarded_action, other_guarded_action].each do |the_action|
            Models::Processing::StrategyStateAction.find_or_create_by!(
              strategy_action_id: the_action.id, originating_strategy_state_id: entity.strategy_state_id
            )
          end
          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: guarded_action.id, prerequisite_strategy_action_id: action.id
          )

          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action, requested_by: user)

          Models::Processing::StrategyActionPrerequisite.find_or_create_by!(
            guarded_strategy_action_id: other_guarded_action.id, prerequisite_strategy_action_id: guarded_action.id
          )
          expect(subject).to eq([action, guarded_action])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#usernames_of_those_that_have_taken_the_action_on_the_entity' do
        subject { test_repository.usernames_of_those_that_have_taken_the_action_on_the_entity(entity: entity, action: action) }
        it "will be an enumerable" do
          expect(subject).to be_a(Enumerable)
        end
      end
      context '#users_that_have_taken_the_action_on_the_entity' do
        subject { test_repository.users_that_have_taken_the_action_on_the_entity(entity: entity, action: action) }
        it "will include permitted strategy_state_actions" do
          user = User.create!(username: 'user')
          other_user = User.create!(username: 'another_user')
          groupy = User.create!(username: 'groupy')
          Models::GroupMembership.create(user_id: groupy.id, group_id: group.id)
          Conversions::ConvertToProcessingActor.call(user)
          Conversions::ConvertToProcessingActor.call(other_user)
          Conversions::ConvertToProcessingActor.call(group)
          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action, requested_by: user)
          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action, requested_by: group)
          expect(subject).to eq([user, groupy])
        end
        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

      context '#authorized_for_processing?' do
        it 'will return a boolean based on underlying interactions' do
          expect(test_repository).to receive(:scope_permitted_strategy_actions_available_for_current_state).and_call_original
          expect(test_repository.authorized_for_processing?(user: user, entity: entity, action: :show)).to eq(false)
        end
      end

      context '#scope_permitted_strategy_actions_available_for_current_state' do
        subject { test_repository.scope_permitted_strategy_actions_available_for_current_state(entity: entity, user: user) }
        let(:guarded_action) { Models::Processing::StrategyAction.find_or_create_by!(strategy: strategy, name: 'with_prereq') }
        before do
          strategy_role
          user_strategy_responsibility
          action_permission
        end
        it "will compose several other scopes to answer the question" do
          action_with_completed_prerequisites = Models::Processing::StrategyAction.find_or_create_by!(
            strategy: strategy, name: 'completed_prerequisites'
          ) do |current_action|
            current_action.requiring_strategy_action_prerequisites.build(prerequisite_strategy_action: action)
          end
          Services::RegisterActionTakenOnEntity.call(entity: entity, action: action_with_completed_prerequisites, requested_by: user)

          Models::Processing::StrategyAction.find_or_create_by!(strategy: strategy, name: 'with_incomplete_prereqs') do |current_action|
            current_action.requiring_strategy_action_prerequisites.build(
              prerequisite_strategy_action: action_with_completed_prerequisites
            )
          end

          Models::Processing::StrategyStateAction.find_or_create_by!(originating_strategy_state: originating_state, strategy_action: action)

          # Making sure that I have the expected counts
          expect(User.count).to eq(1)
          expect(Models::Processing::Actor.count).to eq(1)
          expect(Models::Processing::StrategyResponsibility.count).to eq(1)
          expect(Models::Processing::EntitySpecificResponsibility.count).to eq(0)
          expect(Models::Processing::StrategyRole.count).to eq(1)

          expect(Models::Role.count).to eq(1)

          expect(Models::Processing::StrategyAction.count).to eq(3)
          expect(Models::Processing::StrategyActionPrerequisite.count).to eq(2)
          expect(Models::Processing::StrategyStateAction.count).to eq(1)
          expect(Models::Processing::StrategyStateActionPermission.count).to eq(1)
          expect(Models::Processing::StrategyState.count).to eq(1)
          expect(Models::Processing::EntityActionRegister.count).to eq(1)
          expect(Models::Processing::Entity.count).to eq(1)

          expect(subject).to eq([action])
        end

        it "will be a chainable scope" do
          expect(subject).to be_a(ActiveRecord::Relation)
        end
      end

    end
  end
end
