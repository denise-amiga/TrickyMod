Rem
  UPB_TList.bmx
  
  version: 18.01.20
  Copyright (C) 2017, 2018 Jeroen P. Broks
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:
  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
End Rem
Import "UPB_Core.bmx"

MKL_Version "Tricky's Units - UPB_TList.bmx","18.01.20"
MKL_Lic     "Tricky's Units - UPB_TList.bmx","ZLib License"

Type UPB_TList Extends UPB_DRIVER

	Method name$() Return "BlitzMax Linked List" End Method

	Method Recognize(O:Object)
		Return TList(O)<>Null
	End Method
	
	Method MakeList:TList(Ob:Object,Pref$="")
		Local r:TList = New TList
		Local p:TPixmap
		Local i:TImage
		For Local o:Object = EachIn TList(ob)
			If TPixmap(o)
				ListAddLast r,o
			ElseIf String(o)
				p = LoadPixmap(o)
				If p ListAddLast r,p
			ElseIf TImage(o)
				i=TImage(o)
				For p = EachIn i.pixmaps
					ListAddLast r,p
				Next
			EndIf
		Next
		Return r
	End Method
	
End Type	
			
New UPB_Tlist
