class DashboardController < ApplicationController
  def index
    authorize :dashboard, :show?
    @pot_context_year = current_season&.year
    @pot_max = 0
    @pot_display_total = 0
    @winner = nil
    @runner_up = nil
    @top_two = []
    @least_paid = nil
    @second_least_paid = nil
    @jackpot_total = 0
    return unless current_season

    @pot_context_year = current_season.year.to_i
    @current_season_total = season_total_points(current_season)
    @previous_season = Season.where("year < ?", current_season.year).order(year: :desc).first
    @previous_season_total = @previous_season ? season_total_points(@previous_season) : 0
    @season_started = season_started?(current_season)

    @pot_max =
      if @previous_season_total.positive?
        @previous_season_total
      else
        [@current_season_total, 1].max
      end

    @pot_display_total =
      if !@season_started && @previous_season_total.positive?
        @previous_season_total
      else
        @current_season_total
      end

    rows = LeaderboardQuery.call(current_season)
    rows = rows.sort_by { |row| [-row.points.to_i, row.user.name_or_email.downcase] }

    @winner = rows.first
    @runner_up = rows.second
    @top_two = rows.first(2)
    @least_paid = rows.last
    @second_least_paid = rows[-2]
    @jackpot_total = @current_season_total
  end

  private

  def season_total_points(season)
    return 0 unless season

    LeaderboardQuery.call(season).sum { |row| row.points.to_i }
  end

  def season_started?(season)
    return false unless season

    season.matches.completed.exists? || season.points_events.active.exists?
  end
end
