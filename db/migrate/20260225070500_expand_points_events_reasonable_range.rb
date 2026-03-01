class ExpandPointsEventsReasonableRange < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :points_events, name: "check_points_events_reasonable_range"
    add_check_constraint :points_events,
      "points >= -1000 AND points <= 1000",
      name: "check_points_events_reasonable_range"
  end

  def down
    remove_check_constraint :points_events, name: "check_points_events_reasonable_range"
    add_check_constraint :points_events,
      "points >= -100 AND points <= 100",
      name: "check_points_events_reasonable_range"
  end
end
