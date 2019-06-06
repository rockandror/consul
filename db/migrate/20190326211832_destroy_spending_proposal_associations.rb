class DestroySpendingProposalAssociations < ActiveRecord::Migration[4.2]
  def change
    remove_column :budget_investments, :original_spending_proposal_id
    remove_column :tags, :spending_proposals_count
    remove_column :valuators, :spending_proposals_count
  end
end