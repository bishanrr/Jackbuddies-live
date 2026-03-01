require "csv"
require "set"

module Imports
  class Ipl2025Importer
    # Sample CSV rows:
    # data/ipl_2025_matches.csv
    # season_year,match_no,match_date,team_a,team_b,stage,winner_team,loser_team
    # 2025,1,2025-03-22,KKR,RCB,LEAGUE,RCB,KKR
    #
    # data/ipl_2025_users.csv
    # name,email
    # Bishan,bishan@example.com
    #
    # data/ipl_2025_user_points.csv
    # season_year,match_no,user_name,points
    # 2025,1,Bishan,200
    #
    # data/ipl_2025_team_stats.csv (optional)
    # season_year,team,played,wins,losses
    # 2025,RCB,14,9,5

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

    TEAM_ALIASES = {
      "CHENNAI SUPER KINGS" => "CSK",
      "CSK" => "CSK",
      "MUMBAI INDIANS" => "MI",
      "MI" => "MI",
      "ROYAL CHALLENGERS BENGALURU" => "RCB",
      "ROYAL CHALLENGERS BANGALORE" => "RCB",
      "RCB" => "RCB",
      "KOLKATA KNIGHT RIDERS" => "KKR",
      "KKR" => "KKR",
      "SUNRISERS HYDERABAD" => "SRH",
      "SRH" => "SRH",
      "RAJASTHAN ROYALS" => "RR",
      "RR" => "RR",
      "DELHI CAPITALS" => "DC",
      "DC" => "DC",
      "PUNJAB KINGS" => "PBKS",
      "PBKS" => "PBKS",
      "PK" => "PBKS",
      "KXIP" => "PBKS",
      "LUCKNOW SUPER GIANTS" => "LSG",
      "LSG" => "LSG",
      "GUJARAT TITANS" => "GT",
      "GT" => "GT"
    }.freeze

    Result = Struct.new(:counts, :season_totals, keyword_init: true) do
      def summary
        counts.map { |k, v| "#{k}=#{v}" }.join(", ")
      end
    end

    def initialize(data_dir: Rails.root.join("data"), logger: Rails.logger)
      @data_dir = Pathname(data_dir)
      @logger = logger
      @counts = Hash.new(0)
    end

    def call
      ActiveRecord::Base.transaction do
        season = upsert_season!(2025)
        match_rows = read_csv!("ipl_2025_matches.csv").select { |row| row["season_year"].to_i == season.year }
        user_rows = read_csv!("ipl_2025_users.csv")
        points_rows = read_csv!("ipl_2025_user_points.csv").select { |row| row["season_year"].to_i == season.year }

        team_lookup = upsert_teams!(match_rows, optional_team_stat_rows)
        match_lookup = upsert_matches!(season, match_rows, team_lookup)
        user_lookup = upsert_users!(user_rows, points_rows)
        upsert_points_events!(season, points_rows, match_lookup, user_lookup)
        upsert_team_stats!(season, team_lookup)

        totals = season_user_totals(season)
        logger.info("IPL 2025 import complete: #{counts.inspect}")
        Result.new(counts: counts.dup, season_totals: totals)
      end
    end

    private

    attr_reader :data_dir, :logger, :counts

    def optional_team_stat_rows
      @optional_team_stat_rows ||= begin
        path = data_dir.join("ipl_2025_team_stats.csv")
        path.exist? ? read_csv!("ipl_2025_team_stats.csv") : []
      end
    end

    def read_csv!(file_name)
      path = data_dir.join(file_name)
      raise ArgumentError, "Missing CSV: #{path}" unless path.exist?

      CSV.read(path, headers: true).map(&:to_h)
    end

    def upsert_season!(year)
      season = Season.find_or_initialize_by(year: year)
      counts[:seasons_created] += 1 if season.new_record?
      counts[:seasons_updated] += 1 unless season.new_record?
      season.update!(name: "IPL #{year}")
      season
    end

    def upsert_teams!(match_rows, team_stat_rows)
      codes = Set.new

      match_rows.each do |row|
        codes << normalize_team_code!(row["team_a"])
        codes << normalize_team_code!(row["team_b"])
        codes << normalize_team_code!(row["winner_team"]) if row["winner_team"].present?
        codes << normalize_team_code!(row["loser_team"]) if row["loser_team"].present?
      end

      team_stat_rows.each do |row|
        codes << normalize_team_code!(row["team"])
      end

      team_codes = codes.to_a
      existing = Team.where(short_name: team_codes).index_by(&:short_name)

      rows = team_codes.map do |code|
        {
          short_name: code,
          name: TEAM_MASTER.fetch(code),
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      Team.upsert_all(rows, unique_by: :index_teams_on_short_name) if rows.any?

      counts[:teams_created] += team_codes.count { |code| !existing.key?(code) }
      counts[:teams_upserted] += team_codes.size

      Team.where(short_name: team_codes).index_by(&:short_name)
    end

    def upsert_matches!(season, match_rows, team_lookup)
      existing_keys = season.matches.where(match_no: match_rows.map { |row| row["match_no"].to_i }).pluck(:match_no).to_set

      rows = match_rows.map do |row|
        match_no = row.fetch("match_no").to_i
        team_a_code = normalize_team_code!(row.fetch("team_a"))
        team_b_code = normalize_team_code!(row.fetch("team_b"))
        winner_code = row["winner_team"].presence && normalize_team_code!(row["winner_team"])

        {
          season_id: season.id,
          match_no: match_no,
          match_datetime: normalize_match_datetime(row.fetch("match_date")),
          stage: normalize_stage(row["stage"]),
          home_team_id: team_lookup.fetch(team_a_code).id,
          away_team_id: team_lookup.fetch(team_b_code).id,
          winner_team_id: winner_code.present? ? team_lookup.fetch(winner_code).id : nil,
          status: winner_code.present? ? Match.statuses.fetch("completed") : Match.statuses.fetch("scheduled"),
          title: "#{team_a_code} vs #{team_b_code}",
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      Match.upsert_all(rows, unique_by: :index_matches_on_season_id_and_match_no) if rows.any?

      counts[:matches_created] += rows.count { |row| !existing_keys.include?(row[:match_no]) }
      counts[:matches_upserted] += rows.size

      season.matches.where(match_no: rows.map { |row| row[:match_no] }).index_by(&:match_no)
    end

    def upsert_users!(user_rows, points_rows)
      now = Time.current
      user_rows_by_name = user_rows.index_by { |row| normalize_name_key(row["name"]) }
      point_user_names = points_rows.map { |row| row["user_name"] }.compact.map { |name| normalize_name_key(name) }.uniq

      normalized_users = point_user_names.map do |name_key|
        base = user_rows_by_name[name_key] || {}
        raw_name = base["name"].presence || points_rows.find { |row| normalize_name_key(row["user_name"]) == name_key }&.fetch("user_name")
        email = base["email"].presence || generated_email(raw_name)
        { name: raw_name.to_s.strip, email: email.to_s.strip.downcase }
      end

      existing = User.where(email: normalized_users.map { |u| u[:email] }).index_by(&:email)

      rows = normalized_users.map do |attrs|
        existing_user = existing[attrs[:email]]
        role_value = existing_user&.admin? ? User.roles.fetch("admin") : User.roles.fetch("user")
        {
          email: attrs[:email],
          display_name: attrs[:name],
          role: role_value,
          status: User.statuses.fetch("approved"),
          approved_at: now,
          created_at: now,
          updated_at: now
        }
      end

      User.upsert_all(rows, unique_by: :index_users_on_email) if rows.any?

      counts[:users_created] += rows.count { |row| !existing.key?(row[:email]) }
      counts[:users_upserted] += rows.size

      reloaded = User.where(email: rows.map { |row| row[:email] })
      by_name = {}
      reloaded.each do |user|
        by_name[normalize_name_key(user.display_name)] ||= user
      end
      by_name
    end

    def upsert_points_events!(season, points_rows, match_lookup, user_lookup)
      now = Time.current
      existing_keys = PointsEvent.where(reason: PointsEvent::IMPORT_REASON, match_id: match_lookup.values.map(&:id), user_id: user_lookup.values.map(&:id))
        .pluck(:user_id, :match_id)
        .to_set

      rows = points_rows.map do |row|
        match_no = row.fetch("match_no").to_i
        match = match_lookup.fetch(match_no) do
          raise ArgumentError, "No match found for season=#{season.year} match_no=#{match_no}"
        end

        user = user_lookup[normalize_name_key(row.fetch("user_name"))]
        raise ArgumentError, "No user found for user_name=#{row.fetch("user_name")}" unless user

        {
          user_id: user.id,
          season_id: season.id,
          match_id: match.id,
          points: row.fetch("points").to_i,
          reason: PointsEvent::IMPORT_REASON,
          event_type: PointsEvent.event_types.fetch("match_result"),
          metadata: {
            source: "ipl_2025_csv",
            season_year: season.year,
            match_no: match_no
          },
          created_at: now,
          updated_at: now
        }
      end

      PointsEvent.upsert_all(rows, unique_by: :index_points_events_on_import_user_match) if rows.any?

      counts[:points_events_created] += rows.count { |row| !existing_keys.include?([row[:user_id], row[:match_id]]) }
      counts[:points_events_upserted] += rows.size
    end

    def upsert_team_stats!(season, team_lookup)
      rows = optional_team_stat_rows
      return if rows.blank?

      existing_keys = TeamSeasonStat.where(season_id: season.id).pluck(:team_id).to_set
      now = Time.current
      payload = rows.map do |row|
        team_code = normalize_team_code!(row.fetch("team"))
        team = team_lookup.fetch(team_code)
        {
          season_id: season.id,
          team_id: team.id,
          played: row.fetch("played").to_i,
          wins: row.fetch("wins").to_i,
          losses: row.fetch("losses").to_i,
          created_at: now,
          updated_at: now
        }
      end

      TeamSeasonStat.upsert_all(payload, unique_by: :index_team_season_stats_on_season_id_and_team_id)

      counts[:team_stats_created] += payload.count { |row| !existing_keys.include?(row[:team_id]) }
      counts[:team_stats_upserted] += payload.size
    end

    def season_user_totals(season)
      points_by_user_id = PointsEvent.active.where(season_id: season.id).group(:user_id).sum(:points)
      users = User.where(id: points_by_user_id.keys).index_by(&:id)
      points_by_user_id.map do |user_id, points|
        { user_name: users[user_id]&.name_or_email, points: points }
      end.sort_by { |row| -row[:points] }
    end

    def generated_email(name)
      base = name.to_s.parameterize(separator: "_")
      base = "import_user" if base.blank?
      "#{base}@import.local"
    end

    def normalize_name_key(name)
      name.to_s.squish.downcase
    end

    def normalize_match_datetime(raw)
      value = raw.to_s.strip
      parsed = Time.zone.parse(value)
      return parsed if parsed

      date = Date.parse(value)
      Time.zone.local(date.year, date.month, date.day, 19, 30, 0)
    rescue ArgumentError
      raise ArgumentError, "Invalid match_date: #{raw.inspect}"
    end

    def normalize_stage(raw_stage)
      key = raw_stage.to_s.strip.downcase
      return Match.stages.fetch("league") if key.blank? || key == "league"

      return Match.stages.fetch("qualifier") if key.include?("qualifier")
      return Match.stages.fetch("eliminator") if key.include?("eliminator")
      return Match.stages.fetch("final") if key.include?("final")

      Match.stages.fetch("league")
    end

    def normalize_team_code!(raw_name)
      normalized = raw_name.to_s.upcase.gsub(/[^A-Z0-9 ]/, " ").squish
      code = TEAM_ALIASES[normalized]
      raise ArgumentError, "Unknown team alias: #{raw_name.inspect}" unless code

      code
    end
  end
end
