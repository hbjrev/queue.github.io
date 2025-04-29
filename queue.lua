-- Wait for game to load
repeat wait() until game:IsLoaded()

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

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
    return game.PlaceId ~= game.PlaceId -- Placeholder logic
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
