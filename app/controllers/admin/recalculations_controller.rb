module Admin
  class RecalculationsController < BaseController
    def season
      season = Season.find(params[:season_id])
      authorize season, :update?

      Scoring::SeasonRecalculator.new(season: season, admin: current_user).call
      redirect_to admin_matches_path(season_id: season.id), notice: "Season recalculation complete."
    end
  end
end
