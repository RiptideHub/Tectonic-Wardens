DebugMenuCommands.register("bossifyspecies", {
  "parent"      => "editorsmenu",
  "name"        => _INTL("Create bossified graphics"),
  "description" => _INTL("Create bossified graphics for a given species"),
  "effect"      => proc { |sprites, viewport|
	speciesGraphicName = pbEnterText(_INTL("Enter internal name."),0,20)
	createBossGraphics(speciesGraphicName)
  }
})

DebugMenuCommands.register("createallbossifiedsprites", {
  "parent"      => "editorsmenu",
  "name"        => _INTL("Create bossified graphics for all"),
  "description" => _INTL("Create bossified graphics for every avatar in avatars.txt at 1.5 size"),
  "effect"      => proc { |sprites, viewport|
	GameData::Avatar.each do |avatar_data|
	  createBossGraphics(avatar_data.id.to_s)
  end
  }
})
