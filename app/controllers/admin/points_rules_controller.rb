module Admin
  class PointsRulesController < BaseController
    before_action :set_season

    def edit
      authorize PointsRule
      @rules = rules_hash
    end

    def update
      authorize PointsRule
      ActiveRecord::Base.transaction do
        Match.stages.keys.each do |stage|
          rule = @season.points_rules.find_or_initialize_by(stage: stage)
          rule.update!(points_for_correct: params.require(:rules)[stage])
        end
      end

      redirect_to edit_admin_points_rule_path(@season, season_id: @season.id), notice: "Rules updated."
    rescue ActiveRecord::RecordInvalid => e
      @rules = rules_hash
      flash.now[:alert] = e.message
      render :edit, status: :unprocessable_entity
    end

    private

    def set_season
      @season = Season.find(params[:id])
    end

    def rules_hash
      Match.stages.keys.index_with do |stage|
        @season.points_rules.find_by(stage: stage)&.points_for_correct || 0
      end
    end
  end
end
