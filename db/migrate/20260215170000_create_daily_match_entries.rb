class CreateDailyMatchEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_match_entries do |t|
      t.references :season, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.integer :match_no, null: false
      t.string :winner_team_short_name, null: false
      t.text :raw_text, null: false
      t.datetime :processed_at, null: false

      t.timestamps
    end

    add_index :daily_match_entries, [:season_id, :match_no, :processed_at], name: "index_daily_match_entries_on_season_match_processed"
  end
end
