class CreateAllowedSignupNames < ActiveRecord::Migration[8.1]
  def change
    create_table :allowed_signup_names do |t|
      t.string :first_name, null: false

      t.timestamps
    end

    add_index :allowed_signup_names, :first_name, unique: true
  end
end
