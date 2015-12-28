--get values
local wattMeterDevice = 19
local porchLightDevice = 21
--porchStatus, 0 = off, 1 = on
local wattageThreshold = 200
local partyModeDevice = 45
local livingRoomMotionDevice = 33

local partyModeStatus = luup.variable_get("urn:upnp-org:serviceId:SwitchPower1", "Status", partyModeDevice)

--if party mode is on, then we don't want to turn the porch light off.
if( partyModeStatus =="1" ) then
	return false
end

local wattValue = luup.variable_get("urn:micasaverde-com:serviceId:EnergyMetering1","Watts",wattMeterDevice)
local porchStatus = luup.variable_get("urn:upnp-org:serviceId:SwitchPower1","Status",porchLightDevice)
local livingRoomMotionSensorArmed = luup.variable_get("urn:micasaverde-com:serviceId:SecuritySensor1", "Armed", livingRoomMotionDevice)
local bMovieOn = (tonumber(wattValue) > wattageThreshold)

local debug = false

if (debug) then
  local url = require("socket.url")
  local urlPrefix = "https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event="
  local urlEscapedEvent = url.escape(string.format("bMovieOn is "..tostring(bMovieOn).."."))
  local urlSuffix = "&priority=-2"
  luup.inet.wget(urlPrefix..urlEscapedEvent..urlSuffix)
end

local bChangedSomething = false

if (bMovieOn) then
  if (livingRoomMotionSensorArmed == "1") then
    luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Test&description=Sensor%20Disarmed%20!%20Wattage%20is%20"..wattValue.."&priority=-2")
    luup.variable_set("urn:micasaverde-com:serviceId:SecuritySensor1", "Armed", "0", livingRoomMotionDevice)
    movieModifiedMotionSensor = 1
    bChangedSomething = true
  end
else
  if (movieModifiedMotionSensor > 0 and livingRoomMotionSensorArmed == "0") then
    luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Test&description=Sensor%20Rearmed%20!%20Wattage%20is%20"..wattValue.."&priority=-2")
    luup.variable_set("urn:micasaverde-com:serviceId:SecuritySensor1", "Armed", "1", livingRoomMotionDevice)
    movieModifiedMotionSensor = 0
    bChangedSomething = true
  end
end

--if the porch light is on, or we've turned it off, run the wattage checks
if( porchStatus =="1" ) or movieModifiedPorchLight > 0 then
	if (bMovieOn) then
		luup.log("Current Wattage is "..wattValue..", which is > "..wattageThreshold.." turning it off!")
		--turn the light off
		luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget",{ newTargetValue="0" },porchLightDevice)
		--set the modified flag so we know we should keep checking to see if the wattage returns to < the threshold.
		movieModifiedPorchLight = 1
		bChangedSomething = true
	else
		--if wattage > threshold, AND we have turned the light off through the script, turn it back on.
		--this check prevents the script from turning the light on when it was turned off through some other means.
		if (movieModifiedPorchLight > 0) then
			luup.log("Current Wattage is "..wattValue..", which is < "..wattageThreshold..", turning it back on!")
			--turn the light on
			luup.call_action("urn:upnp-org:serviceId:SwitchPower1","SetTarget",{ newTargetValue="1" },porchLightDevice)
			--once it's back on, reset the modified flag so we don't keep checking the wattage if the light's off.
			movieModifiedPorchLight = 0
			--what we return doesn't really change anything since we do the switching in lua.
			bChangedSomething = true
		else
			luup.log("Current Wattage is "..wattValue..", and it's already on!")
		end
	end
else
	luup.log("Porch light is off already, not doing anything!")
end

return bChangedSomething
