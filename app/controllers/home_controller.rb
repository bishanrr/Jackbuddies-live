class HomeController < ApplicationController
  def index
    return unless current_season

    @current_season_total = season_total_points(current_season)
    @previous_season = Season.where("year < ?", current_season.year).order(year: :desc).first
    @previous_season_total = @previous_season ? season_total_points(@previous_season) : 0
    @season_started = season_started?(current_season)

    @target_max =
      if @previous_season_total.positive?
        @previous_season_total
      else
        [@current_season_total, 1].max
      end

    @display_total =
      if !@season_started && @previous_season_total.positive?
        @previous_season_total
      else
        @current_season_total
      end

    @overflow_points = [@display_total - @target_max, 0].max
  end

  private

  def season_total_points(season)
    LeaderboardQuery.call(season).sum { |row| row.points.to_i }
  end

  def season_started?(season)
    season.matches.completed.exists? || season.points_events.active.exists?
  end
end
