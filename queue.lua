-- Wait for game to load
repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local lobbyPlaceId = 116495829188952
local mainGamePlaceId = 70876832253163
local apiUrl = "https://games.roblox.com/v1/games/" .. lobbyPlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
local maxPlayersAllowed = 9 -- If more than this, teleport again

-- Function to get a low-player server
local function getLowPlayerServer(cursor)
    local url = apiUrl .. ((cursor and "&cursor=" .. cursor) or "")
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        for _, server in pairs(data.data) do
            if server.playing < maxPlayersAllowed and server.id ~= game.JobId then
                return server.id
            end
        end
        return data.nextPageCursor
    end

    warn("Failed to fetch server list.")
    return nil
end

-- Function to teleport to a low-player server
local function teleportToLowPlayerServer()
    local serverId, cursor = nil, nil

    repeat
        cursor = getLowPlayerServer(cursor)
        if cursor and not serverId then
            serverId = cursor
        end
    until serverId or not cursor

    if serverId then
        print("Teleporting to a low-player server...")
        TeleportService:TeleportToPlaceInstance(lobbyPlaceId, serverId, player)
    else
        warn("No suitable server found.")
    end
end

-- Check where the player is
if game.PlaceId == mainGamePlaceId then
    print("Player is currently in-game, proceeding...")
    return -- Exit the script entirely, skipping teleport logic
elseif game.PlaceId == lobbyPlaceId then
    if #Players:GetPlayers() > maxPlayersAllowed then
        print("Server too crowded! Searching for a new server...")
        teleportToLowPlayerServer()
        return
    else
        print("Server player count is fine. Proceeding with normal execution...")
    end
end

-- Define positions for back-and-forth movement
local pointA = Vector3.new(45, 8, 91)
local pointB = Vector3.new(45, 8, 154)
local moveSpeed = 16 -- Normal walking speed

-- Function to disable collisions (noclip effect)
local function enableNoClip()
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end

-- Function to move smoothly between points using TweenService
local function tweenToPosition(targetPosition)
    local distance = (rootPart.Position - targetPosition).Magnitude
    local timeToMove = distance / moveSpeed -- Time based on speed

    local tweenInfo = TweenInfo.new(timeToMove, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    
    tween:Play()
    return tween
end

-- Function to fire the create party remote endlessly
local function fireCreatePartyRemote()
    while true do
        local args = {
    [1] = {
        ["maxPlayers"] = 1,
        ["gameMode"] = "Normal"
    }
}

game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("RemotePromise"):WaitForChild("Remotes"):WaitForChild("C_CreateParty"):FireServer(unpack(args))
        wait(0.1) -- Small delay to prevent crashes
    end
end

-- Function to check if the player has been teleported
local function hasBeenTeleported()
    return game.PlaceId ~= lobbyPlaceId -- If PlaceId changes, we've left the lobby
end

-- Start the remote firing loop in a separate thread
task.spawn(fireCreatePartyRemote)

-- Main loop: Move back and forth until teleported
local function startTeleportationLoop()
    enableNoClip() -- Enable noclip to prevent movement issues
    
    while not hasBeenTeleported() do
        local tweenA = tweenToPosition(pointA)
        tweenA.Completed:Wait() -- Wait for movement to finish
        if hasBeenTeleported() then break end
        
        local tweenB = tweenToPosition(pointB)
        tweenB.Completed:Wait() -- Wait for movement to finish
        if hasBeenTeleported() then break end
    end

    print("Successfully Teleported. Stopping teleportation & remote firing.")
end

-- Start the teleportation loop
startTeleportationLoop()
