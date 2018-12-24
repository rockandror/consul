class RemoteTranslation < ActiveRecord::Base

  belongs_to :remote_translatable, polymorphic: true

  validates :remote_translatable_id, presence: true
  validates :remote_translatable_type, presence: true
  validates :to, presence: true

  after_create :enqueue_remote_translation

  def enqueue_remote_translation
    RemoteTranslationsCaller.new.delay.call(self)
  end

end
