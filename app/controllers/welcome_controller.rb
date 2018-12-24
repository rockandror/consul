class WelcomeController < ApplicationController
  include RemotelyTranslatable

  skip_authorization_check
  before_action :set_user_recommendations, only: :index, if: :current_user

  layout "devise", only: [:welcome, :verification]

  def index
    @header = Widget::Card.header.first
    @feeds = Widget::Feed.active
    @cards = Widget::Card.body
    @banners = Banner.in_section('homepage').with_active
    @remote_translations = detect_remote_translations(parse_feed(@feeds.first),
                                                      parse_feed(@feeds.second),
                                                      parse_feed(@feeds.third),
                                                      @recommended_debates,
                                                      @recommended_proposals)
  end

  def welcome
  end

  def verification
    redirect_to verification_path if signed_in?
  end

  private

  def set_user_recommendations
    @recommended_debates = Debate.recommendations(current_user).sort_by_recommendations.limit(3)
    @recommended_proposals = Proposal.recommendations(current_user).sort_by_recommendations.limit(3)
  end

  def parse_feed(feed)
    feed.present? ? feed.items : []
  end

end
