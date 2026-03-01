require "yaml"
require "json"

class LeaderboardQuery
  Row = Struct.new(:rank, :user, :points, :correct_picks, :completed_picks, :accuracy, keyword_init: true)

  def self.call(season)
    new(season).call
  end

  def initialize(season)
    @season = season
  end

  def call
    points_data = season_2025_points_data
    winners_rows = season_winners_rows
    winners_total_matches = winners_rows.size
    winners_by_user = winners_by_user_name(winners_rows)
    player_wins_data = season_player_wins_data
    wins_from_data_by_user = wins_count_by_user_name_from_data(player_wins_data)

    rows = User.approved.map do |user|
      if wins_from_data_by_user.present?
        correct_count = wins_from_data_by_user[normalize_name(user_name_key(user))].to_i
        completed_count = season.matches.completed.count
      elsif season&.year == 2025 && winners_total_matches.positive?
        correct_count = winners_by_user[normalize_name(user_name_key(user))].to_i
        completed_count = winners_total_matches
      else
        picks_scope = user.picks.joins(:match).where(matches: { season_id: season.id })
        completed_scope = picks_scope.where(matches: { status: Match.statuses[:completed] })
        completed_count = completed_scope.count
        correct_count = completed_scope.where("picks.team_id = matches.winner_team_id").count
      end

      points =
        if points_data
          total_points_for_user_from_file(user, points_data)
        else
          user.points_events.active.where(season: season).sum(:points)
        end
      accuracy = completed_count.positive? ? ((correct_count.to_f / completed_count) * 100).round(1) : 0.0

      Row.new(
        user: user,
        points: points,
        correct_picks: correct_count,
        completed_picks: completed_count,
        accuracy: accuracy
      )
    end

    ranked = rows.sort_by { |row| [-row.points, -row.accuracy, row.user.name_or_email.downcase] }
    ranked.each_with_index.map { |row, idx| row.tap { |r| r.rank = idx + 1 } }
  end

  private

  attr_reader :season

  def season_2025_points_data
    return nil unless season&.year == 2025

    path = Rails.root.join("config/ipl_2025_player_points.yml")
    return nil unless path.exist?

    YAML.safe_load_file(path) || {}
  end

  def season_winners_rows
    return [] unless season&.year.present?

    path = Rails.root.join("config/ipl_#{season.year}_match_winners.js")
    return [] unless path.exist?

    raw = path.read
    js_text = raw.sub(/\A\s*const\s+matches\s*=\s*/m, "").sub(/;\s*\z/m, "").strip
    json_text = js_text.gsub(/([{,]\s*)([A-Za-z_]\w*)\s*:/, '\1"\2":')
    rows = JSON.parse(json_text)
    rows.select { |row| row.is_a?(Hash) && row["matchNo"].present? }
  rescue JSON::ParserError
    []
  end

  def season_player_wins_data
    return {} unless season&.year.present?

    path = Rails.root.join("config/ipl_#{season.year}_player_wins.yml")
    return {} unless path.exist?

    YAML.safe_load_file(path) || {}
  end

  def wins_count_by_user_name_from_data(data)
    return {} if data.blank?

    data.each_with_object({}) do |(name, payload), acc|
      league = Array(payload["league_matches"] || payload[:league_matches]).map(&:to_i)
      playoffs = Array(payload["playoffs"] || payload[:playoffs]).map(&:to_s)
      acc[normalize_name(name)] = league.size + playoffs.size
    end
  end

  def winners_by_user_name(rows)
    counts = Hash.new(0)

    rows.each do |row|
      Array(row["usersWon"]).each do |name|
        normalized = normalize_name(name)
        counts[normalized] += 1 if normalized.present?
      end
    end

    counts
  end

  def total_points_for_user_from_file(user, points_data)
    normalized_data = points_data.transform_keys { |name| normalize_name(name) }
    payload = normalized_data[normalize_name(user_name_key(user))]
    return 0 unless payload

    league_total = Array(payload["league_segments"]).flatten.map(&:to_i).sum
    knockout_total = %w[Q1 ELIMINATOR Q2 FINAL].sum { |label| payload.dig("knockouts", label).to_i }
    league_total + knockout_total
  end

  def user_name_key(user)
    (user.display_name.presence || user.name_or_email).to_s.strip
  end

  def normalize_name(name)
    name.to_s.downcase.gsub(/\s+/, "")
  end
end
