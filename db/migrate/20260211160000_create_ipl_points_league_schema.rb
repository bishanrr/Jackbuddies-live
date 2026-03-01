class CreateIplPointsLeagueSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.string :display_name
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :approved_at
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :denied_at
      t.references :denied_by, foreign_key: { to_table: :users }
      t.text :denial_reason

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true

    create_table :seasons do |t|
      t.integer :year, null: false
      t.string :name, null: false
      t.integer :default_lock_minutes, null: false, default: 10

      t.timestamps
    end
    add_index :seasons, :year, unique: true

    create_table :teams do |t|
      t.string :name, null: false
      t.string :short_name, null: false

      t.timestamps
    end
    add_index :teams, :name, unique: true
    add_index :teams, :short_name, unique: true

    create_table :points_rules do |t|
      t.references :season, null: false, foreign_key: true
      t.integer :stage, null: false
      t.integer :points_for_correct, null: false

      t.timestamps
    end
    add_index :points_rules, [:season_id, :stage], unique: true

    create_table :matches do |t|
      t.references :season, null: false, foreign_key: true
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.datetime :match_datetime, null: false
      t.integer :stage, null: false
      t.integer :status, null: false, default: 0
      t.references :winner_team, foreign_key: { to_table: :teams }
      t.string :title

      t.timestamps
    end
    add_index :matches, [:season_id, :match_datetime]

    create_table :picks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :updated_by_admin, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :picks, [:user_id, :match_id], unique: true

    create_table :points_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true
      t.references :match, foreign_key: true
      t.references :pick, foreign_key: true
      t.integer :points, null: false
      t.string :reason, null: false
      t.integer :event_type, null: false, default: 0
      t.references :created_by_admin, foreign_key: { to_table: :users }
      t.datetime :voided_at
      t.references :voided_by_admin, foreign_key: { to_table: :users }
      t.string :void_reason
      t.bigint :voided_event_reference_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end
    add_index :points_events, :voided_event_reference_id
    add_index :points_events, [:season_id, :user_id]
    add_index :points_events, [:match_id, :user_id]

    create_table :pick_audit_logs do |t|
      t.references :pick, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :editor_admin, null: false, foreign_key: { to_table: :users }
      t.references :from_team, foreign_key: { to_table: :teams }
      t.references :to_team, null: false, foreign_key: { to_table: :teams }
      t.string :reason, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_check_constraint :matches, "home_team_id <> away_team_id", name: "check_matches_distinct_teams"
    add_check_constraint :points_events, "points >= -100 AND points <= 100", name: "check_points_events_reasonable_range"
  end
end
