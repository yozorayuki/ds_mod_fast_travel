name = "Fast Travel"
version = "2.00"
description = "Build a fast travel network and travel instantly from sign post to sign post."
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
            {description = "Very low", data = 96},
            {description = "Low", data = 64},
            {description = "Normal", data = 32},
            {description = "High", data = 21.3},
            {description = "Very High", data = 16}
        },
        default = 32
    }
}
