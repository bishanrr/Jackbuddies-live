require "yaml"

class LeaderboardsController < ApplicationController
  def index
    authorize :leaderboard, :show?
    @leaderboard_view = %w[table graphs].include?(params[:view].to_s) ? params[:view].to_s : "table"
    points_data = current_season&.year == 2025 ? player_points_data_2025 : {}
    @users = users_for_display(points_data)
    @rows = rows_for_display(@users)
    @matches = current_season.matches.includes(:home_team, :away_team, :winner_team).order(:match_datetime)
    @display_match_no_by_match_id = build_display_match_no_map(@matches)
    @points_by_match_user = points_by_match_user_for_display
    @total_points_by_match_id = @matches.each_with_object({}) do |match, acc|
      acc[match.id] = @users.sum { |user| @points_by_match_user[[match.id, user.id]].to_i }
    end
    @chart_points_by_user = chart_points_by_user
    @chart_accuracy_by_user = chart_accuracy_by_user
    @chart_picks_by_user = chart_picks_by_user
    @chart_cumulative_points_by_user = chart_cumulative_points_by_user
  end

  private

  def chart_points_by_user
    @rows.sort_by { |row| -row.points.to_i }.to_h { |row| [row.user.name_or_email, row.points.to_i] }
  end

  def chart_accuracy_by_user
    @rows.sort_by { |row| -row.accuracy.to_f }.to_h { |row| [row.user.name_or_email, row.accuracy.to_f] }
  end

  def chart_picks_by_user
    sorted = @rows.sort_by { |row| -row.correct_picks.to_i }
    [
      { name: "Correct Picks", data: sorted.to_h { |row| [row.user.name_or_email, row.correct_picks.to_i] } },
      { name: "Total Picks", data: sorted.to_h { |row| [row.user.name_or_email, row.completed_picks.to_i] } }
    ]
  end

  def chart_cumulative_points_by_user
    match_labels = @matches.each_with_object({}) do |match, acc|
      acc[match.id] = @display_match_no_by_match_id[match.id].to_s
    end

    @rows
      .sort_by { |row| -row.points.to_i }
      .first(6)
      .map do |row|
        running_total = 0
        data = {}

        @matches.each do |match|
          running_total += @points_by_match_user[[match.id, row.user.id]].to_i
          data[match_labels[match.id]] = running_total
        end

        { name: row.user.name_or_email, data: data }
      end
  end

  def points_by_match_user_for_display
    if current_season&.year == 2025
      points_data = player_points_data_2025
      return points_by_match_user_from_file(points_data) if points_data.present?
    end

    PointsEvent.active
      .where(season_id: current_season.id, match_id: @matches.map(&:id), user_id: @users.map(&:id))
      .group(:match_id, :user_id)
      .sum(:points)
  end

  def player_points_data_2025
    path = Rails.root.join("config/ipl_2025_player_points.yml")
    return {} unless path.exist?

    YAML.safe_load_file(path) || {}
  end

  def users_for_display(points_data)
    users = User.approved.order(:display_name, :email)
    return users unless current_season&.year == 2025 && points_data.present?

    blocked_names = %w[aarav diya leagueadmin]
    allowed_names = points_data.keys.map { |name| normalize_name(name) }

    users.select do |user|
      normalized = normalize_name(user.display_name.presence || user.name_or_email)
      allowed_names.include?(normalized) && !blocked_names.include?(normalized)
    end
  end

  def rows_for_display(users)
    rows = LeaderboardQuery.call(current_season)
    return rows unless current_season&.year == 2025

    allowed_ids = users.map(&:id)
    filtered = rows.select { |row| allowed_ids.include?(row.user.id) }
    filtered.each_with_index { |row, idx| row.rank = idx + 1 }
    filtered
  end

  def points_by_match_user_from_file(points_data)
    normalized_points = points_data.transform_keys { |name| normalize_name(name) }
    values_by_user_id = {}

    @users.each do |user|
      payload = normalized_points[normalize_name(user.display_name.presence || user.name_or_email)]
      next unless payload

      league = Array(payload["league_segments"]).flatten.map(&:to_i)
      playoff = %w[Q1 ELIMINATOR Q2 FINAL].map { |label| payload.dig("knockouts", label).to_i }
      values_by_user_id[user.id] = league + playoff
    end

    points_by_match_user = {}

    @matches.each do |match|
      label = @display_match_no_by_match_id[match.id].to_s
      next unless label

      idx = point_index_from_label(label)
      next unless idx

      @users.each do |user|
        points_by_match_user[[match.id, user.id]] = values_by_user_id.dig(user.id, idx).to_i
      end
    end

    points_by_match_user
  end

  def build_display_match_no_map(matches)
    return matches.index_with { |match| match.match_no || "-" } unless current_season&.year == 2025

    q_matches = matches.select { |m| m.stage == "qualifier" }.sort_by(&:match_datetime)
    league_matches = matches.select { |m| m.stage == "league" }.sort_by(&:id)
    fallback_league_no_by_id = league_matches.each_with_index.each_with_object({}) do |(match, idx), acc|
      acc[match.id] = idx + 1
    end

    matches.each_with_object({}) do |match, acc|
      acc[match.id] =
        if match.stage == "league"
          match.match_no.presence || fallback_league_no_by_id[match.id]
        elsif match.match_no.present?
          match.match_no
        elsif match.stage == "eliminator"
          "ELIMINATOR"
        elsif match.stage == "final"
          "FINAL"
        elsif match.stage == "qualifier"
          match.id == q_matches[0]&.id ? "Q1" : "Q2"
        else
          "-"
        end
    end
  end

  def point_index_from_label(label)
    return label.to_i - 1 if label.match?(/\A\d+\z/)

    case label
    when "Q1" then 70
    when "ELIMINATOR" then 71
    when "Q2" then 72
    when "FINAL" then 73
    end
  end

  def normalize_name(name)
    name.to_s.downcase.gsub(/\s+/, "")
  end
end
