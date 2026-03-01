module Admin
  class MatchesController < BaseController
    before_action :set_match, only: [:show, :edit, :update, :destroy, :set_result, :recalculate]

    def index
      authorize Match
      @matches = current_season.matches.includes(:home_team, :away_team, :winner_team).order(:match_datetime)
      @seasons = Season.order(year: :desc)
    end

    def show
      authorize @match
    end

    def new
      @match = Match.new(season: current_season)
      authorize @match
      load_form_data
    end

    def create
      @match = Match.new(match_params)
      authorize @match

      if @match.save
        redirect_to admin_matches_path(season_id: @match.season_id), notice: "Match created."
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @match
      load_form_data
    end

    def update
      authorize @match
      if @match.update(match_params)
        redirect_to admin_matches_path(season_id: @match.season_id), notice: "Match updated."
      else
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @match
      season_id = @match.season_id
      @match.destroy
      redirect_to admin_matches_path(season_id: season_id), notice: "Match deleted."
    end

    def set_result
      authorize @match, :update?
      if @match.update(result_params.merge(status: :completed))
        Scoring::MatchRecalculator.new(match: @match, admin: current_user).call
        redirect_to admin_matches_path(season_id: @match.season_id), notice: "Result saved and points recalculated."
      else
        redirect_to admin_matches_path(season_id: @match.season_id), alert: @match.errors.full_messages.to_sentence
      end
    end

    def recalculate
      authorize @match, :update?
      Scoring::MatchRecalculator.new(match: @match, admin: current_user).call
      redirect_to admin_matches_path(season_id: @match.season_id), notice: "Match points recalculated."
    end

    private

    def set_match
      @match = Match.find(params[:id])
    end

    def load_form_data
      @teams = Team.order(:name)
      @seasons = Season.order(year: :desc)
    end

    def match_params
      params.require(:match).permit(:season_id, :match_no, :home_team_id, :away_team_id, :match_datetime, :stage, :status, :winner_team_id, :title)
    end

    def result_params
      params.require(:match).permit(:winner_team_id)
    end
  end
end
