require "json"
require "yaml"

class MatchesController < ApplicationController
  def index
    authorize Match
    @matches_view = %w[league playoffs points].include?(params[:view].to_s) ? params[:view].to_s : "league"
    @show_match_tabs = false
    @upcoming_matches = Match.none
    @completed_matches = Match.none
    @playoff_rows = []
    @points_players = []
    @selected_player = "all"
    @selected_player_rows = []
    @player_summary_rows = []
    @display_match_no_by_match_id = {}
    @winner_names_by_match_id = {}
    @winner_data_present_by_match_id = {}
    @picks_by_match_id = {}
    return unless current_season

    @show_match_tabs = current_season.matches.exists?
    season_points_data = player_points_data_for_current_season
    season_winners_present = winners_rows.present?

    if season_winners_present
      @upcoming_matches = Match.none
      file_matches = current_season.matches.includes(:home_team, :away_team, :winner_team).to_a
      @display_match_no_by_match_id, @winner_names_by_match_id, @winner_data_present_by_match_id = build_match_display_mappings_from_winners(file_matches)
      @completed_matches = file_matches
        .select { |match| match.stage == "league" }
        .select do |match|
          match_no = @display_match_no_by_match_id[match.id] || match.match_no
          match_no.present? && match_no.to_i.between?(1, 70)
        end
        .sort_by { |match| (@display_match_no_by_match_id[match.id] || match.match_no).to_i }
      @playoff_rows = playoff_rows_from_winners(file_matches)
      if @matches_view == "points"
        if season_points_data.present?
          load_points_tab_from_file(season_points_data)
        else
          load_points_tab_from_events
        end
      else
        @points_players = []
        @selected_player = nil
        @selected_player_rows = []
        @player_summary_rows = []
      end
    else
      @upcoming_matches = current_season.matches.scheduled.includes(:home_team, :away_team, :winner_team)
      completed = current_season.matches.completed.includes(:home_team, :away_team, :winner_team)
      @completed_matches =
        if @matches_view == "playoffs"
          completed.where(stage: [Match.stages[:qualifier], Match.stages[:eliminator], Match.stages[:final]])
        else
          completed.where(stage: Match.stages[:league])
        end
      @display_match_no_by_match_id = {}
      @winner_names_by_match_id = {}
      @winner_data_present_by_match_id = {}
      @playoff_rows = playoff_rows_for_non_2025(completed)
      load_points_tab_from_events if @matches_view == "points"
    end
    @picks_by_match_id = current_user.picks.where(match_id: current_season.matches.select(:id)).index_by(&:match_id)
  end

  private

  def winners_rows
    path = Rails.root.join("config/ipl_#{current_season.year}_match_winners.js")
    return [] unless path.exist?

    raw = path.read
    js_text = raw.sub(/\A\s*const\s+matches\s*=\s*/m, "").sub(/;\s*\z/m, "").strip
    json_text = js_text.gsub(/([{,]\s*)([A-Za-z_]\w*)\s*:/, '\1"\2":')
    rows = JSON.parse(json_text)
    # matchNo is the unique key; keep the last occurrence if duplicates exist.
    unique_rows = rows.each_with_object({}) { |row, acc| acc[row["matchNo"].to_s.strip] = row }.values
    unique_rows.sort_by do |row|
      key = row["matchNo"].to_s.strip
      key.match?(/\A\d+\z/) ? [0, key.to_i] : [1, key]
    end
  rescue JSON::ParserError
    []
  end

  def build_match_display_mappings_from_winners(matches)
    rows = winners_rows
      .select { |row| row["matchNo"].to_s.match?(/\A\d+\z/) }
      .select { |row| row["matchNo"].to_i.between?(1, 70) }
      .sort_by { |row| row["matchNo"].to_i }
    display_match_no_by_match_id = {}
    winner_names_by_match_id = {}
    winner_data_present_by_match_id = {}

    rows_by_match_no = rows.index_by { |row| row["matchNo"].to_i }
    league_matches = matches.select { |match| match.stage == "league" }.sort_by(&:id)

    # matchNo is the primary key for table mapping. If DB match_no is missing, use league order.
    league_matches.each_with_index do |match, idx|
      match_no = match.match_no.present? ? match.match_no.to_i : (idx + 1)
      display_match_no_by_match_id[match.id] = match_no

      row = rows_by_match_no[match_no]
      next unless row

      winner_names_by_match_id[match.id] = normalize_winner_names(row["usersWon"])
      winner_data_present_by_match_id[match.id] = true
    end

    [display_match_no_by_match_id, winner_names_by_match_id, winner_data_present_by_match_id]
  end

  def normalize_winner_names(values)
    Array(values).map(&:to_s).map(&:strip).reject(&:blank?)
  end

  def playoff_rows_from_winners(matches)
    winner_rows_by_label = winners_rows
      .select { |row| row["matchNo"].to_s.match?(/\A[A-Z0-9]+\z/) && !row["matchNo"].to_s.match?(/\A\d+\z/) }
      .index_by { |row| row["matchNo"].to_s.upcase }

    qualifier_matches = matches.select { |match| match.stage == "qualifier" }.sort_by(&:match_datetime)
    eliminator_match = matches.select { |match| match.stage == "eliminator" }.min_by(&:match_datetime)
    final_match = matches.select { |match| match.stage == "final" }.min_by(&:match_datetime)

    planned = [
      ["Q1", qualifier_matches[0]],
      ["ELIMINATOR", eliminator_match],
      ["Q2", qualifier_matches[1]],
      ["FINAL", final_match]
    ]

    planned.filter_map do |label, match|
      next unless match

      winner_row = winner_rows_by_label[label]
      {
        label: label,
        match: match,
        winner_names: winner_row ? normalize_winner_names(winner_row["usersWon"]) : [],
        winner_data_present: winner_row.present?
      }
    end
  end

  def load_points_tab_from_file(points_data)
    @points_players = points_data.keys.sort
    allowed_values = @points_players + ["all"]
    @selected_player = allowed_values.include?(params[:player].to_s) ? params[:player].to_s : "all"
    @player_summary_rows = build_player_summary_rows(points_data)
    @selected_player_rows =
      if @selected_player == "all"
        build_all_players_rows(points_data)
      else
        build_selected_player_rows(@selected_player, points_data[@selected_player])
      end
  end

  def player_points_data_for_current_season
    path = Rails.root.join("config/ipl_#{current_season.year}_player_points.yml")
    return {} unless path.exist?

    YAML.safe_load_file(path) || {}
  end

  def build_player_summary_rows(points_data)
    points_data.map do |player, payload|
      league = Array(payload["league_segments"]).flatten.map(&:to_i)
      knockouts = Array(%w[Q1 ELIMINATOR Q2 FINAL]).sum { |label| payload.dig("knockouts", label).to_i }
      league_total = league.sum
      {
        player: player,
        league_total: league_total,
        playoff_total: knockouts,
        grand_total: league_total + knockouts
      }
    end.sort_by { |row| -row[:grand_total] }
  end

  def build_selected_player_rows(player_name, payload)
    return [] unless payload

    league = Array(payload["league_segments"]).flatten.map(&:to_i)
    playoff_labels = %w[Q1 ELIMINATOR Q2 FINAL]
    playoff_points = playoff_labels.map { |label| payload.dig("knockouts", label).to_i }
    rows = []
    cumulative = 0

    league.each_with_index do |points, idx|
      cumulative += points
      rows << {
        label: (idx + 1).to_s,
        points: points,
        cumulative: cumulative,
        points_paid: "#{player_name} (#{points})"
      }
    end

    playoff_labels.each_with_index do |label, idx|
      points = playoff_points[idx]
      cumulative += points
      rows << {
        label: label,
        points: points,
        cumulative: cumulative,
        points_paid: "#{player_name} (#{points})"
      }
    end

    rows
  end

  def build_all_players_rows(points_data)
    player_rows = points_data.transform_values do |payload|
      league = Array(payload["league_segments"]).flatten.map(&:to_i)
      playoff = %w[Q1 ELIMINATOR Q2 FINAL].map { |label| payload.dig("knockouts", label).to_i }
      league + playoff
    end

    labels = (1..70).map(&:to_s) + %w[Q1 ELIMINATOR Q2 FINAL]
    cumulative = 0

    labels.each_with_index.map do |label, idx|
      per_player = player_rows.map { |name, points| [name, points[idx].to_i] }
      per_player.sort_by! { |name, points| [-points, name] }
      match_total = per_player.sum { |_name, points| points }
      cumulative += match_total

      {
        label: label,
        points: match_total,
        cumulative: cumulative,
        points_paid: per_player.map { |name, points| "#{name} (#{points})" }.join(", ")
      }
    end
  end

  def playoff_rows_for_non_2025(completed_matches_relation)
    matches = completed_matches_relation.to_a
    qualifiers = matches.select { |m| m.stage == "qualifier" }.sort_by(&:match_datetime)
    eliminator = matches.select { |m| m.stage == "eliminator" }.min_by(&:match_datetime)
    final = matches.select { |m| m.stage == "final" }.min_by(&:match_datetime)

    [
      ["Q1", qualifiers[0]],
      ["ELIMINATOR", eliminator],
      ["Q2", qualifiers[1]],
      ["FINAL", final]
    ].filter_map do |label, match|
      next unless match

      { label: label, match: match, winner_names: [], winner_data_present: false }
    end
  end

  def load_points_tab_from_events
    users = User.approved.order(:display_name, :email).to_a
    completed_matches = current_season.matches.completed.includes(:home_team, :away_team).order(:match_no, :match_datetime).to_a
    points_by_match_user = PointsEvent.active
      .where(season: current_season, match_id: completed_matches.map(&:id))
      .group(:match_id, :user_id)
      .sum(:points)

    rows_by_user = Hash.new { |h, k| h[k] = { league_total: 0, playoff_total: 0, grand_total: 0 } }
    points_by_match_user.each do |(match_id, user_id), points|
      match = completed_matches.find { |m| m.id == match_id }
      next unless match

      if match.stage == "league"
        rows_by_user[user_id][:league_total] += points
      else
        rows_by_user[user_id][:playoff_total] += points
      end
      rows_by_user[user_id][:grand_total] += points
    end

    @points_players = users.select { |u| rows_by_user[u.id][:grand_total].positive? }.map(&:name_or_email).sort
    allowed_values = @points_players + ["all"]
    @selected_player = allowed_values.include?(params[:player].to_s) ? params[:player].to_s : "all"

    @player_summary_rows = users
      .map do |user|
        totals = rows_by_user[user.id]
        next if totals[:grand_total].zero?

        {
          player: user.name_or_email,
          league_total: totals[:league_total],
          playoff_total: totals[:playoff_total],
          grand_total: totals[:grand_total]
        }
      end
      .compact
      .sort_by { |row| -row[:grand_total] }

    label_for_match = lambda do |match|
      return match.match_no.to_s if match.match_no.present?

      case match.stage
      when "qualifier" then "Q"
      when "eliminator" then "ELIMINATOR"
      when "final" then "FINAL"
      else "-"
      end
    end

    ordered_matches = completed_matches.sort_by do |m|
      [m.match_no.to_i.zero? ? 10_000 : m.match_no.to_i, m.match_datetime]
    end

    if @selected_player == "all"
      cumulative = 0
      @selected_player_rows = ordered_matches.map do |match|
        per_player = users.map do |user|
          [user.name_or_email, points_by_match_user[[match.id, user.id]].to_i]
        end
        per_player.sort_by! { |name, points| [-points, name] }
        match_total = per_player.sum { |_name, points| points }
        cumulative += match_total

        {
          label: label_for_match.call(match),
          points: match_total,
          cumulative: cumulative,
          points_paid: per_player.map { |name, points| "#{name} (#{points})" }.join(", ")
        }
      end
    else
      selected_user = users.find { |u| u.name_or_email == @selected_player }
      cumulative = 0
      @selected_player_rows = ordered_matches.map do |match|
        points = selected_user ? points_by_match_user[[match.id, selected_user.id]].to_i : 0
        cumulative += points
        {
          label: label_for_match.call(match),
          points: points,
          cumulative: cumulative,
          points_paid: "#{@selected_player} (#{points})"
        }
      end
    end
  end
end
