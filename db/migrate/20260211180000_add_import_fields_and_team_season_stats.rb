class AddImportFieldsAndTeamSeasonStats < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :match_no, :integer
    add_index :matches, [:season_id, :match_no], unique: true, where: "match_no IS NOT NULL", name: "index_matches_on_season_id_and_match_no"

    add_index :points_events, [:user_id, :match_id], unique: true, where: "match_id IS NOT NULL AND reason = 'import'", name: "index_points_events_on_import_user_match"

    create_table :team_season_stats do |t|
      t.references :season, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :played, null: false, default: 0
      t.integer :wins, null: false, default: 0
      t.integer :losses, null: false, default: 0

      t.timestamps
    end

    add_index :team_season_stats, [:season_id, :team_id], unique: true
  end
end
