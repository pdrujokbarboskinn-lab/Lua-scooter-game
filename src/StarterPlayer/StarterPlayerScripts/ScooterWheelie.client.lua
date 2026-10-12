-- ScooterWheelie (LocalScript)
-- მოთავსება: StarterPlayer > StarterPlayerScripts
--
-- როცა მოთამაშე სკუტერზე ზის (VehicleSeat), E ღილაკზე დაჭერით სკუტერი
-- უკანა ბორბალზე დგება (wheelie). ხელახლა E — ჩამოდის ორივე ბორბალზე.
-- სკუტერიდან ჩამოსვლისას wheelie ავტომატურად ითიშება.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CONFIG = {
	Key = Enum.KeyCode.E,
	TargetAngle = math.rad(35), -- რა კუთხით აიწიოს წინა ბორბალი
	Stiffness = 8,              -- რამდენად სწრაფად მიაღწიოს კუთხეს
	MaxPitchSpeed = 4,          -- მაქს. ბრუნვის სიჩქარე (რად/წმ)
	-- თუ მხოლოდ სკუტერზე გინდა მუშაობა და არა ყველა მანქანაზე,
	-- სკუტერის მოდელს დაარქვი სახელი, რომელიც შეიცავს ამ სიტყვას.
	-- nil = ნებისმიერ VehicleSeat-ზე იმუშავებს.
	ModelNameContains = nil,    -- მაგ.: "Scooter"
}

local player = Players.LocalPlayer
local currentSeat: VehicleSeat? = nil
local wheelieOn = false
local landing = false -- E-ს მეორედ დაჭერის შემდეგ, სანამ წინა ბორბალი არ დაეშვება

local function isScooterSeat(seat)
	if not seat or not seat:IsA("VehicleSeat") then
		return false
	end
	if CONFIG.ModelNameContains then
		local model = seat:FindFirstAncestorOfClass("Model")
		return model ~= nil and string.find(model.Name, CONFIG.ModelNameContains, 1, true) ~= nil
	end
	return true
end

local function hookCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Seated:Connect(function(active, seatPart)
		if active and isScooterSeat(seatPart) then
			currentSeat = seatPart
		else
			currentSeat = nil
			wheelieOn = false
			landing = false
		end
	end)

	humanoid.Died:Connect(function()
		currentSeat = nil
		wheelieOn = false
	end)
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return -- მაგ. ჩატში წერისას E არ უნდა ჩაითვალოს
	end
	if input.KeyCode == CONFIG.Key and currentSeat then
		wheelieOn = not wheelieOn
		landing = not wheelieOn
	end
end)

-- მძღოლს აქვს network ownership სკუტერზე, ამიტომ ფიზიკის მართვა
-- კლიენტიდან შეიძლება და ყველა მოთამაშე დაინახავს.
RunService.Heartbeat:Connect(function()
	local seat = currentSeat
	if not seat or not seat.Parent then
		return
	end

	local cf = seat.CFrame
	local right = cf.RightVector
	-- pitch > 0 ნიშნავს, რომ წინა მხარე აწეულია
	local pitch = math.asin(math.clamp(cf.LookVector.Y, -1, 1))
	local target = wheelieOn and CONFIG.TargetAngle or 0

	if not wheelieOn then
		-- ვეხებით მხოლოდ დაშვების დროს, რომ აღმართზე/ტრამპლინზე არ შევუშალოთ
		if not landing or pitch < math.rad(3) then
			landing = false
			return
		end
	end

	local pitchSpeed = math.clamp((target - pitch) * CONFIG.Stiffness, -CONFIG.MaxPitchSpeed, CONFIG.MaxPitchSpeed)

	-- ვცვლით მხოლოდ "წინ/უკან გადახრის" ბრუნვას, საჭე და დანარჩენი ხელუხლებელია
	local angVel = seat.AssemblyAngularVelocity
	local other = angVel - right * angVel:Dot(right)
	seat.AssemblyAngularVelocity = other + right * pitchSpeed
end)
