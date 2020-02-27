// [SGD] RRDC Inmate Database Bridge Stub v1.0 - Copyright 2020 Alex Pascal (Alex Carpenter) @ Second Life.
// ---------------------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// =========================================================================================================

// System Configuration Variables
// ---------------------------------------------------------------------------------------------------------
integer g_appChan     = -89039937;                              // The channel for this application set.
// ---------------------------------------------------------------------------------------------------------

// getAvChannel - Given an avatar key, returns a static channel XORed with g_appChan.
// ---------------------------------------------------------------------------------------------------------
integer getAvChannel(key av)
{
    return (0x80000000 | ((integer)("0x"+(string)av) ^ g_appChan));
}

default
{
    state_entry()
    {
        llSetMemoryLimit(llGetUsedMemory() + 1024);
        llListen(g_appChan, "", "", ""); // Listen on the appChan.
    }

    listen(integer chan, string name, key id, string mesg)
    {
        // Request Syntax: ilistrequest <user-key>
        list l = llParseString2List(mesg, [" "], []);
        if (llToLower(llList2String(l, 0)) == "ilistrequest" && // Verify message is genuine request.
            llList2String(l, 1) == (string)llGetOwnerKey(id))
        {
            // Get the requested information here and put the reply below in the appropriate event.
            // We will assume the data came back and is in a list called 'inmateIDs'.
            // ----------------------------------------------------------------------------------------
            // list inmateIDs = [""]; // An empty list means the user isn't in the database yet.
            list inmateIDs = ["12345", "60993", "20309"];
            // ----------------------------------------------------------------------------------------
            // Reply sent on requestor's av channel for the collar. Use llRegionSayTo direct to object.
            // Note: CSV of the inmate number list cannot contain ANY spaces.
            // Reply Syntax: ilistresponse <user-key> <csv-of-inmate-numbers>
            llRegionSayTo(id, getAvChannel(llGetOwnerKey(id)), "ilistresponse " + 
                (string)llGetOwnerKey(id) + " " + llDumpList2String(inmateIDs, ",")
            );
        }
    }
}