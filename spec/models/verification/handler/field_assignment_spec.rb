require "rails_helper"

describe Verification::Handler::FieldAssignment do
  let(:field_assignment) { build(:verification_handler_field_assignment) }

  it "Default factory should be valid" do
    expect(field_assignment).to be_valid
  end

  it "When field is not assigned it should not be valid" do
    field_assignment.verification_field = nil

    expect(field_assignment).not_to be_valid
  end

  it "When handler is not defined it should not be valid" do
    field_assignment.handler = nil

    expect(field_assignment).not_to be_valid
  end
end