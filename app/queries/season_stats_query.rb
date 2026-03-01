class SeasonStatsQuery
  Result = Struct.new(:points, :correct_picks, :completed_picks, :accuracy, :rank, :picks_remaining, :chart_data, keyword_init: true)

  def self.call(user:, season:)
    new(user: user, season: season).call
  end

  def initialize(user:, season:)
    @user = user
    @season = season
  end

  def call
    leaderboard = LeaderboardQuery.call(season)
    rank = leaderboard.find { |row| row.user.id == user.id }&.rank

    picks_scope = user.picks.joins(:match).where(matches: { season_id: season.id })
    completed_scope = picks_scope.where(matches: { status: Match.statuses[:completed] })
    completed_count = completed_scope.count
    correct_count = completed_scope.where("picks.team_id = matches.winner_team_id").count
    points = user.points_events.active.where(season: season).sum(:points)
    accuracy = completed_count.positive? ? ((correct_count.to_f / completed_count) * 100).round(1) : 0.0

    remaining = season.matches.scheduled.where("match_datetime > ?", Time.current).count -
      picks_scope.joins(:match).where(matches: { status: Match.statuses[:scheduled] }).count

    Result.new(
      points: points,
      correct_picks: correct_count,
      completed_picks: completed_count,
      accuracy: accuracy,
      rank: rank,
      picks_remaining: [remaining, 0].max,
      chart_data: cumulative_points_over_time
    )
  end

  private

  attr_reader :user, :season

  def cumulative_points_over_time
    daily = user.points_events.active
      .where(season: season)
      .joins(:match)
      .group_by_day("matches.match_datetime", format: "%b %d")
      .sum(:points)

    running = 0
    daily.transform_values do |value|
      running += value
      running
    end
  end
end
