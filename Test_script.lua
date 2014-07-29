--cameraState is set in the Lua startup script, and used by my open window scene.
--0 = uninit'd, 1 = day, 2 = night

threshold = 15

debug = 2
if cameraState then
	if debug >= 1 then
		luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=cameraStateExists:"..cameraState.."&priority=-1")
	end
else
	cameraState = 0
	if debug >= 1 then
		luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=Initing+cameraState&priority=-1")
	end
end

--get values
local lightValue = luup.variable_get("urn:micasaverde-com:serviceId:LightSensor1","CurrentLevel",34)

--logic
--it's bright, and the camera isn't in day mode, set it to day!
if ((tonumber(lightValue) > threshold) and (cameraState ~=1)) then
	if debug >= 1 then
		luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=Light+Level+is+"..lightValue.."+,+Set+the+camera+to+day+mode!&priority=-1")
	end
	luup.inet.wget("http://vera:crappylogin@192.168.1.113/param.cgi?action=update&ImageSource.I0.DayNight.ManualStatus=day")
	luup.log("Current Light is "..lightValue.." setting it to day!")
	cameraState = 1
	return true
	luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=Light+Level+is+"..lightValue.."+,+Set+the+camera+to+day+mode!&priority=-1")
end

--it's dark, and the camera isn't in day mode, set it to night!
if ((tonumber(lightValue) < threshold) and (cameraState ~=2)) then
	if debug >= 1 then
		luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=Light+Level+is+"..lightValue.."+,+Set+the+camera+to+night+mode!&priority=-1")
	end
	luup.inet.wget("http://vera:crappylogin@192.168.1.113/param.cgi?action=update&ImageSource.I0.DayNight.ManualStatus=night")
	luup.log("Current Light is "..lightValue.." setting it to night!")
	cameraState = 2
	return true
end

if debug >= 2 then
	luup.inet.wget("https://prowl.weks.net/publicapi/add?apikey=c45253cc541650abe369501d60cc24a188efdce1&application=Vera&event=Camera&description=Nothing+to+do.+Light+Value+is+"..lightValue.."!&priority=-1")
end

return false
