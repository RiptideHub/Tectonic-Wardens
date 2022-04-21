SaveData.register(:pokestate_2) do
	ensure_class :PokEstate
	save_value { $PokEstate }
	load_value { |value| $PokEstate = value }
	new_game_value { PokEstate.new }
end

SaveData.register_conversion(:pokestate_2) do
  game_version '1.6.1'
  display_title 'Adding PokEstate object to pre 1.6.1 saves.'
  to_all do |save_data|
    save_data[:pokestate_2] = PokEstate.new if !save_data.has_key?(:pokestate_2)
  end
end