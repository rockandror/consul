class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  default_scope { order(id: :asc) }

  def type
    prefix = key.split(".").first
    if %w[feature process proposals map html homepage].include? prefix
      prefix
    elsif %w[remote_census].include? prefix
      key.rpartition(".").first
    else
      "configuration"
    end
  end

  def enabled?
    value.present?
  end

  class << self
    def [](key)
      where(key: key).pluck(:value).first.presence
    end

    def []=(key, value)
      setting = where(key: key).first || new(key: key)
      setting.value = value.presence
      setting.save!
      value
    end

    def rename_key(from:, to:)
      if where(key: to).empty?
        value = where(key: from).pluck(:value).first.presence
        create!(key: to, value: value)
      end
      remove(from)
    end

    def remove(key)
      setting = where(key: key).first
      setting.destroy if setting.present?
    end

    def force_presence_date_of_birth?
      Setting["feature.remote_census"].present? &&
        Setting["remote_census.request.date_of_birth"].present?
    end

    def force_presence_postal_code?
      Setting["feature.remote_census"].present? &&
        Setting["remote_census.request.postal_code"].present?
    end
  end
end
