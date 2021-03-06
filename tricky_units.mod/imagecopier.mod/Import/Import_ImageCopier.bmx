Rem
  ImageCopier.bmx
  
  version: 17.06.19
  Copyright (C) 2015, 2017 Jeroen P. Broks
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

Strict
Import tricky_units.MKL_Version
Import brl.max2d

MKL_Version "Tricky's Units - ImageCopier.bmx","17.06.19"
MKL_Lic     "Tricky's Units - ImageCopier.bmx","ZLib License"

Rem
bbdoc: copies image
about: Rather than copying the pointer a complete new image is created.<p>Please note this feature may be incomplete, so use with care.
returns: The new image address
End Rem
Function CopyImage:TImage(Img:TImage)
	Local ret:TImage = CreateImage(img.width,img.height,Len(img.pixmaps),img.flags)
	RET.handle_x=Img.handle_x
	ret.handle_y=Img.handle_y
	For Local ak=0 Until Len(img.pixmaps) ret.pixmaps[ak] = CopyPixmap(img.pixmaps[ak]) Next ' This way the pixmap itself gets copied. Otherwise we'd only have the reference to the pixmap copied and that's not what we want!
	Return ret
End Function



