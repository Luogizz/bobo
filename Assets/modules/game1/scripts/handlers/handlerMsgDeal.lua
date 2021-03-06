--[[
    处理服务器下发的发牌消息，发牌消息意味一手牌开始
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug("deal msg")

    local msgDeal = proto.decodeMessage("pokerface.MsgDeal", msgData)

    room:resetForNewHand()

    --保存一些房间属性
    room.bankerChairID = msgDeal.bankerChairID
    --是否连庄
    room.isContinuousBanker = msgDeal.isContinuousBanker
    room.windFlowerID = msgDeal.windFlowerID

    room.markup = msgDeal.markup
    local players = room.players

    local player1 = nil
    local player2 = nil
    --保存每一个玩家的牌列表
    local playerCardLists = msgDeal.playerCardLists
    for _, v in ipairs(playerCardLists) do
        local playerTileList = v
        local chairID = v.chairID
        local player = room:getPlayerByChairID(chairID)

        --填充手牌列表，仅自己有手牌列表，对手只有手牌张数
        if player:isMe() then
            player:addHandTiles(playerTileList.cardsOnHand)
        else
            if player1 == nil then
                player1 = player
            else
                player2 = player
            end
            player.cardCountOnHand = playerTileList.cardCountOnHand
        end

        player.playerView:setCurScore()
    end

    --自己手牌排一下序
    local mySelf = room.myPlayer
    mySelf:sortHands(false)

    --显示各个玩家的手牌（对手只显示暗牌）和花牌
    for _, p in pairs(players) do
        logger.debug(" 显示各个玩家的手牌")
        p:hand2UI(false, false)
    end

    --播放发牌动画，并使用coroutine等待动画完成
    room.roomView:dealAnimation(mySelf, player1, player2)

    --等待庄家出牌
    local bankerPlayer = room:getPlayerByChairID(room.bankerChairID)
    room.roomView:setWaitingPlayer(bankerPlayer)
end

return Handler
