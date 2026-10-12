-- ScooterCollisionFix (Script)
-- მოთავსება: Workspace > "Electric Scooter" (პირდაპირ მოდელის შიგნით)
--
-- სკუტერი ჰაერში იმიტომ ხტება, რომ მისივე ნაწილები (ბორბლები, კორპუსი,
-- მძღოლის სხეული) ერთმანეთში შედიან და ფიზიკა მათ ძალით აშორებს.
-- ეს სკრიპტი მხოლოდ Roblox-ის ჩაშენებულ ფიზიკას იყენებს (collision groups):
--   * სკუტერის ნაწილები ერთმანეთს აღარ ეჯახებიან
--   * სკუტერი და მოთამაშეები ერთმანეთს აღარ ეჯახებიან
--   * მიწასთან და დანარჩენ სამყაროსთან შეჯახება რჩება ჩვეულებრივად

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local SCOOTER_GROUP = "ElectricScooter"
local PLAYER_GROUP = "ScooterRiders"

local scooter = script.Parent

PhysicsService:RegisterCollisionGroup(SCOOTER_GROUP)
PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
PhysicsService:CollisionGroupSetCollidable(SCOOTER_GROUP, SCOOTER_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(SCOOTER_GROUP, PLAYER_GROUP, false)

local function setGroup(container, group)
	for _, obj in container:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = group
		end
	end
end

setGroup(scooter, SCOOTER_GROUP)
scooter.DescendantAdded:Connect(function(obj)
	if obj:IsA("BasePart") then
		obj.CollisionGroup = SCOOTER_GROUP
	end
end)

local function onCharacter(character)
	setGroup(character, PLAYER_GROUP)
	character.DescendantAdded:Connect(function(obj)
		if obj:IsA("BasePart") then
			obj.CollisionGroup = PLAYER_GROUP
		end
	end)
end

local function onPlayer(player)
	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

for _, player in Players:GetPlayers() do
	onPlayer(player)
end
Players.PlayerAdded:Connect(onPlayer)
