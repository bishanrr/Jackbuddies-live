namespace :data do
  desc "Import IPL 2025 historical data from CSV files in Rails.root/data"
  task import_ipl_2025: :environment do
    result = Imports::Ipl2025Importer.new.call

    puts "Import complete."
    puts "Counts: #{result.summary}"
    puts "Top totals:"
    result.season_totals.first(10).each_with_index do |row, idx|
      puts format("%2d. %-24s %d", idx + 1, row[:user_name], row[:points])
    end
  end

  desc "Import IPL 2024 schedule from data/ipl_2024_matches.csv"
  task import_ipl_2024_schedule: :environment do
    require "csv"
    require "set"

    path = Rails.root.join("data/ipl_2024_matches.csv")
    raise "Missing CSV: #{path}" unless path.exist?

    season = Season.find_or_create_by!(year: 2024) { |s| s.name = "IPL 2024" }
    season.update!(name: "IPL 2024")

    team_aliases = {
      "PK" => "PBKS"
    }

    team_codes = Set.new
    rows = CSV.read(path, headers: true).map(&:to_h).select { |row| row["season_year"].to_i == 2024 }

    rows.each do |row|
      team_codes << team_aliases.fetch(row["team_a"].to_s.strip.upcase, row["team_a"].to_s.strip.upcase)
      team_codes << team_aliases.fetch(row["team_b"].to_s.strip.upcase, row["team_b"].to_s.strip.upcase)
    end

    teams = Team.where(short_name: team_codes.to_a).index_by(&:short_name)
    missing = team_codes.reject { |code| teams.key?(code) }
    raise "Missing teams: #{missing.to_a.sort.join(', ')}" if missing.any?

    existing_by_match_no = season.matches.where(match_no: rows.map { |row| row["match_no"].to_i }).index_by(&:match_no)

    payload = rows.map do |row|
      team_a = team_aliases.fetch(row["team_a"].to_s.strip.upcase, row["team_a"].to_s.strip.upcase)
      team_b = team_aliases.fetch(row["team_b"].to_s.strip.upcase, row["team_b"].to_s.strip.upcase)
      date = Date.parse(row.fetch("match_date"))
      match_time = Time.zone.local(date.year, date.month, date.day, 19, 30, 0)
      existing = existing_by_match_no[row.fetch("match_no").to_i]
      status =
        if existing&.status.in?(%w[completed cancelled])
          Match.statuses.fetch(existing.status)
        else
          match_time < Time.current ? Match.statuses.fetch("completed") : Match.statuses.fetch("scheduled")
        end
      stage_text = row["stage"].to_s.strip.upcase
      stage =
        if stage_text.include?("QUALIFIER")
          Match.stages.fetch("qualifier")
        elsif stage_text.include?("ELIMINATOR")
          Match.stages.fetch("eliminator")
        elsif stage_text.include?("FINAL")
          Match.stages.fetch("final")
        else
          Match.stages.fetch("league")
        end

      {
        season_id: season.id,
        match_no: row.fetch("match_no").to_i,
        match_datetime: match_time,
        stage: stage,
        status: status,
        home_team_id: teams.fetch(team_a).id,
        away_team_id: teams.fetch(team_b).id,
        winner_team_id: existing&.winner_team_id,
        title: "#{team_a} vs #{team_b}",
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    existing_match_nos = season.matches.where(match_no: payload.map { |row| row[:match_no] }).pluck(:match_no).to_set
    Match.upsert_all(payload, unique_by: :index_matches_on_season_id_and_match_no)

    created = payload.count { |row| !existing_match_nos.include?(row[:match_no]) }
    puts "Import complete."
    puts "Season: #{season.year}"
    puts "Matches upserted: #{payload.size}"
    puts "Matches created: #{created}"
  end

  desc "Import IPL 2024 match winners from data/ipl_2024_winners.csv"
  task import_ipl_2024_winners: :environment do
    require "csv"

    path = Rails.root.join("data/ipl_2024_winners.csv")
    raise "Missing CSV: #{path}" unless path.exist?

    season = Season.find_by!(year: 2024)
    team_aliases = {
      "CHENNAI SUPER KINGS" => "CSK",
      "MUMBAI INDIANS" => "MI",
      "ROYAL CHALLENGERS BENGALURU" => "RCB",
      "ROYAL CHALLENGERS BANGALORE" => "RCB",
      "KOLKATA KNIGHT RIDERS" => "KKR",
      "SUNRISERS HYDERABAD" => "SRH",
      "RAJASTHAN ROYALS" => "RR",
      "DELHI CAPITALS" => "DC",
      "PUNJAB KINGS" => "PBKS",
      "LUCKNOW SUPER GIANTS" => "LSG",
      "GUJARAT TITANS" => "GT"
    }

    team_by_code = Team.where(short_name: team_aliases.values.uniq).index_by(&:short_name)
    rows = CSV.read(path, headers: true).map(&:to_h)
    updated = 0

    rows.each do |row|
      match_no = row.fetch("match_no").to_i
      raw_winner = row.fetch("winner_team").to_s.strip
      match = season.matches.find_by!(match_no: match_no)

      if raw_winner.casecmp("abandoned").zero?
        match.update!(winner_team_id: nil, status: :cancelled)
      else
        code = team_aliases.fetch(raw_winner.upcase) { raise "Unknown team: #{raw_winner}" }
        winner = team_by_code.fetch(code)
        match.update!(winner_team_id: winner.id, status: :completed)
      end

      updated += 1
    end

    puts "Import complete."
    puts "Season: 2024"
    puts "Winners rows processed: #{updated}"
    puts "Completed: #{season.matches.completed.count}, Cancelled: #{season.matches.cancelled.count}"
  end

  desc "Import IPL 2024 acquired points from data/ipl_2024_points.txt"
  task import_ipl_2024_points: :environment do
    require "securerandom"

    path = Rails.root.join("data/ipl_2024_points.txt")
    raise "Missing points file: #{path}" unless path.exist?

    season = Season.find_by!(year: 2024)
    matches_by_no = season.matches.where(match_no: 1..74).index_by(&:match_no)
    missing_match_nos = (1..74).reject { |no| matches_by_no.key?(no) }
    raise "Missing matches for season 2024: #{missing_match_nos.join(', ')}" if missing_match_nos.any?

    data = {}
    current_name = nil

    path.read.each_line do |raw_line|
      line = raw_line.to_s.strip
      next if line.blank?

      line = line.sub(/\A[•*-]\s*/, "")

      if line.match?(/\A[A-Za-z][A-Za-z ]+\z/) && !line.start_with?("Matches", "Playoffs")
        current_name = line.strip
        data[current_name] ||= { match_points: [], playoffs: {} }
        next
      end

      raise "Malformed file. Found data before player name: #{line}" if current_name.blank?

      if (match_line = line.match(/\AMatches\s+\d+\s*[-–]\s*\d+:\s*(.+)\z/i))
        values = match_line[1].split(",").map { |v| Integer(v.strip, 10) }
        raise "Expected 10 values for #{current_name}, got #{values.size}" unless values.size == 10

        data[current_name][:match_points].concat(values)
        next
      end

      if (playoff_line = line.match(/\APlayoffs:\s*(.+)\z/i))
        playoffs = {}
        playoff_line[1].scan(/(Q1|Eliminator|Q2|Final)\s*\((\d+)\)/i) do |label, points|
          playoffs[label.upcase] = points.to_i
        end
        data[current_name][:playoffs] = playoffs
      end
    end

    required_playoff_labels = %w[Q1 ELIMINATOR Q2 FINAL]

    data.each do |name, payload|
      unless payload[:match_points].size == 70
        raise "Player #{name} has #{payload[:match_points].size} match points; expected 70"
      end

      missing_labels = required_playoff_labels - payload[:playoffs].keys
      raise "Player #{name} missing playoff labels: #{missing_labels.join(', ')}" if missing_labels.any?
    end

    existing_users = User.all.index_by { |u| u.display_name.to_s.downcase.gsub(/\s+/, "") }
    users_by_name = {}

    data.keys.each do |name|
      normalized = name.downcase.gsub(/\s+/, "")
      user = existing_users[normalized]

      unless user
        email = "#{name.parameterize(separator: '_')}@import.local"
        user = User.find_by(email: email)
      end

      unless user
        user = User.create!(
          email: "#{name.parameterize(separator: '_')}@import.local",
          password: SecureRandom.hex(12),
          display_name: name,
          role: :user,
          status: :approved,
          approved_at: Time.current
        )
      end

      user.update!(display_name: name, status: :approved, approved_at: user.approved_at || Time.current)
      users_by_name[name] = user
    end

    import_reason = "import_2024_acquired"
    playoff_reason = "ipl_2024_playoffs_import"
    now = Time.current
    match_rows = []

    PointsEvent.where(season_id: season.id, reason: [import_reason, playoff_reason]).delete_all

    data.each do |name, payload|
      user = users_by_name.fetch(name)
      payload[:match_points].each_with_index do |points, idx|
        match_no = idx + 1
        match = matches_by_no.fetch(match_no)
        match_rows << {
          user_id: user.id,
          season_id: season.id,
          match_id: match.id,
          points: points.to_i,
          reason: import_reason,
          event_type: PointsEvent.event_types.fetch("match_result"),
          metadata: { source: "ipl_2024_points_text", season_year: 2024, match_no: match_no },
          created_at: now,
          updated_at: now
        }
      end

      playoff_match_no_by_label = { "Q1" => 71, "ELIMINATOR" => 72, "Q2" => 73, "FINAL" => 74 }
      payload[:playoffs].each do |label, points|
        match_no = playoff_match_no_by_label.fetch(label)
        match = matches_by_no.fetch(match_no)
        match_rows << {
          user_id: user.id,
          season_id: season.id,
          match_id: match.id,
          points: points.to_i,
          reason: import_reason,
          event_type: PointsEvent.event_types.fetch("match_result"),
          metadata: { source: "ipl_2024_points_text", season_year: 2024, match_no: match_no, playoff_label: label },
          created_at: now,
          updated_at: now
        }
      end
    end

    PointsEvent.insert_all(match_rows) if match_rows.any?

    puts "Import complete."
    puts "Players imported: #{data.size}"
    puts "Match point rows inserted: #{match_rows.size}"
    puts "Playoff adjustment rows inserted: 0 (mapped to matches 71-74)"
  end
end
