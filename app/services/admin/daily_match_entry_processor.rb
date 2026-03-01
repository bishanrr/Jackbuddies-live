module Admin
  class DailyMatchEntryProcessor
    Result = Struct.new(:processed_matches, :updated_picks, :unresolved_users, :errors, keyword_init: true)

    def initialize(season:, admin_user:, raw_text:)
      @season = season
      @admin_user = admin_user
      @raw_text = raw_text.to_s
    end

    def call
      # Defensive refresh: avoids stale column cache errors after rollbacks/migrations.
      Pick.reset_column_information
      Match.reset_column_information
      PointsEvent.reset_column_information
      DailyMatchEntry.reset_column_information

      processed_matches = 0
      updated_picks = 0
      unresolved_users = []
      errors = []
      processed_at = Time.current

      ActiveRecord::Base.transaction do
        parsed_blocks.each do |block|
          match = find_match_for_block(block, errors)
          unless match
            next
          end

          team_by_short = {
            match.home_team.short_name.upcase => match.home_team,
            match.away_team.short_name.upcase => match.away_team
          }
          winner_team = team_by_short[block[:winner_short]]
          unless winner_team
            errors << "Winner #{block[:winner_short]} is invalid for match #{block[:match_no]}"
            next
          end

          user_team_map = build_user_team_map(block)
          monkey_set = block[:monkey_jump_names].map { |name| normalize_name(name) }.to_set
          users_by_name = approved_users_lookup

          user_team_map.each do |raw_name, chosen_short|
            normalized = normalize_name(raw_name)
            user = users_by_name[normalized]
            unless user
              unresolved_users << raw_name
              next
            end

            effective_short = chosen_short
            if monkey_set.include?(normalized)
              effective_short = (chosen_short == match.home_team.short_name.upcase ? match.away_team.short_name.upcase : match.home_team.short_name.upcase)
            end

            team = team_by_short[effective_short]
            unless team
              errors << "Team #{effective_short} invalid for #{raw_name} in match #{block[:match_no]}"
              next
            end

            pick = Pick.find_or_initialize_by(user: user, match: match)
            pick.team = team
            pick.save!
            updated_picks += 1
          end

          match.update!(winner_team: winner_team, status: :completed)
          Scoring::MatchRecalculator.new(match: match, admin: admin_user).call
          DailyMatchEntry.create!(
            season: season,
            admin_user: admin_user,
            match_no: block[:match_no],
            winner_team_short_name: winner_team.short_name,
            raw_text: block[:raw_text],
            processed_at: processed_at
          )
          processed_matches += 1
        end
      end

      Result.new(
        processed_matches: processed_matches,
        updated_picks: updated_picks,
        unresolved_users: unresolved_users.uniq.sort,
        errors: errors
      )
    end

    private

    attr_reader :season, :admin_user, :raw_text

    def parsed_blocks
      chunks = raw_text.split(/(?=^\s*\*?\s*Match\s+\d+\s*:)/im).map(&:strip).reject(&:blank?)
      chunks.map { |chunk| parse_chunk(chunk) }.compact
    end

    def parse_chunk(chunk)
      match_header = chunk.match(/Match\s+(\d+)\s*:\s*([A-Za-z]+)\s*VS\s*([A-Za-z]+)/i)
      return nil unless match_header

      team1 = match_header[2].upcase
      team2 = match_header[3].upcase

      lines = chunk.lines.map { |line| line.gsub(/\*+/, "").strip }.reject(&:blank?)
      team_users = { team1 => [], team2 => [] }
      monkey_jump_names = []
      winner_short = nil

      lines.each do |line|
        if line.match?(/^#{Regexp.escape(team1)}\s*:/i)
          team_users[team1] = split_names(line.split(":", 2).last)
        elsif line.match?(/^#{Regexp.escape(team2)}\s*:/i)
          team_users[team2] = split_names(line.split(":", 2).last)
        elsif line.match?(/^Monkey\s*Jump\s*:/i)
          monkey_jump_names = split_names(line.split(":", 2).last)
        elsif line.match?(/^Winner\s*:/i)
          winner_short = line.split(":", 2).last.to_s.gsub(/[,\s]/, "").upcase
        end
      end

      return nil if winner_short.blank?

      {
        match_no: match_header[1].to_i,
        team1_short: team1,
        team2_short: team2,
        team_users: team_users,
        monkey_jump_names: monkey_jump_names,
        winner_short: winner_short,
        raw_text: chunk
      }
    end

    def split_names(raw)
      raw.to_s.split(",").map(&:strip).reject(&:blank?)
    end

    def build_user_team_map(block)
      user_team_map = {}
      block[:team_users].each do |team_short, names|
        names.each { |name| user_team_map[name] = team_short }
      end
      user_team_map
    end

    def approved_users_lookup
      @approved_users_lookup ||= User.approved.index_by { |user| normalize_name(user.display_name.presence || user.name_or_email) }
    end

    def normalize_name(name)
      name.to_s.downcase.gsub(/\s+/, "")
    end

    def find_match_for_block(block, errors)
      existing = season.matches.find_by(match_no: block[:match_no])
      return existing if existing

      if season.year.to_i == 2025
        errors << "Match #{block[:match_no]} not found in season #{season.year}"
        return nil
      end

      team1 = find_team_by_short(block[:team1_short])
      team2 = find_team_by_short(block[:team2_short])

      unless team1 && team2
        errors << "Match #{block[:match_no]} not found in season #{season.year} and team short names could not be resolved"
        return nil
      end

      Match.create!(
        season: season,
        match_no: block[:match_no],
        home_team: team1,
        away_team: team2,
        title: "#{team1.short_name} vs #{team2.short_name}",
        match_datetime: Time.current,
        stage: :league,
        status: :completed
      )
    end

    def find_team_by_short(short_name)
      Team.where("UPPER(short_name) = ?", short_name.to_s.upcase).first
    end
  end
end
