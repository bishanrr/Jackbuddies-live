module Scoring
  class SeasonRecalculator
    def initialize(season:, admin: nil)
      @season = season
      @admin = admin
    end

    def call
      season.matches.completed.includes(:season, :picks).find_each.sum do |match|
        MatchRecalculator.new(match: match, admin: admin).call
      end
    end

    private

    attr_reader :season, :admin
  end
end
