// Original Staff Badge Script with additions by Alex Pascal.
// Changes:
//    CharSheet giver is now permissions safe.
//    Wearer now gets notified when a charsheet is taken.
//    Added option for wearer to get own charsheet.
//    Added script memory limit.

float txtCharSpacing = 0.03;
key textFont = "7910e702-2efc-78a5-aa78-ae0cbf3e03d4";

integer primN1;
integer primN2;
integer primP1;
integer primP2;

integer primID;

integer lMode = 0;


string txtChrIndex = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\n\n\n\n\n";

offsetTextures(integer prim, vector gO1, vector gO2, vector gO3, vector gO4, vector gO5, vector gO6, vector gO7, vector gO8)
{
    llSetLinkPrimitiveParamsFast(prim, [
        PRIM_TEXTURE, 0, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO1, 0.0,
        PRIM_TEXTURE, 1, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO2, 0.0,
        PRIM_TEXTURE, 2, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO3, 0.0,
        PRIM_TEXTURE, 3, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO4, 0.0,
        PRIM_TEXTURE, 4, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO5, 0.0,
        PRIM_TEXTURE, 5, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO6, 0.0,
        PRIM_TEXTURE, 6, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO7, 0.0,
        PRIM_TEXTURE, 7, textFont, <0.1 - txtCharSpacing, 0.1, 0>, gO8, 0.0
        
    ]);
}

vector getGridOffset(integer i)
{
    integer r = i / 10;
    integer c = i % 10;
    
    float x = -0.4515 + (0.1 * c);
    float y = 0.45 - (0.1 * r) + 0.00;
    
    return <x, y, 0.0>;
}

//#line 1 "D:/SL Stuff\\Scripty Shit\\D Lib\\d_lib_utilsLinkset.lsl"
integer findChildByName(string nName)
{
    integer i;
    for(i=1;i<=llGetNumberOfPrims();i++)
    {
        string pName = llGetLinkName(i);
        if(pName == nName)
            return i;
    }
    return 0; 
}

giveCharSheet(key user)
{
    if (llGetInventoryNumber(INVENTORY_NOTECARD)) // Notecard is present.
    {
        string note = llGetInventoryName(INVENTORY_NOTECARD, 0);

        // Make sure we can transfer a copy of the notecard to the toucher.
        if (llGetInventoryPermMask(note, MASK_OWNER) & (PERM_COPY | PERM_TRANSFER))
        {
            llOwnerSay("secondlife:///app/agent/" + ((string)user) + "/completename" +
                " has taken a copy of your character sheet.");

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

default
{
    on_rez(integer param)
    {
        llResetScript();
    }
    
    state_entry()
    {
        llSetMemoryLimit(llGetUsedMemory() + 1024);
        
        primN1 = findChildByName("n1");
        primN2 = findChildByName("n2");
        primP1 = findChildByName("p1");
        primP2 = findChildByName("p2");

        primID = findChildByName("id");
        
        llListen(524196, "", llGetOwner(), "");
    }
    
    touch_start(integer tNum)
    {
        key toucher = llDetectedKey(0);
        
        if(toucher == llGetOwner())
        {
            llDialog(toucher, "What do.", ["Name", "Position", "ID Num", "Image", "CharSheet"], 524196);
        }
        else
        {
            giveCharSheet(toucher);
        }
    }
    
    listen(integer chan, string name, key id, string str)
    {
        if(llGetOwnerKey(id) != llGetOwner())
            return;
        
        if (str == "CharSheet")
        {
            giveCharSheet(llGetOwner());
        }
        else if(str == "Image")
        {
            lMode = 0;
            llTextBox(id, "Enter new texture ID:", 524196);
        }
        else if(str == "Name")
        {
            lMode = 1;
            llTextBox(id, "Enter new name:", 524196);
        }
        else if(str == "Position")
        {
            lMode = 2;
            llTextBox(id, "Enter new position:", 524196);
        }
        else if(str == "ID Num")
        {
            lMode = 3;
            llTextBox(id, "Enter new ID number:", 524196);
        }
        else
        {
            if(lMode == 0)
            {
                llSetTexture((key)str, 1);
            }
            else if(lMode == 1)
            {
                string line = str;
                integer len = llStringLength(str);
                if(len < 16)
                {
                    integer lettersMissing = 16 - len;
                    
                    integer i;
                    for(i=0;i<lettersMissing;i++)
                        line = " "+line;
                }
                
                string partOne = llGetSubString(line, 0, 7);
                string partTwo = llGetSubString(line, 8, -1);
                
                vector gO1 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 0, 0)));
                vector gO2 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 1, 1)));
                vector gO3 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 2, 2)));
                vector gO4 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 3, 3)));
                vector gO5 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 4, 4)));
                vector gO6 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 5, 5)));
                vector gO7 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 6, 6)));
                vector gO8 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 7, 7)));
                offsetTextures(primN1, gO1, gO2, gO3, gO4, gO5, gO6, gO7, gO8);
                
                gO1 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 0, 0)));
                gO2 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 1, 1)));
                gO3 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 2, 2)));
                gO4 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 3, 3)));
                gO5 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 4, 4)));
                gO6 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 5, 5)));
                gO7 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 6, 6)));
                gO8 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 7, 7)));
                offsetTextures(primN2, gO1, gO2, gO3, gO4, gO5, gO6, gO7, gO8);
            }
            else if(lMode == 2)
            {
                string line = str;
                integer len = llStringLength(str);
                if(len < 16)
                {
                    integer lettersMissing = 16 - len;
                    
                    integer i;
                    for(i=0;i<lettersMissing;i++)
                        line = " "+line;
                }
                
                string partOne = llGetSubString(line, 0, 7);
                string partTwo = llGetSubString(line, 8, -1);
                
                vector gO1 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 0, 0)));
                vector gO2 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 1, 1)));
                vector gO3 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 2, 2)));
                vector gO4 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 3, 3)));
                vector gO5 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 4, 4)));
                vector gO6 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 5, 5)));
                vector gO7 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 6, 6)));
                vector gO8 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partOne, 7, 7)));
                offsetTextures(primP1, gO1, gO2, gO3, gO4, gO5, gO6, gO7, gO8);
                
                gO1 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 0, 0)));
                gO2 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 1, 1)));
                gO3 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 2, 2)));
                gO4 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 3, 3)));
                gO5 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 4, 4)));
                gO6 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 5, 5)));
                gO7 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 6, 6)));
                gO8 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(partTwo, 7, 7)));
                offsetTextures(primP2, gO1, gO2, gO3, gO4, gO5, gO6, gO7, gO8);
            }
            else if(lMode == 3)
            {
                string line = str;
                integer len = llStringLength(str);
                if(len < 5)
                {
                    integer lettersMissing = 5 - len;
                    
                    integer i;
                    for(i=0;i<lettersMissing;i++)
                        line = " "+line;
                }
                
                vector gO1 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(line, 0, 0)));
                vector gO2 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(line, 1, 1)));
                vector gO3 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(line, 2, 2)));
                vector gO4 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(line, 3, 3)));
                vector gO5 = getGridOffset(llSubStringIndex(txtChrIndex, llGetSubString(line, 4, 4)));
                offsetTextures(primID, gO1, gO2, gO3, gO4, gO5, ZERO_VECTOR, ZERO_VECTOR, ZERO_VECTOR);
            }
        }
    }
}

