
# qadr-safe

[Sample Video](https://youtu.be/gQy4hqNDq1w)

![Preview](https://i.gyazo.com/386504a7ad557e94222324a462bcc8ce.png)

**How to use**

Set resource folder name to `qadr-safe`

And set `ensure qadr-safe` in your server.cfg

This resource converted from fivem to redm.

You can create as many locks as you want. 

It will be generated based on how many random numbers are provided to the **createSafe** function

Also, you shall only provide numbers **between 0 and 99**, otherwise it will be impossible to **finish the minigame properly!**
`````lua
--- @param combination table
--- @param milliseconds number | nil
local res = exports["qadr-safe"]:createSafe({math.random(0,99)}, 60000)
`````
*The final result is returned as soon as the minigame is finished*

*This code was originally developed in C#. You can access the original repository by clicking on the [following link](https://github.com/TimothyDexter/FiveM-SafeCrackingMiniGame)*

