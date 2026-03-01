module Admin
  class PicksController < BaseController
    before_action :set_pick, only: [:edit, :update]

    def index
      authorize Pick
      @picks = Pick.joins(:match)
        .where(matches: { season_id: current_season.id })
        .includes(:user, :team, match: [:home_team, :away_team])
        .order("matches.match_datetime DESC")
    end

    def edit
      authorize @pick
      @teams = [@pick.match.home_team, @pick.match.away_team]
    end

    def update
      authorize @pick
      from_team = @pick.team

      if @pick.update(team_id: pick_params[:team_id], updated_by_admin: current_user)
        PickAuditLog.create!(
          pick: @pick,
          match: @pick.match,
          user: @pick.user,
          editor_admin: current_user,
          from_team: from_team,
          to_team: @pick.team,
          reason: pick_params[:reason].presence || "Admin pick correction"
        )
        Scoring::MatchRecalculator.new(match: @pick.match, admin: current_user).call if @pick.match.completed?
        redirect_to admin_picks_path(season_id: current_season.id), notice: "Pick updated."
      else
        @teams = [@pick.match.home_team, @pick.match.away_team]
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_pick
      @pick = Pick.find(params[:id])
    end

    def pick_params
      params.require(:pick).permit(:team_id, :reason)
    end
  end
end
