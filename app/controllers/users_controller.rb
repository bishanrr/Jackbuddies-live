class UsersController < ApplicationController
  PLAYER_NAMES_2025 = %w[
    Akhil
    Arun
    Bishan
    Gopi
    Naveen
    Prasad
    Praveen
    Raghu
    Raju
    Sreekanth
    Sunny
    Vishal
  ].freeze

  def index
    authorize User
    @users = User.approved.search(params[:q]).order(:display_name, :email)
    @users_2025 = users_2025_table_rows
  end

  def show
    @user = User.find(params[:id])
    authorize @user

    @stats = SeasonStatsQuery.call(user: @user, season: current_season)
    @picks = @user.picks
      .joins(:match)
      .where(matches: { season_id: current_season.id })
      .includes(:team, match: [:home_team, :away_team, :winner_team])
      .order("matches.match_datetime ASC")

    @points_by_match_id = @user.points_events.active.where(season: current_season, match_id: @picks.map(&:match_id)).group(:match_id).sum(:points)
  end

  private

  def users_2025_table_rows
    return [] unless current_season&.year == 2025

    users_by_name = User.approved
      .where(role: :user)
      .where("LOWER(COALESCE(display_name, '')) IN (?)", PLAYER_NAMES_2025.map(&:downcase))
      .index_by { |user| user.display_name.to_s.downcase }
    pick_results_by_user_id = pick_results_by_user_id(users_by_name.values.map(&:id))

    PLAYER_NAMES_2025.map do |name|
      user = users_by_name[name.downcase]
      pick_results = user.present? ? pick_results_by_user_id[user.id] : nil
      {
        name: name,
        user: user,
        account_created: user.present?,
        matches_won: pick_results&.fetch("matches_won", 0).to_i,
        matches_lost: pick_results&.fetch("matches_lost", 0).to_i
      }
    end
  end

  def pick_results_by_user_id(user_ids)
    return {} if user_ids.blank?

    Pick.joins(:match)
      .where(user_id: user_ids, matches: { season_id: current_season.id, status: Match.statuses[:completed] })
      .where.not(matches: { winner_team_id: nil })
      .group(:user_id)
      .pluck(
        :user_id,
        Arel.sql("SUM(CASE WHEN picks.team_id = matches.winner_team_id THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN picks.team_id <> matches.winner_team_id THEN 1 ELSE 0 END)")
      )
      .each_with_object({}) do |(user_id, won, lost), acc|
        acc[user_id] = { "matches_won" => won.to_i, "matches_lost" => lost.to_i }
      end
  end
end
