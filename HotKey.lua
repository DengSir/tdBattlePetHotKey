--[[
HotKey.lua
@Date    : 2016/9/6 下午3:27:21
@Author  : DengSir (tdaddon@163.com)
@Link    : https://dengsir.github.io
]]

local ns                = select(2, ...)

local PetBattleFrame    = PetBattleFrame
local BottomFrame       = PetBattleFrame.BottomFrame
local PetSelectionFrame = BottomFrame.PetSelectionFrame

local HotKey            = CreateFrame('Frame', nil, PetBattleFrame)

function HotKey:OnLoad(event)
    if InCombatLockdown() then
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
    else
        self:InitBlizzard()
        self:InitBindings()
        self:SetScript('OnEvent', self.OnEvent)

        self:UnregisterEvent('PLAYER_REGEN_DISABLED')
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')

        self:RegisterEvent('PET_BATTLE_OPENING_START')
        self:RegisterEvent('PET_BATTLE_OPENING_DONE')
        self:RegisterEvent('PET_BATTLE_OVER')
        self:RegisterEvent('PET_BATTLE_CLOSE')

        self:SetScript('OnKeyDown', self.OnKeyDown)

        self.InitBlizzard = nil
        self.InitBindings = nil
        self.OnLoad       = nil
        self:OnEvent(event == 'PLAYER_LOGIN' and 'PET_BATTLE_OPENING_START' or event)
    end
end

function HotKey:InitBlizzard()
    local ForfeitButton = BottomFrame.ForfeitButton
    ForfeitButton.HotKey:Show()
    ForfeitButton:SetScript('OnClick', function()
        C_PetBattles.ForfeitGame()
    end)

    local SkipButton = BottomFrame.TurnTimer.SkipButton
    SkipButton.HotKey = SkipButton:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmallGray')
    SkipButton.HotKey:SetPoint('TOPRIGHT', -1, -2)

    local Switcher = PetTracker and PetTracker.Switcher
    if Switcher then
        Switcher._Initialize = Switcher.Initialize
        Switcher.Initialize = function()
            Switcher:_Initialize()
            Switcher._Initialize = nil

            for i = 1, 3 do
                local swap = Switcher['1'..i]
                local slot = PetSelectionFrame['Pet'..i]

                slot.HotKey = swap:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmallGray', 5)
                slot.HotKey:SetPoint('TOPRIGHT', swap.Icon, 'TOPRIGHT', 0, -1)
            end

            self:UpdateHotKeys()
        end
    else
        for i = 1, 3 do
            local slot = PetSelectionFrame['Pet'..i]

            slot.HotKey = slot:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmallGray')
            slot.HotKey:SetPoint('BOTTOMRIGHT', -10, 8)
        end
    end
end

function HotKey:InitBindings()
    self.Buttons = {}
    self.Bindings = {}

    local index = 0
    local function MakeBinding(button)
        local name = 'tdBattlePetHotKey' .. index
        local binding = CreateFrame('Button', name)
        if button then
            binding:SetScript('PostClick', function()
                if button:GetButtonState() == 'PUSHED' then
                    button:SetButtonState('NORMAL')
                end
            end)
            binding:SetScript('OnClick', function()
                button:Click()
            end)
        end
        index = index + 1
        return name
    end

    local Bindings = ns.Bindings

    local Buttons = {
        BottomFrame.abilityButtons[1],
        BottomFrame.abilityButtons[2],
        BottomFrame.abilityButtons[3],
        BottomFrame.SwitchPetButton,
        BottomFrame.CatchButton,
        BottomFrame.ForfeitButton,
        BottomFrame.TurnTimer.SkipButton,
        PetSelectionFrame.Pet1,
        PetSelectionFrame.Pet2,
        PetSelectionFrame.Pet3,
    }

    -- tdBattlePetHotKey0
    MakeBinding()

    for i, button in ipairs(Buttons) do
        local hotKey = Bindings[i]
        local name = MakeBinding(button)

        self.Buttons[hotKey] = button
        self.Bindings[hotKey] = name
    end
end

function HotKey:UpdateBindings()
    for i = 1, 5 do
        SetOverrideBindingClick(self, true, tostring(i), 'tdBattlePetHotKey0')
    end

    for key, button in pairs(self.Bindings) do
        SetOverrideBindingClick(self, true, key, button)
    end
end

function HotKey:ClearBindings()
    ClearOverrideBindings(self)
end

function HotKey:UpdateHotKeys()
    for key, button in pairs(self.Buttons) do
        if button.HotKey then
            button.HotKey:SetText(key)
        end
    end
end

function HotKey:OnKeyDown(key)
    local button = self.Buttons[key]
    if button and button:GetButtonState() == 'NORMAL' then
        button:SetButtonState('PUSHED')
    end
    self:SetPropagateKeyboardInput(true)
end

function HotKey:OnEvent(event, ...)
    if event == 'PET_BATTLE_OPENING_START' or event == 'PET_BATTLE_OPENING_DONE' then
        self:UpdateHotKeys()
        self:UpdateBindings()
    elseif event == 'PET_BATTLE_OVER' or event == 'PET_BATTLE_CLOSE' then
        self:ClearBindings()
    end
end

if C_PetBattles.IsInBattle() then
    if IsLoggedIn() then
        HotKey:OnLoad('PET_BATTLE_OPENING_START')
    else
        HotKey:RegisterEvent('PLAYER_LOGIN')
        HotKey:SetScript('OnEvent', function()
            C_Timer.After(0, function()
                HotKey:OnLoad('PET_BATTLE_OPENING_START')
            end)
        end)
    end
else
    HotKey:RegisterEvent('PET_BATTLE_OPENING_START')
    HotKey:SetScript('OnEvent', HotKey.OnLoad)
end
