module Admin
  class SeasonsController < BaseController
    before_action :set_season, only: [:show, :edit, :update, :destroy]

    def index
      authorize Season
      @seasons = Season.order(year: :desc)
    end

    def show
      authorize @season
    end

    def new
      @season = Season.new
      authorize @season
    end

    def create
      @season = Season.new(season_params)
      authorize @season
      if @season.save
        redirect_to admin_season_path(@season), notice: "Season created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @season
    end

    def update
      authorize @season
      if @season.update(season_params)
        redirect_to admin_season_path(@season), notice: "Season updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @season
      @season.destroy
      redirect_to admin_seasons_path, notice: "Season removed."
    end

    private

    def set_season
      @season = Season.find(params[:id])
    end

    def season_params
      params.require(:season).permit(:year, :name, :default_lock_minutes)
    end
  end
end
