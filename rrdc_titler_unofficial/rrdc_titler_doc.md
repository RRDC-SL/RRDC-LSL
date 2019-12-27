# [SGD] Unofficial RRDC Titler v1.0.1 - User Manual #

---------------------------------------------------------------------------------------------------

## RP Character Spoofer Syntax: ##
    /4[</me|:|`>][((]<text>

**Examples:**

    /4This is an IC statement.
    /4/me makes an IC emote.
    /4:makes an IC emote.
    /4((This is an OOC statment.
    /4/me ((makes an OOC emote.
    /4:((makes an OOC emote.
    /4`This is narrated ICly.
    /4`((This is narrated OOCly.

* Note1: When your status is set OOC or AFK, all text is interpreted as OOC automatically.
* Note2: When chat redirect is enabled (provided RLV is enabled in viewer), local chat and
         emotes are automatically redirected through the spoofer. The exception is when
         you manually make an OOC statement; it will not redirect due to a safety feature
         of RLVa.

---------------------------------------------------------------------------------------------------

## Command Line Syntax: ##
    /2<command>[<arguments>][;<command>...]

* Note1: Only commands that take text or numeric arguments require a semicolon at the end.
         You can use spaces or even nothing between most commands and it will still work.
         Menu names can also be used as commands to bring up that specific menu, and
         leaving the argument blank for a command that takes one will open a menu or
         input box for that option.
* Note2: If you click 'Ignore' on an input box or a character select menu, your next
         command will be misrouted to the function the ignored input box or selection
         menu was associated with. This is a known limitation of the parser.

**Available Commands:**
    
    menu
Shows the main menu.

    help
Gives a copy of this notecard.

    new [<name>]
Create a new character. You can create up to 12.

    select [<partial-name>]
Switch to a different character.

    erase [<partial-name>]
Erase a character.

    name [<text>]
Set the name of the current character.

    prefix [<text>]
Sets a prefix that appears before the character's name.

    sex [<text>]
Sets the sex/gender of the current character.

    species [<text>]
Sets the species of the current character.

    misc<1|2|3|4> [<text>]
Sets any of the 4 misc text fields for the current character.

    cmdchan [<number>]
Changes the channel these commands are accepted on.

    rpchan [<number>]
Changes the channel of the RP character spoofer.

    status [<ic|ooc|afk>]
Sets your RP status.

    ic
Sets status to In-Character.

    ooc
Sets status to Out-Of-Character.

    afk
Sets status to Away-From-Keyboard.

    available
Sets RP availability to available. Shown while OOC.

    busy
Sets RP availability to unavailable.
    
    depth [<casual|story|either>] 
Sets the desired RP depth for the current character.

    casual
Sets a preference for casual RP for the current character.

    story
Sets a preference for story-driven RP for current character.

    either
Declares no RP depth preference for the current character. 

    intimacy [<dom|sub|switch|nonsex|nopref>]
Sets the desired type of intimacy for the current character.

    dom
Sets the current character as a dominant.

    sub
Sets the current character as a submissive.

    switch
Sets the current character as versatile/a switch.

    nonsex
Sets the current character as non-sexual.

    nopref
Declares no intimacy preference for the current character.

    role [<inmate|staff|genpop|violent|guard|biotech|engineer|genstaff>]
Sets the characters role within RRDC.

    genpop
Sets the current character as a general inmate (orange).

    violent
Sets the current character as a violent inmate (red).

    deviant
Sets the current character as a deviant inmate (lilac).

    guard
Sets the current character as a guard (blue).

    biotech
Sets the current character as a biotech (olive).

    engineer
Sets the current character as an engineer (gold).

    genstaff
Sets the current character as general staff (grey).

    show
Makes the titler hovertext visible.

    hide
Makes the titler hovertext invisible.

    blanks
Forces blank lines for empty titler fields to show.

    noblanks
Hides empty titler fields.

    speak
Sets the spoofer's chat volume to normal speech (20m).

    whisper
Sets the spoofer's chat volume to whispers (10m).

    redirecton
Enables redirect of local chat/emotes to spoofer (RLV).

    redirectoff
Disables local chat redirect (RLV).

    heightup
Increases the distance between the hovertext and the titler.

    heightdn
Decreases the distance between the hovertext and the titler.

---------------------------------------------------------------------------------------------------
