class PicksController < ApplicationController
  def create
    match = current_season.matches.find(pick_params[:match_id])
    pick = current_user.picks.find_or_initialize_by(match: match)
    pick.assign_attributes(team_id: pick_params[:team_id])
    authorize pick

    if match.locked?
      redirect_to matches_path(season_id: current_season.id), alert: "Pick is locked for this match."
      return
    end

    if pick.save
      redirect_to matches_path(season_id: current_season.id), notice: "Pick saved."
    else
      redirect_to matches_path(season_id: current_season.id), alert: pick.errors.full_messages.to_sentence
    end
  end

  def update
    pick = current_user.picks.find(params[:id])
    authorize pick

    if pick.match.locked?
      redirect_to matches_path(season_id: current_season.id), alert: "Pick is locked for this match."
      return
    end

    if pick.update(team_id: pick_params[:team_id])
      redirect_to matches_path(season_id: current_season.id), notice: "Pick updated."
    else
      redirect_to matches_path(season_id: current_season.id), alert: pick.errors.full_messages.to_sentence
    end
  end

  private

  def pick_params
    params.require(:pick).permit(:team_id, :match_id)
  end
end
