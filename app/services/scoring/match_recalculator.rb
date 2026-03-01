module Scoring
  class MatchRecalculator
    def initialize(match:, admin: nil)
      @match = match
      @admin = admin
    end

    def call
      return 0 unless match.completed? && match.winner_team_id.present?

      ActiveRecord::Base.transaction do
        void_existing_events!

        match.picks.includes(:user).find_each.sum do |pick|
          points = awarded_points_for(pick)
          PointsEvent.create!(
            user: pick.user,
            season: match.season,
            match: match,
            pick: pick,
            points: points,
            reason: "Auto score for #{match.display_name} (#{match.stage.titleize})",
            event_type: :match_result,
            created_by_admin: admin,
            metadata: {
              stage: match.stage,
              winner_team_id: match.winner_team_id,
              picked_team_id: pick.team_id
            }
          )
          1
        end
      end
    end

    private

    attr_reader :match, :admin

    def awarded_points_for(pick)
      return 0 unless pick.team_id == match.winner_team_id

      match.season.points_for_stage(match.stage)
    end

    def void_existing_events!
      match.points_events.active.match_result.find_each do |event|
        event.update!(
          voided_at: Time.current,
          voided_by_admin: admin,
          void_reason: "Recalculated for updated result/pick",
          voided_event_reference_id: match.id
        )
      end
    end
  end
end
