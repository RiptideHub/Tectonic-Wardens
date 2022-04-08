SaveData.register(:waypoints_tracker) do
	ensure_class :WaypointsTracker
	save_value { $waypoints_tracker }
	load_value { |value| $waypoints_tracker = value }
	new_game_value { WaypointsTracker.new }
end

SaveData.register_conversion(:waypoints_data_add) do
  game_version '1.5.1'
  display_title 'Adding WayPoints Tracker to pre 1.5.1 saves.'
  to_all do |save_data|
    save_data[:waypoints_tracker] = WaypointsTracker.new if !save_data.has_key?(:waypoints_tracker)
  end
end