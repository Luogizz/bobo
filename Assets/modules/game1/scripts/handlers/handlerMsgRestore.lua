--[[
    处理断线恢复，奔溃后恢复
]]
local Handler = {}

local proto = require "scripts/proto/proto"
local logger = require "lobby/lcore/logger"

function Handler.onMsg(msgData, room)
    logger.debug(" handle room restore")

    --掉线恢复时，是通过MsgRestore下发的
    local msgRestore = proto.decodeMessage("pokerface.MsgRestore", msgData)

    --首先清空所有玩家的牌列表
    for _, p in pairs(room.players) do
        p:resetForNewHand()
    end

    --一手牌数据
    local msgDeal = msgRestore.msgDeal
    room.bankerChairID = msgDeal.bankerChairID
    room.isContinuousBanker = msgDeal.isContinuousBanker
    room.windFlowerID = msgDeal.windFlowerID
    --room.tilesInWall = msgDeal.tilesInWall
    room.markup = msgDeal.markup
    -- end

    --重连
    --room.roomView:onReconnect()
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
            player.cardCountOnHand = playerTileList.cardCountOnHand
        end

        --填充花牌列表
        --player:addFlowerTiles(playerTileList.tilesFlower)

        --填充打出去的牌列表
        if playerTileList.discardedHands then
            local discardTileIdLength = #playerTileList.discardedHands
            if discardTileIdLength > 0 then
                local discardTiles = playerTileList.discardedHands[discardTileIdLength]
                if discardTiles then
                    local discardTileIds = discardTiles.cards
                    if discardTileIds and #discardTileIds > 0 then
                        for _, v2 in ipairs(discardTileIds) do
                            --加到打出牌列表
                            player:addDicardedTile(v2)
                        end
                        player:discarded2UI(discardTileIds)
                    --显示
                    end
                end
            end
        end

        if player.chairID == room.bankerChairID then
            room.roomView:setWaitingPlayer(player)
        end
    end

    --自己手牌排一下序
    local mySelf = room.myPlayer
    mySelf:sortHands()

    --显示各个玩家的手牌（对手只显示暗牌）和花牌和打出去的牌
    for _, p in pairs(room.players) do
        p:hand2UI()

        --local newDiscarded = false
        if p.chairID == msgRestore.prevActionChairID then
            room.roomView:setWaitingPlayer(p)
        --newDiscarded = true
        end
        --p:discarded2UI(msgRestore.prevActionHand.cards)
    end
end

return Handler
