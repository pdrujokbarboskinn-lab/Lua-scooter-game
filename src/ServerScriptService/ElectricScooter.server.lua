-- ElectricScooter (Script)
-- მოთავსება: ServerScriptService
--
-- აშენებს მართვად ელექტრო სკუტერს Workspace-ში, სახელით "Electric Scooter".
-- მხოლოდ Roblox-ის ნამდვილი ფიზიკა: ბორბლები HingeConstraint-ებზე ტრიალებს,
-- უკანა ბორბალი ძრავია (Motor), წინა საჭე Servo-თი ბრუნავს,
-- AlignOrientation მხოლოდ გვერდზე გადავარდნისგან იცავს (წინ/უკან თავისუფალია).
--
-- მართვა: მიდი სკუტერთან და დააჭირე E-ს რომ დაჯდე.
-- W/S — წინ/უკან (S მოძრაობისას მუხრუჭია), A/D — საჭე, Space — ჩამოსვლა.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local CONFIG = {
	SpawnCFrame = CFrame.new(0, 0.2, -15), -- სად გაჩნდეს (y = მიწის სიმაღლე)
	MaxSpeed = 45,        -- სტადი/წმ წინ
	ReverseSpeed = 10,    -- სტადი/წმ უკან
	MotorTorque = 4000,   -- ძრავის ძალა
	CoastTorque = 150,    -- გაზის გარეშე ნელ-ნელა ჩერდება
	MaxSteerAngle = 30,   -- გრადუსი, დაბალ სიჩქარეზე
	HighSpeedSteer = 0.4, -- მაქს. სიჩქარეზე საჭის რა წილი რჩება
	WheelRadius = 1,
	InvertDrive = false,  -- თუ W-ზე უკან მიდის, გახადე true
	InvertSteer = false,  -- თუ D-ზე მარცხნივ უხვევს, გახადე true
}

local SCOOTER_GROUP = "ElectricScooter"
local PLAYER_GROUP = "ScooterRiders"

PhysicsService:RegisterCollisionGroup(SCOOTER_GROUP)
PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
-- სკუტერის ნაწილები ერთმანეთს და მძღოლს არ ეჯახება — ამიტომ აღარ "აფრინდება"
PhysicsService:CollisionGroupSetCollidable(SCOOTER_GROUP, SCOOTER_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(SCOOTER_GROUP, PLAYER_GROUP, false)

local R = CONFIG.WheelRadius
local WHEEL_Z = 2.3 -- ბორბლების მანძილი ცენტრიდან (წინ = -Z)

local base = CONFIG.SpawnCFrame
local model = Instance.new("Model")
model.Name = "Electric Scooter"

local function makePart(name, size, localPos, props)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = base * CFrame.new(localPos)
	p.Anchored = false
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CollisionGroup = SCOOTER_GROUP
	for k, v in props or {} do
		p[k] = v
	end
	p.Parent = model
	return p
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- axis / secondary — ნაწილის ლოკალურ სივრცეში (ყველა ნაწილი base-ის მიმართულებითაა)
local function attach(part, worldPos, axis, secondary)
	local a = Instance.new("Attachment")
	a.CFrame = CFrame.fromMatrix(part.CFrame:PointToObjectSpace(worldPos), axis, secondary)
	a.Parent = part
	return a
end

-- კორპუსი (მძიმე, რომ სიმძიმის ცენტრი დაბლა იყოს)
local deck = makePart("Deck", Vector3.new(1.4, 0.3, 2.6), Vector3.new(0, 0.8, 0), {
	Color = Color3.fromRGB(45, 45, 50),
	Material = Enum.Material.Metal,
	CustomPhysicalProperties = PhysicalProperties.new(8, 0.3, 0),
})
model.PrimaryPart = deck

local seat = Instance.new("VehicleSeat")
seat.Name = "DriveSeat"
seat.Size = Vector3.new(1.2, 0.2, 1.2)
seat.CFrame = base * CFrame.new(0, 1.05, 0.3)
seat.CanCollide = false
seat.Transparency = 1
seat.HeadsUpDisplay = false
seat.CollisionGroup = SCOOTER_GROUP
seat.Parent = model
weld(deck, seat)

local wheelPhys = PhysicalProperties.new(2, 1.5, 0, 100, 100)
local function makeWheel(name, z)
	return makePart(name, Vector3.new(0.5, R * 2, R * 2), Vector3.new(0, R, z), {
		Shape = Enum.PartType.Cylinder, -- ღერძი X-ზეა, ზუსტად როგორც ბორბალს სჭირდება
		CanCollide = true,
		Color = Color3.fromRGB(20, 20, 20),
		Material = Enum.Material.Rubber,
		CustomPhysicalProperties = wheelPhys,
	})
end

local frontWheel = makeWheel("FrontWheel", -WHEEL_Z)
local rearWheel = makeWheel("RearWheel", WHEEL_Z)

-- საჭის ბლოკი: ბრუნავს ვერტიკალური ღერძის გარშემო, მასზეა მიმაგრებული ძელი და სახელური
local fork = makePart("Fork", Vector3.new(0.4, 0.4, 0.4), Vector3.new(0, 2.2, -WHEEL_Z), {
	Transparency = 1,
})
local stem = makePart("Stem", Vector3.new(0.25, 3, 0.25), Vector3.new(0, 3.2, -WHEEL_Z), {
	Color = Color3.fromRGB(30, 30, 35),
	Material = Enum.Material.Metal,
})
local handlebar = makePart("Handlebar", Vector3.new(2.2, 0.2, 0.2), Vector3.new(0, 4.7, -WHEEL_Z), {
	Color = Color3.fromRGB(30, 30, 35),
	Material = Enum.Material.Metal,
})
weld(fork, stem)
weld(fork, handlebar)

local X, Y = Vector3.xAxis, Vector3.yAxis
local function worldOf(lx, ly, lz)
	return (base * CFrame.new(lx, ly, lz)).Position
end
local axleX, upAxis = X, Y

-- უკანა ბორბალი: ძრავი
local rearMotor = Instance.new("HingeConstraint")
rearMotor.Name = "RearMotor"
rearMotor.ActuatorType = Enum.ActuatorType.Motor
rearMotor.MotorMaxTorque = CONFIG.CoastTorque
rearMotor.AngularVelocity = 0
rearMotor.Attachment0 = attach(deck, worldOf(0, R, WHEEL_Z), axleX, upAxis)
rearMotor.Attachment1 = attach(rearWheel, worldOf(0, R, WHEEL_Z), axleX, upAxis)
rearMotor.Parent = deck

-- საჭე: Servo ვერტიკალურ ღერძზე
local steering = Instance.new("HingeConstraint")
steering.Name = "Steering"
steering.ActuatorType = Enum.ActuatorType.Servo
steering.ServoMaxTorque = 5000
steering.AngularSpeed = 6
steering.TargetAngle = 0
steering.LimitsEnabled = true
steering.LowerAngle = -CONFIG.MaxSteerAngle
steering.UpperAngle = CONFIG.MaxSteerAngle
steering.Attachment0 = attach(deck, worldOf(0, 2.2, -WHEEL_Z), upAxis, axleX)
steering.Attachment1 = attach(fork, worldOf(0, 2.2, -WHEEL_Z), upAxis, axleX)
steering.Parent = deck

-- წინა ბორბალი: თავისუფლად ტრიალებს საჭის ბლოკზე
local frontAxle = Instance.new("HingeConstraint")
frontAxle.Name = "FrontAxle"
frontAxle.Attachment0 = attach(fork, worldOf(0, R, -WHEEL_Z), axleX, upAxis)
frontAxle.Attachment1 = attach(frontWheel, worldOf(0, R, -WHEEL_Z), axleX, upAxis)
frontAxle.Parent = fork

-- გვერდზე გადავარდნისგან დაცვა: კორპუსის მარჯვენა ღერძი ჰორიზონტალური რჩება.
-- წინ/უკან დახრა (აღმართი, ტრამპლინი, ცალ ბორბალზე დგომა) თავისუფალია.
local upright = Instance.new("AlignOrientation")
upright.Name = "KeepUpright"
upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
upright.AlignType = Enum.AlignType.PrimaryAxisPerpendicular
upright.PrimaryAxis = Vector3.yAxis
upright.Attachment0 = attach(deck, deck.Position, axleX, upAxis)
upright.MaxTorque = 100000
upright.Responsiveness = 25
upright.Parent = deck

-- ჯდომა ProximityPrompt-ით (შეჯახებით ავტომატური ჯდომა გამორთულია collision group-ის გამო)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ride"
prompt.ObjectText = "Electric Scooter"
prompt.MaxActivationDistance = 8
prompt.RequiresLineOfSight = false
prompt.Parent = seat

prompt.Triggered:Connect(function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and not seat.Occupant then
		seat:Sit(humanoid)
	end
end)

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	prompt.Enabled = seat.Occupant == nil
end)

model.Parent = workspace

-- მოთამაშეების collision group
local function onCharacter(character)
	for _, obj in character:GetDescendants() do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = PLAYER_GROUP
		end
	end
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

-- მართვა
local driveSign = CONFIG.InvertDrive and 1 or -1 -- -1: X ღერძის გარშემო უარყოფითი ბრუნვა = წინ
local steerSign = CONFIG.InvertSteer and 1 or -1 -- -1: D (SteerFloat=+1) = მარჯვნივ

RunService.Heartbeat:Connect(function()
	if not deck.Parent then
		return
	end

	local throttle = seat.Occupant and seat.ThrottleFloat or 0
	local steer = seat.Occupant and seat.SteerFloat or 0

	if throttle > 0 then
		rearMotor.AngularVelocity = driveSign * CONFIG.MaxSpeed / R * throttle
		rearMotor.MotorMaxTorque = CONFIG.MotorTorque
	elseif throttle < 0 then
		-- თუ წინ მიდის, ეს ჯერ მუხრუჭია, მერე უკან სვლა
		rearMotor.AngularVelocity = driveSign * CONFIG.ReverseSpeed / R * throttle
		rearMotor.MotorMaxTorque = CONFIG.MotorTorque
	else
		rearMotor.AngularVelocity = 0
		rearMotor.MotorMaxTorque = CONFIG.CoastTorque
	end

	local speed = deck.AssemblyLinearVelocity.Magnitude
	local t = math.clamp(speed / CONFIG.MaxSpeed, 0, 1)
	local steerScale = 1 - (1 - CONFIG.HighSpeedSteer) * t
	steering.TargetAngle = steerSign * steer * CONFIG.MaxSteerAngle * steerScale
end)
