SA = require "components/signable"
SA.Reload()

TA = require "components/travelable"
TA.Reload()

for k, v in pairs(SA) do
    print(k)
end

for k,v in pairs(Signs) do print(k, v.components.signable:GetText(), v.ininterior) end

GetPlayer().Transform:SetPosition(Signs[1].Transform:GetWorldPosition())

print(GetPlayer().Transform:GetWorldPosition())

print(IsDLCEnabled(3) and IsDLCEnabled(3) and GetInteriorSpawner():IsInInterior())

print(GetInteriorSpawner():IsInInterior())