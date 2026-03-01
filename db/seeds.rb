puts "Seeding JackBuddies..."

admin = User.find_or_initialize_by(email: "bishan@jackbuddies.local")
admin.assign_attributes(
  password: "Password123!",
  password_confirmation: "Password123!",
  display_name: "Bishan",
  role: :admin,
  status: :approved,
  approved_at: Time.current
)
admin.save!

allowed_first_names = %w[
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
]

allowed_first_names.each do |name|
  AllowedSignupName.find_or_create_by!(first_name: name)
end

allowed_first_names.each do |name|
  user = User.find_or_initialize_by(email: "#{name.downcase}.player@jackbuddies.local")
  user.assign_attributes(
    display_name: name,
    role: :user,
    status: :approved,
    approved_at: Time.current
  )

  if user.new_record?
    user.password = "Password123!"
    user.password_confirmation = "Password123!"
  end

  user.save!
end

teams = [
  ["Chennai Super Kings", "CSK"],
  ["Mumbai Indians", "MI"],
  ["Royal Challengers Bengaluru", "RCB"],
  ["Kolkata Knight Riders", "KKR"],
  ["Sunrisers Hyderabad", "SRH"],
  ["Rajasthan Royals", "RR"],
  ["Delhi Capitals", "DC"],
  ["Punjab Kings", "PBKS"],
  ["Lucknow Super Giants", "LSG"],
  ["Gujarat Titans", "GT"]
].map do |name, short|
  Team.find_or_create_by!(name: name) { |team| team.short_name = short }
end

ipl_2025_fixtures = [
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
]

[2025, 2026].each do |year|
  season = Season.find_or_create_by!(year: year) do |s|
    s.name = "IPL #{year}"
    s.default_lock_minutes = 10
  end

  {
    league: 2,
    qualifier: 3,
    eliminator: 3,
    final: 5
  }.each do |stage, points|
    rule = season.points_rules.find_or_initialize_by(stage: stage)
    rule.points_for_correct = points
    rule.save!
  end

  sample_matches =
    if year == 2025
      season.points_events.delete_all
      season.matches.destroy_all
      ipl_2025_fixtures.map { |fixture| fixture.merge(completed: true, status: :completed) }
    else
      []
    end

  sample_matches.each do |m|
    home = teams.find { |t| t.short_name == m[:home] }
    away = teams.find { |t| t.short_name == m[:away] }
    match_time = Time.zone.parse(m[:datetime])

    match = Match.find_or_initialize_by(season: season, home_team: home, away_team: away, match_datetime: match_time)
    match.stage = m[:stage] || :league
    match.status = m[:status] || (m[:completed] ? :completed : :scheduled)
    match.winner_team = m[:completed] ? [home, away].sample : nil
    match.title = "#{home.short_name} vs #{away.short_name}"
    match.save!
  end

  if year == 2025
    approved_users = User.approved.where(role: :user)
    season.matches.each do |match|
      approved_users.each do |user|
        pick = Pick.find_or_initialize_by(user: user, match: match)
        pick.team = [match.home_team, match.away_team].sample
        pick.save!
      end

      next unless match.completed? && match.winner_team_id.present?

      Scoring::MatchRecalculator.new(match: match, admin: admin).call
    end
  end
end

puts "Seed complete."
