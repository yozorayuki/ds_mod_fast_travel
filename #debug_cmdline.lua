SA = require "components/signable"
SA.Reload()

TA = require "components/travelable"
TA.Reload()

for k, v in pairs(SA) do
    print(k)
end
