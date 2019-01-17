SA = require "components/signable"
SA.Reload()

TA = require "components/travelable"
TA.Reload()

for k, v in pairs(SA) do
    print(k)
end

print(GetPlayer().Transform:GetWorldPosition())

print(IsDLCEnabled(3) and IsDLCEnabled(3) and GetInteriorSpawner():IsInInterior())

print(GetInteriorSpawner():IsInInterior())