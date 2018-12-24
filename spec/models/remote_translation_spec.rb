require 'rails_helper'

describe RemoteTranslation do

  let(:remote_translation) { build(:remote_translation, to: :es) }

  it "is valid" do
    expect(remote_translation).to be_valid
  end

  it "is valid without error_message" do
    remote_translation.error_message = nil
    expect(remote_translation).to be_valid
  end

  it "is not valid without to" do
    remote_translation.to = nil
    expect(remote_translation).not_to be_valid
  end

  it "is not valid without a remote_translatable_id" do
    remote_translation.remote_translatable_id = nil
    expect(remote_translation).not_to be_valid
  end

  it "is not valid without a remote_translatable_type" do
    remote_translation.remote_translatable_type = nil
    expect(remote_translation).not_to be_valid
  end

  describe '#enqueue_remote_translation' do

    it 'after create enqueue Delayed Job' do
      Delayed::Worker.delay_jobs = true

      expect { remote_translation.save }.to change { Delayed::Job.count }.by(1)

      Delayed::Worker.delay_jobs = false
    end

  end

end
