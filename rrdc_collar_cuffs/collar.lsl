// [SGD] RRDC Collar Script v0.23 - Copyright 2019 Alex Pascal (Alex Carpenter) @ Second Life.
// ---------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// =============================================================================================

// Assets.
// ---------------------------------------------------------------------------------------------
string  g_whiteTex          = "RRDC_Collar_Metals_Diffuse_Wte";
string  g_orangeTex         = "RRDC_Collar_Metals_Diffuse_Orange";
string  g_lilacTex          = "RRDC_Collar_Metals_Diffuse_Lilac";
string  g_blueTex           = "RRDC_Collar_Metals_Diffuse_Blue";
string  g_blackTex          = "RRDC_Collar_Metals_Diffuse_Blk";
string  g_zapLoopSound      = "soundZapLoop";
string  g_zapStopSound      = "soundZapStop";
string  g_zapAnim           = "animCollarZap";

// State Variables.
// ---------------------------------------------------------------------------------------------
integer g_powerCore;                    // Link number of the power core FX prim.
integer g_leashingPoint;                // Link number of the leashing point prim.
integer g_shacklesPoint;                // Link number of the chain to shackles point prim.
integer g_ledLink;                      // Link number of the LED light.
integer g_ledState;                     // Tracks the current on-off state of the LED.
integer g_menuChan;                     // The channel to send menu commands on.
string  g_curMenu           = "main";   // Tracks the current menu.
integer g_shockCount;                   // Tracks how long to keep shock active.

string  g_noNoteMesg        = "No character sheet is available."; // Display when no notecard.
// ---------------------------------------------------------------------------------------------

// showMenu - Given a menu name string, shows the appropriate menu.
// ---------------------------------------------------------------------------------------------
showMenu(string menu, key user)
{
    g_curMenu = menu; // Last menu memory.

    string text = "\n\nChoose an option:";
    list buttons = [];
    if (menu == "main") // Show main menu.
    {
        text = "Main Menu" + text;
        buttons = ["CharSheet"];

        if (user == llGetOwner())
        {
            buttons += ["Shock", "Textures"];
        }
        else if (llVecDist(llGetPos(), // Shock option only available if within 6m.
                 llList2Vector(llGetObjectDetails(user, [OBJECT_POS]), 0)) < 6.0)
        {
            buttons += ["Shock"];
        }
    }
    else if (menu == "textures")
    {
        text = "Texture Select Menu" + text;
        buttons = ["Blue", "Black", "↺ Main", "White", "Orange", "Lilac"];
    }
    llDialog(user, text, buttons, g_menuChan);
}

default
{
    state_entry()
    {
        llSetMemoryLimit(llGetUsedMemory()+1024); // Limit memory for mono-compiled scripts.
        llRequestPermissions(llGetOwner(), 
            (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION)
        );
    }

    run_time_permissions(integer perm)
    {
        if (perm & (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION))
        {
            // Set the texture anim for the electric effects on the collar base.
            llSetLinkTextureAnim(LINK_THIS, ANIM_ON | LOOP, 2, 32, 32, 0.0, 64.0, 20.4);

            integer i; // Find the prims we will work with.
            for (i = 1; i <= llGetNumberOfPrims(); i++)
            {
                string name = llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]), 0);
                if (name == "powerCore")
                {
                    g_powerCore = i; // Also set texture anim for the power core.
                    llSetLinkTextureAnim(i, ANIM_ON | LOOP, ALL_SIDES, 20, 20, 0.0, 64.0, 30.4);
                }
                else if (name == "LED")
                {
                    g_ledLink = i;
                }
                else if (name == "leashingPoint")
                {
                    g_leashingPoint = i;
                }
                else if (name == "chainToShacklesPoint")
                {
                    g_shacklesPoint = i;
                }
            }

            llTakeControls( // Initial take of controls in passthrough, just to be safe.
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON,
                            FALSE, TRUE
            );

            // Start listening for menu.
            g_menuChan = (-1 * (0x80000000 | ((integer)("0x"+(string)llGetOwner()) ^ 89039937)));
            llListen(g_menuChan, "", "", "");
            llSetTimerEvent(1.0); // Start the timer.
        }
    }

    on_rez(integer s)
    {
        llRequestPermissions(llGetOwner(), 
            (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION)
        );
    }

    touch_start(integer num)
    {
        showMenu("main", llDetectedKey(0));
    }

    listen(integer chan, string name, key id, string mesg)
    {
        if (llGetOwnerKey(id) != id) // Only take commands from avatars.
        {
            return;
        }
        else if (mesg == "↺ Main") // Show main menu.
        {
            showMenu("main", id);
            return;
        }
        else if (mesg == "Close") // Close button does nothing but return.
        {
            return;
        }
        else if (mesg == "CharSheet") // Give notecard.
        {
            if (llGetInventoryNumber(INVENTORY_NOTECARD)) // Notecard is present.
            {
                string note = llGetInventoryName(INVENTORY_NOTECARD, 0);

                // Make sure we can transfer a copy of the notecard to the toucher.
                if (llGetInventoryPermMask(note, MASK_OWNER) & (PERM_COPY | PERM_TRANSFER))
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " has requested a copy of your character sheet.");

                    llGiveInventory(id, note); // Offer notecard.
                }
                else
                {
                    llInstantMessage(id, g_noNoteMesg);
                }
            }
            else // No notecard present.
            {
                llInstantMessage(id, g_noNoteMesg);
            }
            return;
        }
        else if (mesg == "Shock" && (llVecDist(llGetPos(), // Deliver shock. Locks av in place momentarily.
                 llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0)) < 6.0))
        {
            llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                " just activated your shock collar!");

            llSetTimerEvent(0.0);
            llTakeControls(
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON,
                            TRUE, FALSE
            );
            llStartAnimation(g_zapAnim);
            llLoopSound(g_zapLoopSound, 0.5);
            g_shockCount = 2;
            llSetTimerEvent(0.8);
        }
        else if (id == llGetOwner()) // Texture commands are owner locked.
        {
            if (mesg == "Textures") // Texture select.
            {
                showMenu("textures", id);
                return;
            }
            else if (mesg == "Blue") // Set textures.
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXTURE, 0, g_blueTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                ]);
            }
            else if (mesg == "Black")
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXTURE, 0, g_blackTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                ]);
            }
            else if (mesg == "White")
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXTURE, 0, g_whiteTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                ]);
            }
            else if (mesg == "Orange")
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXTURE, 0, g_orangeTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                ]);
            }
            else if (mesg == "Lilac")
            {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXTURE, 0, g_lilacTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                ]);
            }
        }

        showMenu(g_curMenu, id); // Reshow current menu.
    }

    timer()
    {
        if (g_shockCount > 0) // Shock effects.
        {
            if (g_shockCount == 2) // Ending effect.
            {
                llStopSound();
                llPlaySound(g_zapStopSound, 0.5);
                llSetTimerEvent(1.0);
            }
            g_shockCount--;
        }
        else // Release controls when the anim is done.
        {
            llTakeControls(
                            CONTROL_FWD |
                            CONTROL_BACK |
                            CONTROL_LEFT |
                            CONTROL_RIGHT |
                            CONTROL_ROT_LEFT |
                            CONTROL_ROT_RIGHT |
                            CONTROL_UP |
                            CONTROL_DOWN |
                            CONTROL_LBUTTON |
                            CONTROL_ML_LBUTTON,
                            FALSE, TRUE
            );
        }

        if (g_ledState = !g_ledState) // Blinking LED effects.
        {
            llSetLinkPrimitiveParamsFast(g_ledLink, [
                PRIM_COLOR, ALL_SIDES, <0.3, 0.0, 0.0>, llGetAlpha(0), 
                PRIM_POINT_LIGHT, FALSE, ZERO_VECTOR, 0.5, 0.5, 0.1,
                PRIM_GLOW, ALL_SIDES, 0.0
            ]);
        }
        else
        {
            llSetLinkPrimitiveParamsFast(g_ledLink, [
                PRIM_COLOR, ALL_SIDES, <1.0, 0.0, 0.0>, llGetAlpha(0), 
                PRIM_POINT_LIGHT, TRUE, <1.0, 0.0, 0.0>, 0.35, 0.075, 0.1,
                PRIM_GLOW, ALL_SIDES, 1.0
            ]);
        }
    }
}