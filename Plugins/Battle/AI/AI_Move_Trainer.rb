class PokeBattle_AI
    def pbChooseMovesTrainer(idxBattler, choices)
        user        = @battle.battlers[idxBattler]
        owner = @battle.pbGetOwnerFromBattlerIndex(user.index)
        skill  = owner.skill_level || 0
        policies = owner.policies || []

        # Log the available choices
        logMoveChoices(user,choices)
        
        # If there are valid choices, pick among them
        if choices.length > 0
            # Determine the most preferred move
            preferredChoice = nil
            sortedChoices = choices.sort_by{|choice| -choice[1]}
            preferredChoice = sortedChoices[0]
            PBDebug.log("[AI] #{user.pbThis} (#{user.index}) thinks #{user.moves[preferredChoice[0]].name} is the highest rated choice")
            if preferredChoice != nil
                @battle.pbRegisterMove(idxBattler,preferredChoice[0],false)
                @battle.pbRegisterTarget(idxBattler,preferredChoice[2]) if preferredChoice[2]>=0
            end
        else # If there are no calculated choices, create a list of the choices all scored the same, to be chosen between randomly later on
          PBDebug.log("[AI] #{user.pbThis} (#{user.index}) scored no moves above a zero, resetting all choices to default")
          user.eachMoveWithIndex do |m,i|
            next if !@battle.pbCanChooseMove?(idxBattler,i,false)
            next if m.empoweredMove?
            choices.push([i,100,-1])   # Move index, score, target
          end
          if choices.length == 0   # No moves are physically possible to use; use Struggle
            @battle.pbAutoChooseMove(user.index)
          end
        end

        # if there is somehow still no choice, randomly choose a move from the choices and register it
        if @battle.choices[idxBattler][2].nil?
          echoln("All AI protocols have failed or fallen through, picking at random.")
          randNum = pbAIRandom(totalScore)
          choices.each do |c|
            randNum -= c[1]
            next if randNum >= 0
            @battle.pbRegisterMove(idxBattler,c[0],false)
            @battle.pbRegisterTarget(idxBattler,c[2]) if c[2]>=0
            break
          end
        end

        # Log the result
        if @battle.choices[idxBattler][2]
          user.lastMoveChosen = @battle.choices[idxBattler][2].id
          PBDebug.log("[AI] #{user.pbThis} (#{user.index}) will use #{@battle.choices[idxBattler][2].name}")
        end
    end

    # Returns an array filled with each move that has a target worth using against
    # Giving also the best target to use the move against and the score of doing so
    def pbGetBestTrainerMoveChoices(user,skill=100,policies=[])
      choices = []
      user.eachMoveWithIndex do |move,i|
        next if !@battle.pbCanChooseMove?(user.index,i,false)
        newChoice = pbEvaluateMoveTrainer(user,user.moves[i],skill,policies)
        # Push a new array of [moveIndex,moveScore,targetIndex]
        # where targetIndex could be -1 for anything thats not single target
        choices.push([i].concat(newChoice)) if newChoice
      end
      return choices
    end

    def pbEvaluateMoveTrainer(user,move,skill,policies=[])
        target_data = move.pbTarget(user)
        newChoice = nil
        if target_data.num_targets > 1
            # If move affects multiple battlers and you don't choose a particular one
            totalScore = 0
            targets = []
            @battle.eachBattler do |b|
                next if !@battle.pbMoveCanTarget?(user.index,b.index,target_data)
                targets.push(b)
                score = pbGetMoveScore(move,user,b,skill,policies)
                totalScore += ((user.opposes?(b)) ? score : -score)
            end
            if targets.length > 1
                totalScore *= targets.length / (targets.length.to_f + 1.0)
                totalScore = totalScore.floor
            end
            newChoice = [totalScore,-1] if totalScore>0
        elsif target_data.num_targets == 0
            # If move has no targets, affects the user, a side or the whole field
            score = pbGetMoveScore(move,user,user,skill,policies)
            newChoice = [score,-1] if score>0
        else
            # If move affects one battler and you have to choose which one
            scoresAndTargets = []
            @battle.eachBattler do |b|
                next if !@battle.pbMoveCanTarget?(user.index,b.index,target_data)
                next if target_data.targets_foe && !user.opposes?(b)
                score = pbGetMoveScore(move,user,b,skill,policies)
                scoresAndTargets.push([score,b.index]) if score>0
            end
            if scoresAndTargets.length>0
                # Get the one best target for the move
                scoresAndTargets.sort! { |a,b| b[0]<=>a[0] }
                newChoice = [scoresAndTargets[0][0],scoresAndTargets[0][1]]
            end
        end
        return newChoice
    end

    #=============================================================================
	# Get a score for the given move being used against the given target
	#=============================================================================
	def pbGetMoveScore(move,user,target,skill=100,policies=[])
		score = 100
		score = pbGetMoveScoreFunctionCode(score,move,user,target,skill,policies)
		if score.nil?
			echoln("#{user.pbThis} unable to score #{move.id} against target #{target.pbThis(false)} assuming 50")
			return 50
		end
		
		# Never use a move that would fail outright
		@battle.messagesBlocked = true

		# Falsify the turn count so that the AI is calculated as though we are actually
        # in the midst of performing the move (turnCount is incremented as the attack phase begins)
        user.turnCount += 1 

		if move.pbMoveFailed?(user,[target])
			score = 0
            echoln("#{user.pbThis} scores the move #{move.id} as 0 due to it being predicted to fail.")
		end
		
        if move.pbFailsAgainstTarget?(user,target)
            score = 0
            echoln("#{user.pbThis} scores the move #{move.id} as 0 against target #{target.pbThis(false)} due to it being predicted to fail against that target.")
        end

        user.turnCount -= 1
        @battle.messagesBlocked = false
            
        # Don't prefer moves that are ineffective because of abilities or effects
        if pbCheckMoveImmunity(score,move,user,target,skill)
            score = 0
            echoln("#{user.pbThis} scores the move #{move.id} as 0 due to it being ineffective against target #{target.pbThis(false)}.")
        end
		
		# If user is asleep, prefer moves that are usable while asleep
		if user.status == :SLEEP && !move.usableWhenAsleep?
            echoln("#{user.pbThis} scores the move #{move.id} differently against target #{target.pbThis(false)} due to the user being asleep.")
			user.eachMove do |m|
				next unless m.usableWhenAsleep?
				score = 0
				break
			end
		end

		# Don't prefer attacking the target if they'd be semi-invulnerable
		if move.accuracy > 0 && (target.semiInvulnerable? || target.effectActive?(:SkyDrop))
            echoln("#{user.pbThis} scores the move #{move.id} differently against target #{target.pbThis(false)} due to the target being semi-invulnerable.")
            canHitAnyways = false
            # Knows what can get past semi-invulnerability
            if target.effectActive?(:SkyDrop)
                canHitAnyways = true if move.hitsFlyingTargets?
            else
                if target.inTwoTurnAttack?("0C9","0CC","0CE")   # Fly, Bounce, Sky Drop
                    canHitAnyways = true if move.hitsFlyingTargets?
                elsif target.inTwoTurnAttack?("0CA")          # Dig
                    canHitAnyways = true if move.hitsDiggingTargets?
                elsif target.inTwoTurnAttack?("0CB")          # Dive
                    canHitAnyways = true if move.hitsDivingTargets?
                end
            end
            canHitAnyways = true if user.hasActiveAbility?(:NOGUARD) || target.hasActiveAbility?(:NOGUARD)
			  
            if user.pbSpeed(true) > target.pbSpeed(true)
                if canHitAnyways
                    score *= 2
                else
                    score = 0
                end
            else
                score /= 2
            end
        end
		
		# A score of 0 here means it absolutely should not be used
		if score<=0
			echoln("#{user.pbThis} scores the move #{move.id} against target #{target.pbThis(false)} early: #{0}")
			return 0
		end
		
		# Pick a good move for the Choice items
        if user.hasActiveItem?([:CHOICEBAND,:CHOICESPECS,:CHOICESCARF]) || user.hasActiveAbilityAI?(:GORILLATACTICS)
            echoln("#{user.pbThis} scores the move #{move.id} differently #{target.pbThis(false)} due to choice locking.")
            if move.damagingMove?
                score += 40
            else
                score -= 40
			end
		end
		
		# Adjust score based on how much damage it can deal
		if move.damagingMove?
		  begin
            score = pbGetMoveScoreDamage(score,move,user,target,skill)
          rescue => exception
            pbPrintException($!) if $DEBUG
          end
		  score *= 0.75 if policies.include?(:DISLIKEATTACKING)
		end

        # Two-turn attacks waste a turn
        if move.chargingTurnMove? || move.function == "0C2"   # Hyper Beam
            score *= 2/3   # Not halved because semi-invulnerable during use or hits first turn
        end
	
		# Account for accuracy of move
		accuracy = pbRoughAccuracy(move,user,target,skill)
		score *= accuracy/100.0
		
		# Final adjustments t score
		score = score.to_i
		score = 0 if score<0
		echoln("#{user.pbThis} scores the move #{move.id} against target #{target.pbThis(false)}: #{score}")
		return score
	end
  
    #=============================================================================
    # Add to a move's score based on how much damage it will deal (as a percentage
    # of the target's current HP)
    #=============================================================================
    def pbGetMoveScoreDamage(score,move,user,target,skill)
        damagePercentage = getDamagePercentageAI(move,user,target,skill)
        
        # Adjust score
        if damagePercentage >= 100   # Prefer lethal damage
            damagePercentage = 150
            damagePercentage = 300 if move.hasKOEffect?(user,target)
        end
        
        score = (score * 0.75 + damagePercentage * 1.25).to_i
        return score
    end

    def getDamagePercentageAI(move,user,target,skill)
        # Calculate how much damage the move will do (roughly)
        baseDmg = pbMoveBaseDamageAI(move,user,target,skill)
        realDamage = pbTotalDamageAI(move,user,target,skill,baseDmg)

        # Convert damage to percentage of target's remaining HP
        damagePercentage = realDamage*100.0/target.hp
    end
end