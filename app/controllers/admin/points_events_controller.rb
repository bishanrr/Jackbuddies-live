module Admin
  class PointsEventsController < BaseController
    def index
      authorize PointsEvent
      @events = PointsEvent.where(season: current_season).includes(:user, :match, :created_by_admin).order(created_at: :desc)
    end

    def new
      @event = PointsEvent.new
      authorize @event
      @users = User.approved.order(:display_name, :email)
    end

    def create
      @event = PointsEvent.new(points_event_params)
      @event.season = current_season
      @event.created_by_admin = current_user
      @event.event_type = :manual_adjustment
      authorize @event

      if @event.save
        redirect_to admin_points_events_path(season_id: current_season.id), notice: "Adjustment added."
      else
        @users = User.approved.order(:display_name, :email)
        render :new, status: :unprocessable_entity
      end
    end

    private

    def points_event_params
      params.require(:points_event).permit(:user_id, :points, :reason, :match_id)
    end
  end
end
