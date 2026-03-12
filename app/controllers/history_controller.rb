class HistoryController < ApplicationController
  def index
    authorize :history, :show?

    @selected_user = User.approved.find_by(id: params[:user_id]) || current_user
    @leaderboard = []
    @stats = nil
    @picks = []
    return unless current_season

    @leaderboard = LeaderboardQuery.call(current_season)
    @stats = SeasonStatsQuery.call(user: @selected_user, season: current_season)
    @picks = @selected_user.picks
      .joins(:match)
      .where(matches: { season_id: current_season.id })
      .includes(:team, match: [:home_team, :away_team, :winner_team])
      .order("matches.match_datetime ASC")
  end
end
