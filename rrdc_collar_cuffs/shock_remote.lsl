// [SGD] RRDC Shock Remote v1.1.0 - Copyright 2020 Alex Pascal & Raithsphere Starpaw @ Second Life.
// ---------------------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// =========================================================================================================
integer g_appChan       = -89039937;                        // The channel for this application.
integer g_collarHandle  = 0;                                // Listen handle for current target.
string  g_collarTarget  = "";                               // UUID of current target.
list    g_targetList    = [];                               // List of potential targets.
// ---------------------------------------------------------------------------------------------------------
integer g_powerLED      = 1;                                // Face for the power LED.
integer g_readyLED      = 2;                                // Face for the ready LED.
integer g_shockLED      = 3;                                // Face for the shock LED.
// ---------------------------------------------------------------------------------------------------------

// getAvChannel - Given an avatar key, returns a static channel XORed with g_appChan.
// ---------------------------------------------------------------------------------------------------------
integer getAvChannel(key av)
{
    return (0x80000000 | ((integer)("0x"+(string)av) ^ g_appChan));
}

default
{
    state_entry() // Init.
    {
        llSetMemoryLimit(llGetUsedMemory() + 2048);
        llListen(g_appChan, "", "", "");
    }

    on_rez(integer start) // Reset script on rez.
    {
        llResetScript();
    }

    touch_start(integer num) // Trigger for the selection prompt.
    {
        if (llDetectedKey(0) == llGetOwner())
        {
            g_targetList = []; // Clear target list.

            llOwnerSay("Scanning for inmates in range...");
            llSensor("", "", AGENT, 6.0, PI);
            llSetTimerEvent(1.0);
        }
    }

    sensor(integer num) // Scan for and query avatars.
    {
        integer i;
        for (i = 0; i < num; i++)
        {
            llSay(getAvChannel(llDetectedKey(i)), "inmatequery " + (string)llDetectedKey(i));
        }
    }

    timer() // Deliver the selection prompt if applicable.
    {
        llSetTimerEvent(0.0);
        if (llGetListLength(g_targetList) > 0)
        {
            string prompt = "Choose an inmate below:\n\n";
            list buttons = [];
            integer i;
            for (i = 0; i < llGetListLength(g_targetList); i+=2)
            {
                string name = llGetDisplayName(llList2Key(g_targetList, i+1));
                if (name == "???" || name == "") // Display name or user name.
                {
                    name = llKey2Name(llList2Key(g_targetList, i+1));
                }

                prompt += llList2String(g_targetList, i) + " -- " + name + "\n";
                buttons += [llList2String(g_targetList, i)];
            }

            llDialog(llGetOwner(), prompt, buttons, g_appChan);
        }
        else
        {
            llOwnerSay("Sorry, there are no valid inmates in range.");
        }
    }

    listen(integer chan, string name, key id, string mesg)
    {
        if (chan == g_appChan) // Protocol and select menu channel handling.
        {
            if (id == llGetOwner()) // Select a target menu response.
            {
                integer idx = llListFindList(g_targetList, [mesg]); // Find the target by inmate ID.
                if (idx >= 0)
                {
                    if (g_collarHandle) // Remove the old listen handle if there is one.
                    {
                        llListenRemove(g_collarHandle);
                    }
                    // Hook in and get menu.
                    g_collarTarget = llList2String(g_targetList, (idx + 1));
                    g_collarHandle = llListen(
                        getAvChannel((key)g_collarTarget), "", llGetOwner(), ""
                    );
                    llSay(getAvChannel((key)g_collarTarget), "getmenu " + g_collarTarget);
                }
                else
                {
                    llOwnerSay("Something went wrong, specified inmate could not be found.");
                }
            }
            else // Add reply from an inmate collar.
            {
                // Reply Syntax: inmatereply <user-key> <inmate-number>
                list l = llParseString2List(mesg, [" "], []);
                if (llToLower(llList2String(l, 0)) == "inmatereply" && // Genuine reply?
                    llList2String(l, 1) == (string)llGetOwnerKey(id) &&
                    llList2String(l, 2) != "00000" &&   // Inmate has a valid number.
                    llGetListLength(g_targetList) < 12) // And the list still has space?
                {
                    g_targetList += [llList2String(l, 2), (string)llGetOwnerKey(id)];
                    llSetTimerEvent(1.0);
                }
            }
        }
        else // Listen for collar menu button presses here.
        {
            if (mesg == "☠ Shock") // User activated the target's shock feature.
            {
                llSetColor(<0.0, 0.0, 0.0>, g_shockLED); // From Raithspere's script.
                llSetColor(<1.0, 0.0, 0.0>, g_readyLED);
                llTriggerSound("a530bfbe-1ee2-8d8e-12e5-b4d2b2cf0037", 1.0);
                llSleep(3.0);
                llSetColor(<0.0, 1.0, 1.0>, g_shockLED);
                llSleep(1.0);
                llSetColor(<0.0, 1.0, 0.0>, g_readyLED);
                llTriggerSound("0a942914-a743-e88a-66cd-ccec2cf43f6d", 0.5);
            }
        }
    }
}
