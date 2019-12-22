// [SGD] RRDC Collar Script v0.25 - Copyright 2019 Alex Pascal (Alex Carpenter) @ Second Life.
// ---------------------------------------------------------------------------------------------------------
// This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. 
//  If a copy of the MPL was not distributed with this file, You can obtain one at 
//  http://mozilla.org/MPL/2.0/.
// =========================================================================================================

// Assets.
// ---------------------------------------------------------------------------------------------------------
string  g_whiteTex          =   "aaff45c0-a0ef-c00d-58cb-bff31860d7be"; // RRDC_Collar_Metals_Diffuse_Wte.
string  g_orangeTex         =   "658f1177-cede-3ea2-57f9-d50e2b1402e4"; // RRDC_Collar_Metals_Diffuse_Orange.
string  g_lilacTex          =   "25be29e2-cc69-1559-4ad9-511d130554b9"; // RRDC_Collar_Metals_Diffuse_Lilac.
string  g_blueTex           =   "7add76cf-24f4-a2d3-6102-c6338db891fc"; // RRDC_Collar_Metals_Diffuse_Blue.
string  g_blackTex          =   "8c61b3ad-2723-cc83-c454-e602a8258ed7"; // RRDC_Collar_Metals_Diffuse_Blk.
string  g_whiteCuffTex      =   "700b9155-5138-e4c7-d194-1db9a6c09861"; // RRDC_Cuff_Diffuse_Basic.
string  g_orangeCuffTex     =   "ec94158c-2455-be49-a07d-7604be76c933"; // RRDC_Cuff_Diffuse_Orange.
string  g_lilacCuffTex      =   "93628600-5364-0a17-fcd8-e617ddd731e5"; // RRDC_Cuff_Diffuse_Lilac.
string  g_blueCuffTex       =   "e84a056b-f95f-a0db-acf0-7354749bbc03"; // RRDC_Cuff_Diffuse_Blue.
string  g_blackCuffTex      =   "04c857b4-78d1-8add-3d45-c134e70afa8f"; // RRDC_Cuff_Diffuse_Black.
 
string  g_zapLoopSound      =   "27a18333-a425-30b1-1ab6-c9a3a3554903"; // soundZapLoop.
string  g_zapStopSound      =   "a4602ead-96f3-ee86-5e0f-63faeb1ed7cf"; // soundZapStop.
list    g_chainSteps        = [ "f729d711-085e-f899-a723-a4afefd6a7d0", // ChainStep001.
                                "1f08a669-11ac-96e0-0435-419d2ae01254", // ChainStep002.
                                "9da21f36-14b1-9e79-3363-fc9d241628ba", // ChainStep003.
                                "35154062-4f0d-a489-35d3-696d8004b0cc", // ChainStep004.
                                "93ce44ed-014d-6e58-9d7b-1c9c5242ac6c"  // ChainStep005.
                              ];
 
string  g_zapAnim           =   "animCollarZap";                        // Played during shock effect.
string  g_poseBackU         =   "cuffedArmsBackU_001";                  // Arms behind back U pose.
string  g_poseBackV         =   "cuffedArmsBackV_001";                  // Arms behind back V pose.
string  g_poseFrontX        =   "cuffedArmsFrontX_001";                 // Arms in front X pose.
string  g_poseFrontV        =   "cuffedArmsFrontV_002";                 // Arms in front V pose.
list    g_poseComboSet      = [ "cuffedArmsCollar001",                  // Arms in front V pose higher.
                                "cuffedNeckForward001"                  // Neck forward pose.
                              ];

// State Variables.
// ---------------------------------------------------------------------------------------------------------
integer g_appChan           = -89039937; // The channel for this application set.
integer g_useChainSteps     = TRUE;      // If FALSE, random chain steps are not played.
list    g_animList          = [];        // List of currently playing (base) anim names.
integer g_animToggle        = 0;         // 0 = A versions playing. 1 = B versions playing.
integer g_powerCore;                     // Link number of the power core FX prim.
integer g_leashingPoint;                 // Link number of the leashing point prim.
integer g_shacklesPoint;                 // Link number of the chain to shackles point prim.
integer g_ledLink;                       // Link number of the LED light.
integer g_ledState;                      // Tracks the current on-off state of the LED.
integer g_ledCount;                      // Tracks how long to wait to blink LED.
integer g_shockCount;                    // Tracks how long to keep shock active.
integer g_ankleChain;                    // If TRUE, ankle chain is active.
integer g_isShackled;                    // If TRUE, wrist to ankle shackle chain active.
integer g_leashedTo;                     // 0=Nothing,1=Collar,2=ChainGang,3=Cuffed.
list    g_curMenus;                      // Tracks current menu by user.
// ---------------------------------------------------------------------------------------------------------

// getAvChannel - Given an avatar key, returns a static channel XORed with g_appChan.
// ---------------------------------------------------------------------------------------------------------
integer getAvChannel(key av)
{
    return (0x80000000 | ((integer)("0x"+(string)av) ^ g_appChan));
}

// inRange - Returns TRUE if the object is less than 6m from our position.
// ---------------------------------------------------------------------------------------------------------
integer inRange(key object)
{
    return (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(object, [OBJECT_POS]), 0)) < 6.0);
}

// getAnimVersion - Given a toggle state, returns the anim version as a string.
// ---------------------------------------------------------------------------------------------------------
string getAnimVersion(integer toggle)
{
    if (toggle)
    {
        return "b";
    }
    return "a";
}

// playRandomSound - Plays a random chain sound.
// ---------------------------------------------------------------------------------------------------------
playRandomSound()
{
    llTriggerSound(llList2String(g_chainSteps, (integer)llFrand(llGetListLength(g_chainSteps))), 0.2);
}

// stopCurAnims - Stop all AO anims that are playing.
// ---------------------------------------------------------------------------------------------------------
stopCurAnims()
{
    llSetTimerEvent(0.0); // Stop timer, then anims.
    integer i;
    for (i = 0; i < llGetListLength(g_animList); i++)
    {
        llStopAnimation(llList2String(g_animList, i) + getAnimVersion(g_animToggle));
    }
    g_animList = [];
    llSetTimerEvent(0.2); // Restart timer.

    playRandomSound();
}

// giveCharSheet - Gives a copy of the character sheet to the user, if present.
// ---------------------------------------------------------------------------------------------------------
giveCharSheet(key user)
{
    if (llGetInventoryNumber(INVENTORY_NOTECARD)) // Notecard is present.
    {
        string note = llGetInventoryName(INVENTORY_NOTECARD, 0);

        // Make sure we can transfer a copy of the notecard to the toucher.
        if (llGetInventoryPermMask(note, MASK_OWNER) & (PERM_COPY | PERM_TRANSFER))
        {
            llOwnerSay("secondlife:///app/agent/" + ((string)user) + "/completename" +
                " has requested a copy of your character sheet.");

            llGiveInventory(user, note); // Offer notecard.
        }
        else
        {
            llInstantMessage(user, "No character sheet is available.");
        }
    }
    else // No notecard present.
    {
        llInstantMessage(user, "No character sheet is available.");
    }
}

// showMenu - Given a menu name string, shows the appropriate menu.
// ---------------------------------------------------------------------------------------------------------
showMenu(string menu, key user)
{
    integer i;
    for (i = 0; i < llGetListLength(g_curMenus); i += 3) // Updating existing and remove old.
    {
        if (llList2Key(g_curMenus, i) == user)
        {
            if (menu == "") // Access last used menu if menu argument is empty.
            {
                menu = llList2String(g_curMenus, (i + 2));
            }

            g_curMenus = llListReplaceList(g_curMenus, [(string)llGetTime(), menu], (i + 1), (i + 2));
        }
        else if (llList2Key(g_curMenus, i) != llGetOwner() &&
                 (llGetTime() - llList2Float(g_curMenus, (i + 1))) > 60.0)
        {
            g_curMenus = llDeleteSubList(g_curMenus, i, (i + 2));
            i -= 3;
        }
    }

    if (menu == "") // Ensure we always have a menu name.
    {
        menu = "main";
    }

    if (llListFindList(g_curMenus, [(string)user]) <= -1) // Add user if they are new.
    {
        g_curMenus += [(string)user, (string)llGetTime(), menu];
    }

    string text = "\n\nChoose an option:";
    list buttons = [];
    if (menu == "main") // Show main menu.
    {
        // Wearer Menu.
        // -----------------------------------------------
        // CharSheet        Shock           Poses
        // Ankle Chain      Chain Gang      Shackle Link
        // Cuff To          Grab Leash      Leash To
        // Textures         Sounds          Close
        //
        // Staff Menu.
        // -----------------------------------------------
        // CharSheet        Shock           Poses
        // Ankle Chain      Chain Gang      Shackle Link
        // Cuff To          Grab Leash      Leash To
        //
        // Inmate Menu.
        // -----------------------------------------------
        // CharSheet (Just give char sheet. No menu.)

        text = "Main Menu" + text;

        if (user == llGetOwner())
        {
            buttons = ["Textures",    "Sounds",     "Close",
                       "Cuff To",     "Grab Leash", "Leash To",
                       "Ankle Chain", "Chain Gang", "Shackle Link",
                       "CharSheet",   "Shock",      "Poses"];
        }
        else if (inRange(user))
        {
            buttons = ["Cuff To",     "Grab Leash", "Leash To",
                       "Ankle Chain", "Chain Gang", "Shackle Link",
                       "CharSheet",   "Shock",      "Poses"];
        }
        else // Only CharSheet option in menu, so just give CharSheet.
        {
            giveCharSheet(user);
            return;
        }
    }
    else if (menu == "poses")
    {
        text = "Pose Selection Menu" + text;
        buttons = [" ", " ", "↺ Main", "Back U", "Release", "ComboSet", "Front X", "Front V", "Back V"];
    }
    else if (menu == "textures")
    {
        text = "Texture Select Menu" + text;
        buttons = ["Blue", "Black", "↺ Main", "White", "Orange", "Lilac"];
    }
    else if (menu == "sounds")
    {
        text = "Walking Sound Effects Menu" + text + "\n\nCurrent setting: ";
        if (g_useChainSteps)
        {
            text += "Walk Sounds";
        }
        else
        {
            text += "Walk Muted";
        }
        buttons = ["Mute Walk", "Unmute Walk", "↺ Main"];
    }
    llDialog(user, text, buttons, getAvChannel(llGetOwner()));
}

default
{
    // Initialize collar in state_entry and run_time_permissions.
    // -----------------------------------------------------------------------------------------------------
    state_entry()
    {
        llSetMemoryLimit(llGetUsedMemory()+2048); // Limit memory for mono-compiled scripts.
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
            llListen(getAvChannel(llGetOwner()), "", "", "");
            llSetTimerEvent(0.2); // Start the timer.
        }
    }

    // Reacquire permissions on rez. Don't do a full reset/init.
    // ---------------------------------------------------------------------------------------------------------
    on_rez(integer s)
    {
        llRequestPermissions(llGetOwner(), 
            (PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION)
        );
    }

    // Show a menu to the toucher when touched.
    // ---------------------------------------------------------------------------------------------------------
    touch_start(integer num)
    {
        showMenu("main", llDetectedKey(0));
    }

    // Parse and interpret commands.
    // ---------------------------------------------------------------------------------------------------------
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
            giveCharSheet(id);
        }
        else if (inRange(id) || id == llGetOwner()) // Only parse these if we're in range/the wearer.
        {
            if (mesg == "Shock") // Shock feature.
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
                g_shockCount = 11; // 0.8 seconds, then 2.0 seconds.
                llSetTimerEvent(0.2);
            }
            else if (mesg == "Ankle Chain") // Draw chain between ankles.
            {
                if (g_ankleChain = !g_ankleChain)
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " attached your ankle chain.");

                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightankle inner leftankle inner");
                }
                else
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " removed your ankle chain.");

                    llWhisper(getAvChannel(llGetOwner()), "unlink leftankle inner");
                }
                playRandomSound();
            }
            else if (mesg == "Shackle Link") // Draw chains from wrists to ankles.
            {
                if (g_isShackled = !g_isShackled)
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " attached your shackle links.");

                    llWhisper(getAvChannel(llGetOwner()), "linkrequest leftankle outer leftwrist outer");
                    llWhisper(getAvChannel(llGetOwner()), "linkrequest rightankle outer rightwrist outer");
                }
                else
                {
                    llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                        " removed your shackle links.");

                    llWhisper(getAvChannel(llGetOwner()), "unlink leftwrist outer");
                    llWhisper(getAvChannel(llGetOwner()), "unlink rightwrist outer");
                }
                playRandomSound();
            }
            // Pose Commands.
            // -------------------------------------------------------------------------------------------------
            else if (mesg == "Poses") // Pose selection menu.
            {
                llOwnerSay("secondlife:///app/agent/" + ((string)id) + "/completename" +
                    " is interacting with your handcuffs.");

                showMenu("poses", id);
                return;
            }
            else if (mesg == "Back U") // Emitter is always leftwrist inner or collar shacklesPoint.
            { // linkrequest <dest-tag> <inner|outer> <src-tag> <inner|outer>
                stopCurAnims();
                g_animList = [g_poseBackU];
                // TODO: Unlink collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist outer leftwrist inner");
            }
            else if (mesg == "Back V")
            {
                stopCurAnims();
                g_animList = [g_poseBackV];
                // TODO: Unlink collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
            }
            else if (mesg == "Front X")
            {
                stopCurAnims();
                g_animList = [g_poseFrontX];
                // TODO: Unlink collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist outer leftwrist inner");
            }
            else if (mesg == "Front V")
            {
                stopCurAnims();
                g_animList = [g_poseFrontV];
                // TODO: Unlink collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
            }
            else if (mesg == "ComboSet") // Combination two poses.
            {
                stopCurAnims();
                g_animList = g_poseComboSet;
                // TODO: Link collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "linkrequest rightwrist inner leftwrist inner");
            }
            else if (mesg == "Release") // Release from pose.
            {
                stopCurAnims();
                // TODO: Unlink collar shackles point.
                llWhisper(getAvChannel(llGetOwner()), "unlink leftwrist inner"); // Unlink wrists.
            }
            else if (id == llGetOwner()) // Sound and texture commands are owner locked.
            {
                // Texture Commands.
                // ---------------------------------------------------------------------------------------------
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
                    llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_blueCuffTex);
                }
                else if (mesg == "Black")
                {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXTURE, 0, g_blackTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                    ]);
                    llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_blackCuffTex);
                }
                else if (mesg == "White")
                {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXTURE, 0, g_whiteTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                    ]);
                    llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_whiteCuffTex);
                }
                else if (mesg == "Orange")
                {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXTURE, 0, g_orangeTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                    ]);
                    llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_orangeCuffTex);
                }
                else if (mesg == "Lilac")
                {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXTURE, 0, g_lilacTex, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0
                    ]);
                    llWhisper(getAvChannel(llGetOwner()), "settexture allfour " + g_lilacCuffTex);
                }
                // Sound Commands.
                // ---------------------------------------------------------------------------------------------
                else if (mesg == "Sounds") // Turn chain walk sounds on/off.
                {
                    showMenu("sounds", id);
                    return;
                }
                else if (mesg == "Mute Walk")
                {
                    g_useChainSteps = FALSE;
                }
                else if (mesg == "Unmute Walk")
                {
                    g_useChainSteps = TRUE;
                }
            }
        }
        showMenu("", id); // Reshow current menu. Whitespace menu items end up here.
    }
    // Controls timed effects such as blinking light and shock.
    // ---------------------------------------------------------------------------------------------------------
    timer()
    {
        if (g_animList != []) // Persistent AO (0.2 seconds).
        {
            g_animToggle = !g_animToggle;

            integer i;
            for (i = 0; i < llGetListLength(g_animList); i++)
            {
                llStartAnimation(llList2String(g_animList, i) + getAnimVersion(g_animToggle));
                llStopAnimation(llList2String(g_animList, i) + getAnimVersion(!g_animToggle));
            }
        }

        if (g_shockCount > 0) // Shock effects.
        {
            if (g_shockCount == 10) // Ending effect.
            {
                llStopSound();
                llPlaySound(g_zapStopSound, 0.5);
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

        if (g_ledCount++ >= 4) // Blinking LED effects (1.0 seconds).
        {
            if (g_ledState = !g_ledState) 
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
            g_ledCount = 0;
        }
    }

    // Controls random chain sound effects.
    // ---------------------------------------------------------------------------------------------------------
    moving_start()
    {
        if (g_useChainSteps && (g_animList != [] || g_ankleChain || g_isShackled || g_leashedTo))
        {
            playRandomSound();
        }
    }

    moving_end()
    {
        if (g_useChainSteps && (g_animList != [] || g_ankleChain || g_isShackled || g_leashedTo))
        {
            playRandomSound();
        }
    }
}
