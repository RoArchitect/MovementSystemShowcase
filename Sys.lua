-- << GLOBAL >> --
local workspace , game = workspace , game
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Types = require(ReplicatedStorage:WaitForChild("Types"));

local Service = function
	(
		Name : Types.Name
	)
	
	-- >> << --
	
	return game:GetService(tostring(Name) .. "\000");
	
end

-- << DEFINED >> --
local UserInputService : Types.UserInputService = Service('UserInputService');
local ContextActionService : Types.ContextActionService = Service('ContextActionService');
local Players : Types.Players = Service('Players');
local RunService : Instance = Service('RunService');
local Lighting : Instance = Service('Lighting');
local TweenService : Instance = Service('TweenService');
local SoundService : Instance = Service('SoundService');

local LocalPlayer : Types.Player = Players.LocalPlayer;
local Character : Model = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid : Humanoid = Character:WaitForChild("Humanoid");
local Animator : Animator? = Humanoid:WaitForChild("Animator");

local Camera : Camera? = workspace.CurrentCamera;
local DepthOfField : DepthOfFieldEffect = Lighting:WaitForChild("DepthOfField");
local CharValues : Folder = Character:WaitForChild("CharValues");
local PlrGui : PlayerGui = LocalPlayer.PlayerGui;
local Vignette = PlrGui["Visual Effects"].Effects.Vignette;

local SprintTrack : Types.AnimationTrack
local ExhaustedTrack : Types.AnimationTrack
local CrouchTrack : Types.AnimationTrack
local CrouchWalkTrack : Types.AnimationTrack
local Exhausted : Types.Animation
local ExhaustedIdle = false

local Thread = task.spawn

-- << << Tween Infos >> >> --
local TI = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local TI2 = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)


-- << << Tweens >> >> --
local WalkSpeed = TweenService:Create(Humanoid, TI2, {WalkSpeed = 9})
local SprintSpeedT = TweenService:Create(Humanoid, TI, {WalkSpeed = 25})
local CrouchSpeed = TweenService:Create(Humanoid, TI, {WalkSpeed = 5})
local WalkFov = TweenService:Create(Camera, TI, {FieldOfView = 70})
local SprintFov = TweenService:Create(Camera, TI, {FieldOfView = 78})
local BreathingVolumePointFive = TweenService:Create(SoundService.SFX.Char["Breathing_Stamina"],TweenInfo.new(2.2),{Volume = 0.5})
local BreathingVolumeZero = TweenService:Create(SoundService.SFX.Char["Breathing_Stamina"],TweenInfo.new(2.2),{Volume = 0})
local BlurTweenTired1 = TweenService:Create(Lighting["Blur"],TweenInfo.new(2.53),{Size = 13.73})
local BlurTweenTired2 = TweenService:Create(Lighting["Blur"],TweenInfo.new(2.53),{Size = 8.3})
local BlurTweenNormal = TweenService:Create(Lighting["Blur"],TweenInfo.new(2.53),{Size = 0})
local ColorCorrectionTweenTired1 = TweenService:Create(Lighting.StaminaCorrection,TweenInfo.new(2.53),{Brightness = -0.52})
local ColorCorrectionTweenTired2 = TweenService:Create(Lighting.StaminaCorrection,TweenInfo.new(2.53),{Brightness = -0.33})
local ColorCorrectionTweenNormal = TweenService:Create(Lighting.StaminaCorrection,TweenInfo.new(2.53),{Brightness = 0})
local VignetteTweenCrouch = TweenService:Create(Vignette,TweenInfo.new(1),{ImageTransparency = 0.1})
local VignetteTweenUnCrouch = TweenService:Create(Vignette,TweenInfo.new(1),{ImageTransparency = 1})

-- << << Values >> >> --
local Stamina : Types.Stamina = 100;
local SprintSpeed : Types.SprintSpeed = 25;
local StaminaRefillRate : number = 0.10; -- Seconds
local StaminaDrainRate : number = 0.10; -- Seconds
local SprintingValue : BoolValue = CharValues:WaitForChild("Sprinting");
local CrouchingValue : BoolValue = CharValues:WaitForChild("Crouching");


local ExhaustedAnimTable = {
	[1] = "rbxassetid://14886171478",
	[2] = "rbxassetid://14886947351",
	[3] = "rbxassetid://14886962914",
	[4] = "rbxassetid://14891697103",
}

local function ExhaustCheck(currentStamina) --> Will Determine the Exhaust Animation Played; As the number gets higher, the more intense the animation
	if currentStamina <= 40 and currentStamina > 20 then
		return 1
	elseif currentStamina <= 20 and currentStamina > 10 then
		return 2
	elseif currentStamina <= 10 and currentStamina > 5 then
		return 3
	elseif currentStamina <= 5 then
		return 4
	end
end

RunService.RenderStepped:Connect(function()
	if Humanoid.MoveDirection.Magnitude == 0 and Stamina < 40 then
		if not ExhaustedIdle then
			ExhaustedTrack:Stop()
			ExhaustedIdle = true
			local Result = ExhaustCheck(Stamina)
			Exhausted.AnimationId = ExhaustedAnimTable[Result]
			ExhaustedTrack = Animator:LoadAnimation(Exhausted)
			ExhaustedTrack:Play(0.5)
		end
	else
		ExhaustedIdle = false
		ExhaustedTrack:Stop(0.5)
	end
end)

-- << << Functions >> >> --
local function InitSprintEssentials()
	local Sprint = Instance.new("Animation")
	Sprint.AnimationId = "rbxassetid://14254280099"
	Sprint.Name = "Sprint"
	
	local Crouch = Instance.new("Animation")
	Crouch.AnimationId = "rbxassetid://14891787439"
	Crouch.Name = "Crouch"
	
	local CrouchWalk = Instance.new("Animation")
	CrouchWalk.AnimationId = "rbxassetid://14891848801"
	CrouchWalk.Name = "CrouchWalk"
	
	SprintTrack = Animator:LoadAnimation(Sprint)
	SprintTrack.Priority = Enum.AnimationPriority.Action
	
	CrouchTrack = Animator:LoadAnimation(Crouch)
	CrouchTrack.Priority = Enum.AnimationPriority.Action
	
	CrouchWalkTrack = Animator:LoadAnimation(CrouchWalk)
	CrouchWalkTrack.Priority = Enum.AnimationPriority.Action
	
	Exhausted = Instance.new("Animation")
	Exhausted.AnimationId = ExhaustedAnimTable[math.random(1, #ExhaustedAnimTable)]
	Exhausted.Name = "Exhausted"
	ExhaustedTrack = Animator:LoadAnimation(Exhausted)

end

local function SprintKeys()
	return UserInputService:IsKeyDown(Enum.KeyCode.W)
end


local function Sprint(action, state, input)

	if action == "Sprint" then
		
		if state == Enum.UserInputState.Begin then
			
			if SprintKeys() and Humanoid.MoveDirection.Magnitude ~= 0 and Stamina > 0 and SprintingValue.Value == false and CrouchingValue.Value == false then
				
				SprintingValue.Value = true
				SprintTrack:Play(2, 2, 1)
				SprintSpeedT:Play()
				SprintFov:Play()

				repeat
					task.wait()
					if not SprintKeys() then 
						SprintingValue.Value = false
						SprintTrack:Stop(0.5, 2, 1)
						WalkSpeed:Play()
						WalkFov:Play()
						return 
					end
				until not SprintKeys()
				
			end
			
		elseif state == Enum.UserInputState.End and SprintingValue.Value == true then
			
			SprintingValue.Value = false
			SprintTrack:Stop(0.5, 2, 1)
			WalkSpeed:Play()
			WalkFov:Play()

		end
	end
	
end

local function Crouch(action , state , input)
	if action == "Crouch" then
		
		if state == Enum.UserInputState.Begin then
			
			if SprintingValue.Value == false and CrouchingValue.Value == false then
				
				CrouchingValue.Value = true
				CrouchTrack:Play(0.5)
				CrouchSpeed:Play()
				VignetteTweenCrouch:Play()
				
			elseif SprintingValue.Value == false and CrouchingValue.Value == true then
				
				CrouchingValue.Value = false
				CrouchTrack:Stop(0.5)
				WalkSpeed:Play()
				CrouchWalkTrack:Stop()
				VignetteTweenUnCrouch:Play()
			end
			
		end
		
	end
end


-- << Runner >> --

InitSprintEssentials()

-- << << Connections / Binding >> >> --

ContextActionService:BindAction(
	"Sprint",
	Sprint,
	false,
	Enum.KeyCode.LeftShift
)

ContextActionService:BindAction(
	"Crouch",
	Crouch,
	false,
	Enum.KeyCode.C
)

Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	if Humanoid.MoveDirection.Magnitude == 0 and SprintingValue.Value == true then
		
		SprintingValue.Value = false
		SprintTrack:Stop(0.5, 2, 1)
		WalkSpeed:Play()
		WalkFov:Play()
		
		
		return
	end
end)

Thread(function()
	while true do
		task.wait()
		
		if CrouchingValue.Value == true and Humanoid.MoveDirection.Magnitude ~= 0 then
			if CrouchWalkTrack.IsPlaying == false then
				CrouchWalkTrack:Play(0.5)
			end
		elseif CrouchingValue.Value == true and Humanoid.MoveDirection.Magnitude == 0 then
			CrouchWalkTrack:Stop()
		end
		
		if Stamina >= 0 and Stamina < 20 and SoundService.SFX.Char["Breathing_Stamina"].Volume == 0 then
			BreathingVolumePointFive:Play()
			repeat
				task.wait(1.34)
				ColorCorrectionTweenTired1:Play()
				BlurTweenTired1:Play()
				task.wait(1.34)
				BlurTweenTired2:Play()
				ColorCorrectionTweenTired2:Play()
			until Stamina > 20
			
			BreathingVolumeZero:Play()
			BlurTweenNormal:Play()
			ColorCorrectionTweenNormal:Play()
		end
		
	end
end)

Thread(function()
	while true do
		task.wait(0.01)
		
		--	>>
		
		if Stamina <= 0 then
			SprintingValue.Value = false
			SprintTrack:Stop(0.5, 2, 1)
			WalkSpeed:Play()
			WalkFov:Play()
		end
		
		if SprintingValue.Value == true and Stamina > 0 then
			Stamina = Stamina - StaminaDrainRate
						
			if Stamina < 0 then
				Stamina = 0
			end
			
		else
			if Stamina < 100 and Stamina > 0.25 then
				
				Stamina = Stamina + StaminaRefillRate
				if Stamina > 100 then
					Stamina = 100
				end
			elseif Stamina < 100 and Stamina < 0.25 then
				task.wait(2)
				Stamina = Stamina + StaminaRefillRate
			end
		end
		
		--  >>
	end
end)

-- << << Footsteps >> >> --

-- << MOVED TO ANIMATE SCRIPT >> >> --
