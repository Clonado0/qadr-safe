local OnSpot = false
local IsMinigame = false
local SafeCrackingStates = "Setup"

local InitDialRotationDirection = "Clockwise"
local SafeCombination = {math.random(0, 99)}

local SafeLockStatus = {true}
local CurrentLockNum = 1
local ReqDialRotationDirection = InitDialRotationDirection
local SafeDialRotation = 3.6 * math.random(0, 100)


CurrentDialRotationDirection = InitDialRotationDirection
LastDialRotationDirection = InitDialRotationDirection

TimeLimit = 0 

local function sescal(dict, ses)
    local soundset_ref = dict or "Mud5_Sounds"
    local soundset_name = ses or  "Small_Safe_Unlock"
    local counter_i = 1

    while soundset_ref~=0 and not Citizen.InvokeNative(0xD9130842D7226045, soundset_ref, 0) and counter_i <= 300  do
        counter_i = counter_i + 1
        Citizen.Wait(0)
    end

    if soundset_ref == 0 or Citizen.InvokeNative(0xD9130842D7226045, soundset_ref, 0) then
        local ped = PlayerPedId()
        local ped_coords = GetEntityCoords(ped)
        local x,y,z =  table.unpack(ped_coords + GetEntityForwardVector(ped)*2.0)
        Citizen.InvokeNative(0xCCE219C922737BFA,soundset_name, x, y, z, soundset_ref, true, 0, true, 0)
    end
end

local function RelockSafe()
	SafeLockStatus = {}
	CurrentLockNum = 1
	ReqDialRotationDirection = InitDialRotationDirection
	OnSpot = false

	for i = 1, #SafeCombination do
		SafeLockStatus[i] = true
	end
end

local function SetSafeDialStartNumber()
	local dialStartNumber = math.random(0,100)
	SafeDialRotation = 3.6 * dialStartNumber
end

local function InitializeSafe(safeCombination, milliseconds)
	TimeLimit = GetGameTimer() + (milliseconds or 60000)
	SafeCombination = safeCombination
	RelockSafe()
	SetSafeDialStartNumber()
end

local function DrawTexture(textureStreamed,textureName,x, y, width, height,rotation,r, g, b, a, p11)
    if not HasStreamedTextureDictLoaded(textureStreamed) then
       RequestStreamedTextureDict(textureStreamed, false);
    else
        DrawSprite(textureStreamed, textureName, x, y, width, height, rotation, r, g, b, a, p11);
    end
end

local function DrawSprites(drawLocks)
	local textureDict = "qadr_safe_cracking"
	local _aspectRatio = 16/9 --GetAspectRatio(true)

	BgSetTextScale(0.1, _aspectRatio*0.2)
	BgDisplayText(VarString(10, 'LITERAL_STRING', ('Time Remaining: %2d seconds.'):format(math.floor((TimeLimit - GetGameTimer())/1000))), 0.73, 0.27)
	
	DrawTexture("des_safe_sml_l_fail+hi", "p_door_val_bankvault_small_ab", 0.8, 0.5, 0.3, _aspectRatio*0.3, 0, 250, 250, 250, 185)
	DrawTexture(textureDict, "Dial_BG", 0.8, 0.5, 0.2, _aspectRatio*0.2, 0, 255, 255, 255, 255)
	DrawTexture(textureDict, "Dial", 0.8, 0.5, 0.2, _aspectRatio*0.2, SafeDialRotation, 255, 255, 255, 255)

	if not drawLocks then
		return
	end

	local xPos = 0.933
	local yPos = 0.43

	local _kilittexturedic = "elements_stamps_icons"

	for _,lockActive in pairs(SafeLockStatus) do
		local lockString
		if lockActive then
			lockString = "stamp_locked_rank"
		else
			lockString = "stamp_unlocked_rank"
		end

		DrawTexture(_kilittexturedic,lockString,xPos,yPos,0.025,_aspectRatio*0.025,0,231,194,81,255)
		yPos = yPos + 0.05
	end
end

local function EndMiniGame(safeUnlocked)
	if safeUnlocked then
		sescal("Mud5_Sounds","Small_Safe_Unlock")
	end

	IsMinigame = false
	SafeCrackingStates = "Setup"
end

local function GetCurrentSafeDialNumber(currentDialAngle)
	local number = math.floor(100*(currentDialAngle/360))

	if number > 0 then
		number = 100 - number
	end

	return math.abs(number)
end

local function ReleaseCurrentPin()
	local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
	local pinUnlocked = SafeLockStatus[CurrentLockNum] and currentDialNumber == SafeCombination[CurrentLockNum]

	if not pinUnlocked then return end

	SafeLockStatus[CurrentLockNum] = false
	CurrentLockNum = CurrentLockNum + 1

	if ReqDialRotationDirection == "Anticlockwise" then
		ReqDialRotationDirection = "Clockwise"
	else
		ReqDialRotationDirection = "Anticlockwise"
	end

	if SafeLockStatus[CurrentLockNum] then
		sescal("Mud5_Sounds", "Small_Safe_Tumbler")
	else
		sescal("Mud5_Sounds", "Small_Safe_Tumbler_Final")
	end
end

local function RotateSafeDial(rotationDirection)
	if rotationDirection == "Anticlockwise" or rotationDirection == "Clockwise" then
		local multiplier
		local rotationPerNumber = 3.6
		if rotationDirection == "Anticlockwise" then
			multiplier = 1
		elseif rotationDirection == "Clockwise" then
			multiplier = -1
		end

		local rotationChange = multiplier * rotationPerNumber

		SafeDialRotation = SafeDialRotation + rotationChange

		if SafeDialRotation > 360 then
			SafeDialRotation = SafeDialRotation - 360
		elseif SafeDialRotation < 0 then
			SafeDialRotation = SafeDialRotation + 360
		end

		sescal("Mud5_Sounds", "Dial_Turn_Single")

	end

	CurrentDialRotationDirection = rotationDirection
	LastDialRotationDirection = rotationDirection
end

local function HandleSafeDialMovement()
	if IsDisabledControlJustPressed(0,0x7065027D) then
		RotateSafeDial("Anticlockwise")
	elseif IsDisabledControlJustPressed(0,0xB4E465B4) then
		RotateSafeDial("Clockwise")
	else
		RotateSafeDial("Idle")
	end
end

local function IsSafeUnlocked()
	return SafeLockStatus[CurrentLockNum] == nil
end

local function RunMiniGame()
	if SafeCrackingStates == "Setup" then
		SafeCrackingStates = "Cracking"
	elseif SafeCrackingStates == "Cracking" then
		local isDead = IsPedDeadOrDying(PlayerPedId(), false)

		if isDead then
			EndMiniGame(false)
			return false
		end


		DisableControlAction(0, 0x7065027D, true)
		DisableControlAction(0, 0x4D8FB4C1, true)
		DisableControlAction(0, 0xB4E465B4, true)
		DisableControlAction(0, 0xD27782E3, true)
		DisableControlAction(0, 0xFDA83190, true)
		DisableControlAction(0, 0x8FD015D8, true)

		if IsDisabledControlJustPressed(0, 0xD27782E3) then
			EndMiniGame(false)
			return false
		end

		if IsDisabledControlJustPressed(0, 0x8FD015D8) then
			if OnSpot then
				ReleaseCurrentPin()
				OnSpot = false
				if IsSafeUnlocked() then
					EndMiniGame(true)
					return true
				end
			else
				EndMiniGame(false)
				return false
			end
 		end

		HandleSafeDialMovement()

		local incorrectMovement = CurrentLockNum ~= 0 and 
			ReqDialRotationDirection ~= "Idle" and 
			CurrentDialRotationDirection ~= "Idle" and 
			CurrentDialRotationDirection ~= ReqDialRotationDirection

		if not incorrectMovement then
			local currentDialNumber = GetCurrentSafeDialNumber(SafeDialRotation)
			local correctMovement = ReqDialRotationDirection ~= "Idle" and (CurrentDialRotationDirection == ReqDialRotationDirection or LastDialRotationDirection == ReqDialRotationDirection)  
			if correctMovement then
				local pinUnlocked = SafeLockStatus[CurrentLockNum] and currentDialNumber == SafeCombination[CurrentLockNum]
				if pinUnlocked and not OnSpot then
					sescal("Mud5_Sounds","Small_Safe_Tumbler")
					OnSpot = true
				end
			end
		elseif incorrectMovement then
			OnSpot = false
		end
	end
end

local function createSafe(combination, milliseconds)
	local game = promise.new()

	IsMinigame = not IsMinigame
	RequestStreamedTextureDict("qadr_safe_cracking",false)
	RequestStreamedTextureDict("ui_startup_textures",false)

	if IsMinigame then
		InitializeSafe(combination, milliseconds)

		CreateThread(function()
			while IsMinigame do
				DrawSprites(true)
				local response = RunMiniGame()

				if response ~= nil then
					game:resolve(response)
					IsMinigame = false
					break
				end

				if TimeLimit - GetGameTimer() < 0 then
					game:resolve(false)
					IsMinigame = false
					break
				end

				Wait(0)
			end
		end)
		
	end

	return Citizen.Await(game)
end

RegisterCommand("createSafe",function()
	local ss = createSafe({math.random(0,99), math.random(0,99), math.random(0,99)})
	print(ss)
end)

exports("createSafe",createSafe)