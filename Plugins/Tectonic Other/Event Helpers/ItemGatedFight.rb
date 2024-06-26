def itemGatedFight(itemID,regularBattleIntroText,itemGateIntroText,requestItemText,confirmGiveText,declineGiveText,lackingItemText)
    if getMySwitch("B")
        noticePlayer
        pbMessage(regularBattleIntroText)
    else
        showExclamation
        pbWait(20)
        pbMessage(itemGateIntroText)
        if pbHasItem?(itemID)
            if pbConfirmMessage(requestItemText)
                pbDeleteItem(itemID)
                pbMessage(confirmGiveText)
                setMySwitch("B")
            else
                pbMessage(declineGiveText)
                forcePlayerBackwards
                get_self.direction = get_self.original_direction
                command_end # exit event processing
            end
        else
            pbMessage(lackingItemText)
            forcePlayerBackwards
            get_self.direction = get_self.original_direction
            command_end # exit event processing
        end
    end
    # If this finishes without event exit, the battle commences
end