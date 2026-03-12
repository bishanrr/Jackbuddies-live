require "csv"
require "yaml"
require "json"

puts "Seeding JackBuddies..."

TEAM_MASTER = {
  "CSK" => "Chennai Super Kings",
  "MI" => "Mumbai Indians",
  "RCB" => "Royal Challengers Bengaluru",
  "KKR" => "Kolkata Knight Riders",
  "SRH" => "Sunrisers Hyderabad",
  "RR" => "Rajasthan Royals",
  "DC" => "Delhi Capitals",
  "PBKS" => "Punjab Kings",
  "LSG" => "Lucknow Super Giants",
  "GT" => "Gujarat Titans"
}.freeze

ALLOWED_FIRST_NAMES = %w[
  Akhil
  Arun
  Bishan
  Gopi
  Naveen
  Prasad
  Praveen
  Raghu
  Raju
  Sreekanth
  Sunny
  Vishal
].freeze

DEFAULT_POINTS_BY_STAGE = {
  league: 2,
  qualifier: 3,
  eliminator: 3,
  final: 5
}.freeze

IPL_2025_FIXTURES = [
  { home: "KKR", away: "RCB", datetime: "2025-03-22 19:30 +0530" },
  { home: "SRH", away: "RR", datetime: "2025-03-23 15:30 +0530" },
  { home: "CSK", away: "MI", datetime: "2025-03-23 19:30 +0530" },
  { home: "DC", away: "LSG", datetime: "2025-03-24 19:30 +0530" },
  { home: "GT", away: "PBKS", datetime: "2025-03-25 19:30 +0530" },
  { home: "RR", away: "KKR", datetime: "2025-03-26 19:30 +0530" },
  { home: "SRH", away: "LSG", datetime: "2025-03-27 19:30 +0530" },
  { home: "CSK", away: "RCB", datetime: "2025-03-28 19:30 +0530" },
  { home: "GT", away: "MI", datetime: "2025-03-29 19:30 +0530" },
  { home: "DC", away: "SRH", datetime: "2025-03-30 15:30 +0530" },
  { home: "RR", away: "CSK", datetime: "2025-03-30 19:30 +0530" },
  { home: "MI", away: "KKR", datetime: "2025-03-31 19:30 +0530" },
  { home: "LSG", away: "PBKS", datetime: "2025-04-01 19:30 +0530" },
  { home: "RCB", away: "GT", datetime: "2025-04-02 19:30 +0530" },
  { home: "KKR", away: "SRH", datetime: "2025-04-03 19:30 +0530" },
  { home: "LSG", away: "MI", datetime: "2025-04-04 19:30 +0530" },
  { home: "CSK", away: "DC", datetime: "2025-04-05 15:30 +0530" },
  { home: "PBKS", away: "RR", datetime: "2025-04-05 19:30 +0530" },
  { home: "KKR", away: "LSG", datetime: "2025-04-08 15:30 +0530" },
  { home: "SRH", away: "GT", datetime: "2025-04-06 19:30 +0530" },
  { home: "MI", away: "RCB", datetime: "2025-04-07 19:30 +0530" },
  { home: "PBKS", away: "CSK", datetime: "2025-04-08 19:30 +0530" },
  { home: "GT", away: "RR", datetime: "2025-04-09 19:30 +0530" },
  { home: "RCB", away: "DC", datetime: "2025-04-10 19:30 +0530" },
  { home: "CSK", away: "KKR", datetime: "2025-04-11 19:30 +0530" },
  { home: "LSG", away: "GT", datetime: "2025-04-12 15:30 +0530" },
  { home: "SRH", away: "PBKS", datetime: "2025-04-12 19:30 +0530" },
  { home: "RR", away: "RCB", datetime: "2025-04-13 15:30 +0530" },
  { home: "DC", away: "MI", datetime: "2025-04-13 19:30 +0530" },
  { home: "LSG", away: "CSK", datetime: "2025-04-14 19:30 +0530" },
  { home: "PBKS", away: "KKR", datetime: "2025-04-15 19:30 +0530" },
  { home: "DC", away: "RR", datetime: "2025-04-16 19:30 +0530" },
  { home: "MI", away: "SRH", datetime: "2025-04-17 19:30 +0530" },
  { home: "RCB", away: "PBKS", datetime: "2025-04-18 19:30 +0530" },
  { home: "GT", away: "DC", datetime: "2025-04-19 15:30 +0530" },
  { home: "RR", away: "LSG", datetime: "2025-04-19 19:30 +0530" },
  { home: "PBKS", away: "RCB", datetime: "2025-04-20 15:30 +0530" },
  { home: "MI", away: "CSK", datetime: "2025-04-20 19:30 +0530" },
  { home: "KKR", away: "GT", datetime: "2025-04-21 19:30 +0530" },
  { home: "LSG", away: "DC", datetime: "2025-04-22 19:30 +0530" },
  { home: "SRH", away: "MI", datetime: "2025-04-23 19:30 +0530" },
  { home: "RCB", away: "RR", datetime: "2025-04-24 19:30 +0530" },
  { home: "CSK", away: "SRH", datetime: "2025-04-25 19:30 +0530" },
  { home: "KKR", away: "PBKS", datetime: "2025-04-26 19:30 +0530" },
  { home: "MI", away: "LSG", datetime: "2025-04-27 15:30 +0530" },
  { home: "DC", away: "RCB", datetime: "2025-04-27 19:30 +0530" },
  { home: "RR", away: "GT", datetime: "2025-04-28 19:30 +0530" },
  { home: "DC", away: "KKR", datetime: "2025-04-29 19:30 +0530" },
  { home: "CSK", away: "PBKS", datetime: "2025-04-30 19:30 +0530" },
  { home: "RR", away: "MI", datetime: "2025-05-01 19:30 +0530" },
  { home: "GT", away: "SRH", datetime: "2025-05-02 19:30 +0530" },
  { home: "RCB", away: "CSK", datetime: "2025-05-03 19:30 +0530" },
  { home: "KKR", away: "RR", datetime: "2025-05-04 15:30 +0530" },
  { home: "PBKS", away: "LSG", datetime: "2025-05-04 19:30 +0530" },
  { home: "SRH", away: "DC", datetime: "2025-05-05 19:30 +0530" },
  { home: "MI", away: "GT", datetime: "2025-05-06 19:30 +0530" },
  { home: "KKR", away: "CSK", datetime: "2025-05-07 19:30 +0530" },
  { home: "RCB", away: "KKR", datetime: "2025-05-17 19:30 +0530" },
  { home: "RR", away: "PBKS", datetime: "2025-05-18 15:30 +0530" },
  { home: "DC", away: "GT", datetime: "2025-05-18 19:30 +0530" },
  { home: "LSG", away: "SRH", datetime: "2025-05-19 19:30 +0530" },
  { home: "CSK", away: "RR", datetime: "2025-05-20 19:30 +0530" },
  { home: "MI", away: "DC", datetime: "2025-05-21 19:30 +0530" },
  { home: "GT", away: "LSG", datetime: "2025-05-22 19:30 +0530" },
  { home: "RCB", away: "SRH", datetime: "2025-05-23 19:30 +0530" },
  { home: "PBKS", away: "DC", datetime: "2025-05-24 19:30 +0530" },
  { home: "GT", away: "CSK", datetime: "2025-05-25 15:30 +0530" },
  { home: "SRH", away: "KKR", datetime: "2025-05-25 19:30 +0530" },
  { home: "PBKS", away: "MI", datetime: "2025-05-26 19:30 +0530" },
  { home: "LSG", away: "RCB", datetime: "2025-05-27 19:30 +0530" },
  { home: "PBKS", away: "RCB", datetime: "2025-05-29 19:30 +0530", stage: :qualifier },
  { home: "GT", away: "MI", datetime: "2025-05-30 19:30 +0530", stage: :eliminator },
  { home: "PBKS", away: "MI", datetime: "2025-06-01 19:30 +0530", stage: :qualifier },
  { home: "RCB", away: "PBKS", datetime: "2025-06-03 19:30 +0530", stage: :final }
].freeze

def normalize_name_key(name)
  name.to_s.squish.downcase
end

def generated_player_email(name)
  stem = name.to_s.parameterize(separator: "_")
  stem = "player" if stem.blank?
  "#{stem}.player@jackbuddies.local"
end

def admin_name
  ENV.fetch("DEFAULT_ADMIN_NAME", "Bishan")
end

def admin_email
  ENV.fetch("DEFAULT_ADMIN_EMAIL", "bishan@jackbuddies.local").downcase
end

def admin_password
  ENV.fetch("DEFAULT_ADMIN_PASSWORD", "Password123!")
end

def upsert_default_admin!
  admin = User.find_or_initialize_by(email: admin_email)
  admin.assign_attributes(
    display_name: admin_name,
    role: :admin,
    status: :approved,
    approved_at: Time.current
  )
  admin.password = admin_password
  admin.password_confirmation = admin_password
  admin.save!
  admin
end

def upsert_allowed_signup_names!
  ALLOWED_FIRST_NAMES.each do |name|
    AllowedSignupName.find_or_create_by!(first_name: name)
  end
end

def upsert_teams!
  TEAM_MASTER.map do |short_name, name|
    Team.find_or_create_by!(short_name: short_name) do |team|
      team.name = name
    end
  end.index_by(&:short_name)
end

def upsert_season!(year)
  season = Season.find_or_initialize_by(year: year)
  season.name = "IPL #{year}"
  season.default_lock_minutes = 10
  season.save!

  DEFAULT_POINTS_BY_STAGE.each do |stage, points|
    rule = season.points_rules.find_or_initialize_by(stage: stage)
    rule.points_for_correct = points
    rule.save!
  end

  season
end

def parse_js_matches(path)
  raw = path.read
  js_text = raw.sub(/\A\s*const\s+matches\s*=\s*/m, "").sub(/;\s*\z/m, "").strip
  json_text = js_text.gsub(/([{,]\s*)([A-Za-z_]\w*)\s*:/, '\1"\2":')
  JSON.parse(json_text)
end

def winner_row_match_no(value)
  label = value.to_s.strip.upcase
  return label.to_i if label.match?(/\A\d+\z/)

  case label
  when "Q1" then 71
  when "ELIMINATOR" then 72
  when "Q2" then 73
  when "FINAL" then 74
  end
end

def seed_users!(player_names, admin_record)
  player_names.each_with_object({}) do |name, acc|
    email = normalize_name_key(name) == normalize_name_key(admin_record.display_name) ? admin_record.email : generated_player_email(name)
    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(
      display_name: name,
      role: email == admin_record.email ? :admin : (user.role.presence || :user),
      status: :approved,
      approved_at: Time.current
    )
    if user.new_record?
      user.password = admin_password
      user.password_confirmation = admin_password
    end
    user.save!
    acc[normalize_name_key(name)] = user
  end
end

def load_2024_points(path)
  current_player = nil
  payload = {}

  path.each_line do |line|
    text = line.strip
    next if text.blank?

    if text.match?(/\AMatches \d+-\d+:/)
      range_text, values_text = text.split(":", 2)
      start_match, finish_match = range_text.scan(/\d+/).map(&:to_i)
      values = values_text.split(",").map { |value| value.to_i }
      payload[current_player] ||= Array.new(74, 0)
      values.each_with_index do |points, idx|
        payload[current_player][start_match - 1 + idx] = points
      end
    elsif text.start_with?("Playoffs:")
      values = text.scan(/\(([-\d]+)\)/).flatten.map(&:to_i)
      payload[current_player] ||= Array.new(74, 0)
      values.each_with_index do |points, idx|
        payload[current_player][70 + idx] = points
      end
    else
      current_player = text
      payload[current_player] ||= Array.new(74, 0)
    end
  end

  payload
end

def load_2025_points(path)
  (YAML.safe_load_file(path) || {}).transform_values do |player_payload|
    Array(player_payload["league_segments"]).flatten.map(&:to_i) +
      %w[Q1 ELIMINATOR Q2 FINAL].map { |label| player_payload.dig("knockouts", label).to_i }
  end
end

def upsert_matches!(season:, rows:)
  Match.upsert_all(rows, unique_by: :index_matches_on_season_id_and_match_no)
  season.matches.where(match_no: rows.map { |row| row[:match_no] }).index_by(&:match_no)
end

def upsert_points_events!(season:, users_by_name:, matches_by_no:, points_by_name:, source:)
  now = Time.current
  rows = points_by_name.flat_map do |player_name, points|
    user = users_by_name.fetch(normalize_name_key(player_name))

    points.each_with_index.filter_map do |value, idx|
      match_no = idx + 1
      match = matches_by_no[match_no]
      next unless match

      {
        user_id: user.id,
        season_id: season.id,
        match_id: match.id,
        points: value.to_i,
        reason: PointsEvent::IMPORT_REASON,
        event_type: PointsEvent.event_types.fetch("match_result"),
        metadata: {
          source: source,
          season_year: season.year,
          match_no: match_no
        },
        created_at: now,
        updated_at: now
      }
    end
  end

  PointsEvent.upsert_all(rows, unique_by: :index_points_events_on_import_user_match) if rows.any?
end

def upsert_picks!(users_by_name:, matches_by_no:, winner_rows:, loser_team_by_match_no:)
  now = Time.current
  rows = winner_rows.flat_map do |row|
    match_no = winner_row_match_no(row.fetch("matchNo"))
    match = matches_by_no[match_no]
    loser_team_code = loser_team_by_match_no[match_no]
    next [] unless match && match.winner_team_id.present? && loser_team_code.present?

    winner_names = Array(row["usersWon"]).map { |name| normalize_name_key(name) }
    losing_team_id =
      if match.home_team.short_name == loser_team_code
        match.home_team_id
      elsif match.away_team.short_name == loser_team_code
        match.away_team_id
      end
    next [] unless losing_team_id

    users_by_name.values.map do |user|
      {
        user_id: user.id,
        match_id: match.id,
        team_id: winner_names.include?(normalize_name_key(user.display_name)) ? match.winner_team_id : losing_team_id,
        created_at: now,
        updated_at: now
      }
    end
  end

  Pick.upsert_all(rows, unique_by: :index_picks_on_user_id_and_match_id) if rows.any?
end

def seed_2024!(admin_record, teams_by_code)
  season = upsert_season!(2024)
  points_by_name = load_2024_points(Rails.root.join("data/ipl_2024_points.txt"))
  users_by_name = seed_users!(points_by_name.keys, admin_record)
  match_rows = CSV.read(Rails.root.join("data/ipl_2024_matches.csv"), headers: true).map(&:to_h)
  winners_by_match_no = CSV.read(Rails.root.join("data/ipl_2024_winners.csv"), headers: true).each_with_object({}) do |row, acc|
    acc[row["match_no"].to_i] = row["winner_team"].to_s
  end

  rows = match_rows.map do |row|
    match_no = row.fetch("match_no").to_i
    home_team = teams_by_code.fetch(row.fetch("team_a"))
    away_team = teams_by_code.fetch(row.fetch("team_b"))
    winner_name = winners_by_match_no[match_no]
    winner_team =
      case winner_name
      when "", nil, "Abandoned"
        nil
      else
        Team.find_by!(name: winner_name)
      end

    {
      season_id: season.id,
      match_no: match_no,
      match_datetime: Time.zone.parse("#{row.fetch("match_date")} 19:30"),
      stage: case row.fetch("stage").downcase
             when /qualifier/
               Match.stages.fetch("qualifier")
             when /eliminator/
               Match.stages.fetch("eliminator")
             when /final/
               Match.stages.fetch("final")
             else
               Match.stages.fetch("league")
             end,
      status: winner_name == "Abandoned" ? Match.statuses.fetch("cancelled") : Match.statuses.fetch("completed"),
      home_team_id: home_team.id,
      away_team_id: away_team.id,
      winner_team_id: winner_team&.id,
      title: "#{home_team.short_name} vs #{away_team.short_name}",
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  matches_by_no = upsert_matches!(season: season, rows: rows)
  winner_rows = parse_js_matches(Rails.root.join("config/ipl_2024_match_winners.js"))
  loser_team_by_match_no = match_rows.each_with_object({}) do |row, acc|
    match_no = row.fetch("match_no").to_i
    winner_name = winners_by_match_no[match_no]
    next if winner_name.blank? || winner_name == "Abandoned"

    acc[match_no] = Team.find_by!(name: winner_name).short_name == row.fetch("team_a") ? row.fetch("team_b") : row.fetch("team_a")
  end

  upsert_picks!(users_by_name: users_by_name, matches_by_no: matches_by_no, winner_rows: winner_rows, loser_team_by_match_no: loser_team_by_match_no)
  upsert_points_events!(season: season, users_by_name: users_by_name, matches_by_no: matches_by_no, points_by_name: points_by_name, source: "ipl_2024_points_text")
end

def seed_2025!(admin_record, teams_by_code)
  season = upsert_season!(2025)
  season.matches.where(match_no: nil).find_each(&:destroy!)
  points_by_name = load_2025_points(Rails.root.join("config/ipl_2025_player_points.yml"))
  users_by_name = seed_users!(points_by_name.keys, admin_record)
  winner_rows = parse_js_matches(Rails.root.join("config/ipl_2025_match_winners.js"))
  winners_by_match_no = winner_rows.each_with_object({}) do |row, acc|
    match_no = winner_row_match_no(row.fetch("matchNo"))
    acc[match_no] = row if match_no
  end

  rows = IPL_2025_FIXTURES.each_with_index.map do |fixture, idx|
    match_no = idx + 1
    result = winners_by_match_no[match_no] || {}
    home_team = teams_by_code.fetch(fixture.fetch(:home))
    away_team = teams_by_code.fetch(fixture.fetch(:away))
    winner_team_code = result["winnerTeam"].presence
    winner_team = winner_team_code.present? ? teams_by_code.fetch(winner_team_code) : nil

    {
      season_id: season.id,
      match_no: match_no,
      match_datetime: Time.zone.parse(fixture.fetch(:datetime)),
      stage: Match.stages.fetch((fixture[:stage] || :league).to_s),
      status: winner_team.present? ? Match.statuses.fetch("completed") : Match.statuses.fetch("scheduled"),
      home_team_id: home_team.id,
      away_team_id: away_team.id,
      winner_team_id: winner_team&.id,
      title: "#{home_team.short_name} vs #{away_team.short_name}",
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  matches_by_no = upsert_matches!(season: season, rows: rows)
  loser_team_by_match_no = winner_rows.each_with_object({}) do |row, acc|
    match_no = winner_row_match_no(row.fetch("matchNo"))
    acc[match_no] = row["loserTeam"].presence if match_no
  end

  upsert_picks!(users_by_name: users_by_name, matches_by_no: matches_by_no, winner_rows: winner_rows, loser_team_by_match_no: loser_team_by_match_no)
  upsert_points_events!(season: season, users_by_name: users_by_name, matches_by_no: matches_by_no, points_by_name: points_by_name, source: "ipl_2025_player_points_yml")
end

def seed_2026!
  upsert_season!(2026)
end

admin_record = upsert_default_admin!
upsert_allowed_signup_names!
teams_by_code = upsert_teams!
seed_2024!(admin_record, teams_by_code)
seed_2025!(admin_record, teams_by_code)
seed_2026!

puts "Seed complete."
