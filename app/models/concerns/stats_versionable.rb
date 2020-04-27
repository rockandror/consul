module StatsVersionable
  extend ActiveSupport::Concern

  included do
    has_one :stats_version, as: :process, inverse_of: :process, dependent: :destroy
  end

  def find_or_create_stats_version
    stats_version || create_stats_version
  end
end
