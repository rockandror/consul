module Abilities
  class Everyone
    include CanCan::Ability

    def initialize(user)
      can [:read, :map], Debate
      can [:read, :map, :summary, :share], Proposal
      can :read, Comment
      can :read, Poll
      can :results_2018, Poll
      can :stats_2018, Poll
      can :results, Poll do |poll|
        poll.expired? && poll.results_enabled?
      end
      can :stats, Poll do |poll|
        poll.expired? && poll.stats_enabled?
      end
      can :read, Poll::Question
      can [:read, :welcome], Budget
      can [:read, :welcome, :select_district], SpendingProposal
      can [:stats, :results], SpendingProposal
      can :read, User
      can [:read], Budget
      can [:read], Budget::Group
      can [:read, :print, :json_data], Budget::Investment
      can [:read_results, :read_executions], Budget, phase: "finished"
      can(:read_stats, Budget) { |budget| budget.valuating_or_later? }
      can :new, DirectMessage
      can [:read, :debate, :draft_publication, :allegations, :result_publication,
           :proposals, :milestones], Legislation::Process, published: true
      can [:read, :changes, :go_to_version], Legislation::DraftVersion
      can [:read], Legislation::Question
      can [:read, :map, :share], Legislation::Proposal
      can [:search, :comments, :read, :create, :new_comment], Legislation::Annotation
      can :results_2017, Poll
      can :stats_2017, Poll
      can :info_2017, Poll
    end
  end
end
