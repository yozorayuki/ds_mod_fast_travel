name = "Fast Travel"
version = "2.03"
description = "version " .. version .. "\nBuild a fast travel network and travel instantly from sign post to sign post."
author = "SoraYuki"
forumthread = ""

api_version = 6

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dont_starve_compatible = true
reign_of_giants_compatible = true
shipwrecked_compatible = true

priority = 0

configuration_options = {
    {
        name = "Travel_Cost",
        label = "Travel Cost",
        options = {
            {description = "X0.3", data = 106.7},
            {description = "X0.5", data = 64},
            {description = "X1.0", data = 32},
            {description = "X1.5", data = 21.3},
            {description = "X2.0", data = 16}
        },
        default = 32
    }
}
