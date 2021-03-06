Rem
        TUIC_Listbox.bmx
	(c) 2016 Jeroen Petrus Broks.
	
	This Source Code Form is subject to the terms of the 
	Mozilla Public License, v. 2.0. If a copy of the MPL was not 
	distributed with this file, You can obtain one at 
	http://mozilla.org/MPL/2.0/.
        Version: 16.06.12
End Rem

' 16.02.29 - Initial (yeah, Feb 29, the day we only have once in the four years, hehe).
' 16.06.12 - Adepted to BlitzMax NG
'          - Fixed incorrect items declaration


Rem
bbdoc: Creates a listbox. 
about: Though a parent for a screen is accepted mostly it's wiser not to go for this. These screen will not produce any events, but they simply handy to use as parent for all the buttons and other stuff you have on the screen. If the Image is set the screen will always contain this picture, please note though that the sizes of this pictures do not play a role in the size of the screen.
End Rem
Function TUI_CreateListBox:TUI_Gadget(x,y,w,h,parent:TUI_Gadget)
Local ret:TUI_Gadget = New TUI_Gadget
ret.kind = "ListBox"
ret.x = x
ret.y = y
ret.w = w
ret.h = h
ret.parent = parent
ret.enabledcolor 0,0,0
ret.alpha = .5
ret.items = New TList
ret.fselecteditem = -1
setparent parent,ret
Return ret
End Function



Type TUI_GDrvListbox Extends TUI_Gadgetdriver

	Method Run(G:TUI_Gadget,Enabled)
	' init
	Local px,py
	tui_parentcoords G,px,py
	SetImageFont g.font
	Local a:Double = GetAlpha()
	' Box
	SetAlpha Float(G.alpha)
	SetColor G.colors[(g.enabled And enabled),0],G.colors[(g.enabled And enabled),1],G.colors[(g.enabled And enabled),2]
	DrawRect G.x+px,G.y+py,g.w,g.h
	SetAlpha Float(a)
	SetColor G.colors[(g.enabled And enabled)+2,0],G.colors[(g.enabled And enabled)+2,1],G.colors[(g.enabled And enabled)+2,2]
	' Viewport
	Local ovpx,ovpy,ovpw,ovph,oox#,ooy#
	GetViewport ovpx,ovpy,ovpw,ovph
	GetOrigin oox,ooy '-g.scrolly
	SetViewport G.x+px,G.y+py,g.w,g.h
	SetOrigin G.x+px,G.y+py
	' Items
	Local y  = - G.ScrollY
	Local ii = -1
	Local it$	
	If Not G.Items
		Print "WARNING! Item list was Null"
		G.Items = New TList ' G.Items (how the hell did the original BlitzMax ever that this?)
		EndIf	
	For it = EachIn G.Items
		ii:+1
		If ((TUI_CID.MouseX>=px+G.X And TUI_CID.MouseX<=px+G.X+G.W And TUI_CID.MouseY>=(py+G.Y+y) And TUI_CID.MouseY<=(py+G.Y+G.H+y+TextHeight(it))) And TUI_CID.MouseHit[1]) Then G.selectitem ii
		If ii=G.FSelectedItem 
			SetColor G.colors[(g.enabled And enabled),0],G.colors[(g.enabled And enabled),1],G.colors[(g.enabled And enabled),2]
			DrawRect 0,y,g.w,TextHeight(it)
			SetColor G.colors[(g.enabled And enabled)+2,0],G.colors[(g.enabled And enabled)+2,1],G.colors[(g.enabled And enabled)+2,2]
			EndIf
		DrawText it,3,y
		y:+TextHeight(it)	
		Next
	' Restore originals
	SetOrigin oox,ooy
	SetViewport ovpx,ovpy,ovpw,ovph
	If ((TUI_CID.MouseX>=px+G.X And TUI_CID.MouseX<=px+G.X+G.W And TUI_CID.MouseY>=py+G.Y And TUI_CID.MouseY<=py+G.Y+G.H And TUI_CID.MouseHit[1]) Or (G.AltKey And TUI_CID.KeyHit[G.Altkey])) And G.Enabled TUI_ActivateGadget G	
	End Method

	Method ScrollUp(G:TUI_Gadget,md=1)
	G.ScrollY = G.ScrollY - 1
	End Method

	End Type

regtuidriver "ListBox",New TUI_GDrvListBox
