module Admin
  class DashboardController < BaseController
    def index
      @pending_users = User.pending.order(:created_at)
      @recent_matches = current_season.matches.includes(:home_team, :away_team).order(match_datetime: :desc).limit(10)
      @today_matches = current_season.matches.includes(:home_team, :away_team).where(match_datetime: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day).order(:match_datetime)
      @daily_entry_template = daily_entry_template
      @daily_entries = DailyMatchEntry.where(season: current_season).order(match_no: :desc, processed_at: :desc).limit(100)
    end

    def daily_match_entries
      result = Admin::DailyMatchEntryProcessor.new(
        season: current_season,
        admin_user: current_user,
        raw_text: params[:daily_entry_text]
      ).call

      message = "Processed #{result.processed_matches} matches and #{result.updated_picks} picks."
      message = "#{message} Unresolved users: #{result.unresolved_users.join(', ')}." if result.unresolved_users.any?
      if result.errors.any?
        redirect_to admin_root_path(season_id: current_season.id), alert: "#{message} Errors: #{result.errors.join(' | ')}"
      else
        redirect_to admin_root_path(season_id: current_season.id), notice: message
      end
    rescue StandardError => e
      redirect_to admin_root_path(season_id: current_season.id), alert: "Daily entry failed: #{e.message}"
    end

    private

    def daily_entry_template
      <<~TEXT
        *Match 67 : GT VS CSK*

        *GT*: Bishan, Raghu, Sandeep, Arun, Vishal, Gopi, Sreekanth, Naveen

        *CSK*: Praveen, Akhil

        Monkey JUMP : Sandeep, Arun

        WINNER : CSK
      TEXT
    end
  end
end
