module Admin
  class TeamsController < BaseController
    before_action :set_team, only: [:edit, :update, :destroy]

    def index
      authorize Team
      @teams = Team.order(:name)
    end

    def new
      @team = Team.new
      authorize @team
    end

    def create
      @team = Team.new(team_params)
      authorize @team
      if @team.save
        redirect_to admin_teams_path, notice: "Team created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @team
    end

    def update
      authorize @team
      if @team.update(team_params)
        redirect_to admin_teams_path, notice: "Team updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @team
      @team.destroy
      redirect_to admin_teams_path, notice: "Team removed."
    end

    private

    def set_team
      @team = Team.find(params[:id])
    end

    def team_params
      params.require(:team).permit(:name, :short_name)
    end
  end
end
