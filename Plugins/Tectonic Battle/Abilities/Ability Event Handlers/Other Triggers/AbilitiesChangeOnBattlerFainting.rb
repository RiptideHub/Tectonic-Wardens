BattleHandlers::AbilityChangeOnBattlerFainting.add(:POWEROFALCHEMY,
    proc { |ability, battler, fainted, battle|
        next if battler.opposes?(fainted)
        next if fainted.ungainableAbility?(fainted.firstAbility)

        fainted.eachAbility do |abilityID|
            next if GameData::Ability::UNCOPYABLE_ABILITIES.include?(abilityID)
            next if abilityID == :WONDERGUARD
            battler.addAbility(abilityID, true)
        end
    }
)

BattleHandlers::AbilityChangeOnBattlerFainting.add(:RECEIVER,
    proc { |ability, battler, fainted, battle|
        next if battler.opposes?(fainted)
        next if fainted.ungainableAbility?(fainted.firstAbility)
        next if GameData::Ability::UNCOPYABLE_ABILITIES.include?(fainted.firstAbility)
        next if fainted.firstAbility == :WONDERGUARD
        battle.pbShowAbilitySplash(battler, ability, true)
        stolenAbility = fainted.firstAbility
        battler.setAbility(stolenAbility)
        battle.pbReplaceAbilitySplash(battler, stolenAbility)
        battle.pbDisplay(_INTL("{1}'s {2} was taken over!", fainted.pbThis, getAbilityName(stolenAbility)))
        battle.pbHideAbilitySplash(battler)

        fainted.eachAbility do |abilityID|
            next if GameData::Ability::UNCOPYABLE_ABILITIES.include?(abilityID)
            next if abilityID == :WONDERGUARD
            battler.addAbility(abilityID, true)
        end
    }
)