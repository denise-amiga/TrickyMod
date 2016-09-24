'A* Pathfinder (Version 1.82) by Patrick Lester. Used by permission.
'==================================================================
'Last updated 03/15/04

'This file has been converted to BlitzMax by Tricky (Jeroen Broks)
'December 16th, 2008
'It was further adepted by Tricky to make it all work inside a 
'module on June 26th, 2013
'(Please note that the explanations below are directly copied from the
'original .bb file and that they are not fully BMax compatible).


'An article describing A* and this code in particular can be found at:
'http://www.policyalmanac.org/games/aStarTutorial.htm

'If you want to use this AStar Library, you may do so free of charge so 
'long as the author byline (above) is retained. Thank you to CaseyC 
'at the Blitz Forums for suggesting the use of binary heaps for the open 
'list. Email comments and questions to Patrick Lester at 
'pwlester@policyalmanac.org.

'Setup
'-----
'1. Include "includes/aStarLibrary.bb" at the top of your program.

'2. Create an array called walkability(x,y) that contains information
'	about the walkability of each square/tile on your map, with
'	0 = walkable (the default value) and 1 = unwalkable. The array
'	should range from (0,0) in the upper left hand corner to 
'	(mapWidth-1,mapHeight-1) in the bottom right hand corner.

'3. Adjust the following variables at the top of the .declareVariables
'	subroutine below. All three should be made global.
'	- tileSize = the width and height of your square tiles in pixels
'	- mapWidth = the width of your map in tiles = x value in
'		walkability array.
'	- mapHeight = the height of your map in tiles = y value in
'		walkability array.


'Calling the functions
'---------------------
'There are three main functions

'1.	FindPath(unit.unit,targetX,targetY)
'	- unit.unit = unit that is doing the pathfinding
'	- targetX,targetY = location of the target destination (pixel based coordinates)

'	The FindPath() function returns whether a path could be found (1) or
'	if it's nonexistent (2). If there is a path, it stores it in a bank
'	called unit\pathBank.

'2.   CheckPathStepAdvance(unit.unit)
'	This function updates the current path.

'3.	ReadPath(unit.unit)
' 	This function reads the path data generated by FindPath() and returns
'	the x and y coordinates of the next step on the path. They are stored
'	as xPath and yPath. These coordinates are pixel coordinates 
'	on the screen. See the function for more info.

'==========================================================
'DECLARE VARIABLES
'#declareVariables

	Const WalkableDebug = False ' Debugs walkability
	
	'Adjust these variables to match your map dimensions (see "setup" above)
	Global tileSize = 1, mapWidth = 101, mapHeight = 101
	
	Rem
	'Create needed arrays
	'Global walkability[mapWidth+1+1,mapHeight+1+1] 'array that holds wall/obstacle information	
	Global openList[mapWidth*mapHeight+2+1] '1 dimensional array holding ID# of open list items
	Global whichList[mapWidth+1+1,mapHeight+1+1]  '2 dimensional array used to record 
		'whether a cell is on the open list or on the closed list.
	Global openX[mapWidth*mapHeight+2+1] '1d array stores the x location of an item on the open list
	Global openY[mapWidth*mapHeight+2+1] '1d array stores the y location of an item on the open list
	Global parentX[mapWidth+1+1,mapHeight+1+1] '2d array to store parent of each cell (x)
	Global parentY[mapWidth+1+1,mapHeight+1+1] '2d array to store parent of each cell (y)
	Global Fcost[mapWidth*mapHeight+2+1]	'1d array to store F cost of a cell on the open list
	Global Gcost[mapWidth+1+1,mapHeight+1+1] 	'2d array to store G cost for each cell.
	Global Hcost[mapWidth*mapHeight+2+1]	'1d array to store H cost of a cell on the open list		
	End Rem
	Global openlist[]
	Global whichlist[,]
	Global openx[]
	Global openy[]
	Global parentx[,]
	Global parenty[,]
	Global fcost[]
	Global gcost[,]
	Global hcost[]
	
	Rem
	bbdoc: This function setup up the max map bounderies. If not set, it's automatically called with parameters 1,101,10
	End Rem
	Function SetUpPathFinder(ts,mw,mh)
	openlist= New Int[mw*mh+2+1]
	whichlist = New Int[mw+1+1,mh+1+1]
	openx = New Int[mw*mh+2+1]
	openy = New Int[mw*mh+2+1]
	parentx = New Int[mw+1+1,mh+1+1]
	parenty = New Int[mw+1+1,mh+1+1]
	fcost = New Int[mw*mh+2+1]
	gcost = New Int[mw+1+1,mh+1+1]
	hcost = New Int[mw*mh+2+1]
	Mapwidth=mw
	mapheight=mh
	tilesize=ts
	If walkabledebug Print "Setting up map "+ts+": "+mw+"x"+mh
	End Function
	
	SetUpPathFinder(tilesize,mapwidth,mapheight)
	
	'Declare constants
	Global onClosedList = 10 'openList variable	
	Global onOpenList
	Const notfinished = 0, notStarted = 0, found = 1, nonexistent = 2' pathStatus constants 
	Const walkable = 0, unwalkable = 1' walkability array constants

Private 
Function WalkAbility(X,Y) Return PF_Block(X,Y) End Function
Public

Function WalkAbilityDebug()
Local o$[]=["_","X"]
Local l$= ""
Print "Mapformat: "+Mapwidth+"x"+MapHeight	
For Local y=0 To mapheight
	For Local x=0 To mapwidth
		l:+o[Walkability(X,Y)]
		Next
	Print Right("     "+y,5)+"> "+l
	l=""
	Next
End Function

'==========================================================
'FIND PATH: This function finds the path and saves it. Non-Blitz users please note,
'the first parameter is a pointer to a user-defined object called a unit, which contains all
'relevant info about the unit in question (its current location, speed, etc.). As an
'object-oriented data structure, types are similar to structs in C.
'	Please note that targetX and targetY are pixel-based coordinates relative to the
'upper left corner of the map, which is 0,0.
Function FindPath(unit:PathFinderUnit,targetX,targetY)
Local startX,StartY
Local newOpenListItemID
Local addedGCost
Local temp
Local m
Local path
Local pathx,pathy
Local tempx
If walkabledebug Walkabilitydebug
'1.	Convert location data (in pixels) to coordinates in the walkability array.
	startX = Floor(unit.xLoc/tileSize) ; startY = Floor(unit.yLoc/tileSize)	
	targetX = Floor(targetX/tileSize) ; targetY = Floor(targetY/tileSize)

'2.	Quick Path Checks: Under the some circumstances no path needs to
	'be generated ...

	'If starting location and target are in the same location...
	If startX = targetX And startY = targetY And unit.pathLocation > 0 Then Return found
	If startX = targetX And startY = targetY And unit.pathLocation = 0 Then Return nonexistent

	'If target square is unwalkable, return that it's a nonexistent path.
	If walkability(targetX,targetY) = unwalkable 'Then Goto noPath
		unit.xPath = startX 'startingX
		unit.yPath = startY 'startingY
		Return nonexistent
		EndIf

'3.	Reset some variables that need to be cleared
	If onClosedList > 1000000 'occasionally redim whichList
		Global whichList[mapWidth,mapHeight] ; onClosedList = 10
	End If	
	onClosedList = onClosedList+2 'changing the values of onOpenList and onClosed list is faster than redimming whichList() array
	onOpenList = onClosedList-1
	unit.pathLength = notstarted 'i.e, = 0
	unit.pathLocation = notstarted 'i.e, = 0
	Gcost[startX,startY] = 0 'reset starting square's G value to 0

'4.	Add the starting location to the open list of squares to be checked.
	Local numberOfOpenListItems = 1
	openList[1] = 1 'assign it as the top (and currently only) item in the open list, which is maintained as a binary heap (explained below)
	openX[1] = startX ; openY[1] = startY


'5.	Do the following until a path is found or deemed nonexistent.
	Repeat

	
'6.	If the open list is not empty, take the first cell off of the list.
	'This is the lowest F cost cell on the open list.
	If numberOfOpenListItems <> 0 Then

	'Pop the first item off the open list.
	Local parentXval = openX[openList[1]] ; 
	Local parentYVal = openY[openList[1]] 'record cell coordinates of the item
	whichList[parentXval,parentYVal] = onClosedList 'add the item to the closed list

	'Open List = Binary Heap: Delete this item from the open list, which
	'is maintained as a binary heap. For more information on binary heaps, see:
	'http://www.policyalmanac.org/games/binaryHeaps.htm
	numberOfOpenListItems = numberOfOpenListItems - 1 'reduce number of open list items by 1	
	openList[1] = openList[numberOfOpenListItems+1] 'move the last item in the heap up to slot #1
	Local v = 1	
	Repeat 'Repeat the following until the new item in slot #1 sinks to its proper spot in the heap.
		Local u = v	
		If 2*u+1 <= numberOfOpenListItems 'if both children exist
		 	'Check if the F cost of the parent is greater than each child.
			'Select the lowest of the two children.	
			If Fcost[openList[u]] >= Fcost[openList[2*u]] Then v = 2*u
			If Fcost[openList[v]] >= Fcost[openList[2*u+1]] Then v = 2*u+1		
		Else
			If 2*u <= numberOfOpenListItems 'if only child #1 exists
			 	'Check if the F cost of the parent is greater than child #1	
				If Fcost[openList[u]] >= Fcost[openList[2*u]] Then v = 2*u
			End If	
		End If
		If u<>v 'if parent's F is > one of its children, swap them
			Local temp = openList[u]
			openList[u] = openList[v]
			openList[v] = temp				
		Else
			Exit 'otherwise, exit loop
		End If	
	Forever

	
'7.	Check the adjacent squares. (Its "children" -- these path children
	'are similar, conceptually, to the binary heap children mentioned
	'above, but don't confuse them. They are different. Path children
	'are portrayed in Demo 1 with grey pointers pointing toward
	'their parents.) Add these adjacent child squares to the open list
	'for later consideration if appropriate (see various if statements
	'below).
	For Local b = parentYVal-1 To parentYVal+1
	For Local a = parentXval-1 To parentXval+1

	'If not off the map (do this first to avoid array out-of-bounds errors)
	If a <> -1 And b <> -1 And a <> mapWidth And b <> mapHeight

	'If not already on the closed list (items on the closed list have
	'already been considered and can now be ignored).			
	If whichList[a,b] <> onClosedList 
	
	'If not a wall/obstacle square.
	If walkability(a,b) <> unwalkable 
			
	'Don't cut across corners (this is optional)
	Local corner = walkable	
	If a = parentXVal-1 
		If b = parentYVal-1 
			If walkability(parentXval-1,parentYval) = unwalkable Or walkability(parentXval,parentYval-1) = unwalkable Then corner = unwalkable
		Else If b = parentYVal+1 
			If walkability(parentXval,parentYval+1) = unwalkable Or walkability(parentXval-1,parentYval) = unwalkable Then corner = unwalkable 
		End If
	Else If a = parentXVal+1 
		If b = parentYVal-1 
			If walkability(parentXval,parentYval-1) = unwalkable Or walkability(parentXval+1,parentYval) = unwalkable Then corner = unwalkable 
		Else If b = parentYVal+1 
			If walkability(parentXval+1,parentYval) = unwalkable Or walkability(parentXval,parentYval+1) = unwalkable Then corner = unwalkable 
		End If
	End If			
	If corner = walkable
	
	'If not already on the open list, add it to the open list.			
	If whichList[a,b] <> onOpenList	

		'Create a new open list item in the binary heap.
		newOpenListItemID = newOpenListItemID + 1' each new item has a unique ID #
		Local m = numberOfOpenListItems+1
		openList[m] = newOpenListItemID	 'place the new open list item (actually, its ID#) at the bottom of the heap
		openX[newOpenListItemID] = a ; openY[newOpenListItemID] = b 'record the x and y coordinates of the new item

		'Figure out its G cost
		If Abs(a-parentXval) = 1 And Abs(b-parentYVal) = 1 Then
			addedGCost = 14 'cost of going to diagonal squares	
		Else	
			addedGCost = 10 'cost of going to non-diagonal squares				
		End If
		Gcost[a,b] = Gcost[parentXval,parentYVal]+addedGCost
			
		'Figure out its H and F costs and parent
		Hcost[openList[m]] = 10*(Abs(a - targetx) + Abs(b - targety)) ' record the H cost of the new square
		Fcost[openList[m]] = Gcost[a,b] + Hcost[openList[m]] 'record the F cost of the new square
		parentX[a,b] = parentXval ; parentY[a,b] = parentYVal	'record the parent of the new square	
		
		'Move the new open list item to the proper place in the binary heap.
		'Starting at the bottom, successively compare to parent items,
		'swapping as needed until the item finds its place in the heap
		'or bubbles all the way to the top (if it has the lowest F cost).
		While m <> 1 'While item hasn't bubbled to the top (m=1)	
			'Check if child's F cost is < parent's F cost. If so, swap them.	
			If Fcost[openList[m]] <= Fcost[openList[m/2]] Then
				temp = openList[m/2]
				openList[m/2] = openList[m]
				openList[m] = temp
				m = m/2
			Else
				Exit
			End If
		Wend 
		numberOfOpenListItems = numberOfOpenListItems+1 'add one to the number of items in the heap

		'Change whichList to show that the new item is on the open list.
		whichList[a,b] = onOpenList


'8.	If adjacent cell is already on the open list, check to see if this 
	'path to that cell from the starting location is a better one. 
	'If so, change the parent of the cell and its G and F costs.	
	Else' If whichList(a,b) = onOpenList
	
		'Figure out the G cost of this possible new path
		If Abs(a-parentXval) = 1 And Abs(b-parentYVal) = 1 Then
			addedGCost = 14'cost of going to diagonal tiles	
		Else	
			addedGCost = 10 'cost of going to non-diagonal tiles				
		End If
		Local tempGcost = Gcost[parentXval,parentYVal]+addedGCost
		
		'If this path is shorter (G cost is lower) then change
		'the parent cell, G cost and F cost. 		
		If tempGcost < Gcost[a,b] Then 	'if G cost is less,
			parentX[a,b] = parentXval 	'change the square's parent
			parentY[a,b] = parentYVal
			Gcost[a,b] = tempGcost 	'change the G cost			

			'Because changing the G cost also changes the F cost, if
			'the item is on the open list we need to change the item's
			'recorded F cost and its position on the open list to make
			'sure that we maintain a properly ordered open list.
			For Local x = 1 To numberOfOpenListItems 'look for the item in the heap
			If openX[openList[x]] = a And openY[openList[x]] = b Then 'item found
				FCost[openList[x]] = Gcost[a,b] + HCost[openList[x]] 'change the F cost
				
				'See if changing the F score bubbles the item up from it's current location in the heap
				m = x
				While m <> 1 'While item hasn't bubbled to the top (m=1)	
					'Check if child is < parent. If so, swap them.	
					If Fcost[openList[m]] < Fcost[openList[m/2]] Then
						temp = openList[m/2]
						openList[m/2] = openList[m]
						openList[m] = temp
						m = m/2
					Else
						Exit 'while/wend
					End If
				Wend 
				
				Exit 'for x = loop
			End If 'If openX(openList(x)) = a
			Next 'For x = 1 To numberOfOpenListItems

		End If 'If tempGcost < Gcost(a,b) Then			

	End If 'If not already on the open list				
	End If 'If corner = walkable
	End If 'If not a wall/obstacle cell.	
	End If 'If not already on the closed list	
	End If 'If not off the map.	
	Next
	Next

'9.	If open list is empty then there is no path.	
	Else
		path = nonExistent ; Exit
	End If

	'If target is added to open list then path has been found.
	If whichList[targetx,targety] = onOpenList Then path = found ; Exit		

	Forever 'repeat until path is found or deemed nonexistent
	
	
'10.	Save the path if it exists. Copy it to a bank. 
	If path = found
		
		'a. Working backwards from the target to the starting location by checking
		'each cell's parent, figure out the length of the path.
		pathX = targetX ; pathY = targetY	
		Repeat
			tempx = parentX[pathX,pathY]		
			pathY = parentY[pathX,pathY]
			pathX = tempx
			unit.pathLength = unit.pathLength + 1	
		Until pathX = startX And pathY = startY
	
		'b. Resize the data bank to the right size (leave room to store step 0,
		'which requires storing one more step than the length)
		ResizeBank unit.pathBank,(unit.pathLength+1)*4

		'c. Now copy the path information over to the databank. Since we are
		'working backwards from the target to the start location, we copy
		'the information to the data bank in reverse order. The result is
		'a properly ordered set of path data, from the first step to the
		'last.	
		pathX = targetX ; pathY = targetY				
		Local cellPosition = unit.pathLength*4 'start at the end	
		While Not (pathX = startX And pathY = startY)			
			PokeShort unit.pathBank,cellPosition,pathX 'store x value	
			PokeShort unit.pathBank,cellPosition+2,pathY 'store y value	
			cellPosition = cellPosition - 4 'work backwards		
			tempx = parentX[pathX,pathY]
			pathY = parentY[pathX,pathY]
			pathX = tempx
		Wend	
		PokeShort unit.pathBank,0,startX 'store starting x value	
		PokeShort unit.pathBank,2,startY 'store starting y value

	End If 'If path = found Then 


'11. Return info on whether a path has been found.
	Return path' Returns 1 if a path has been found, 2 if no path exists. 

'12.If there is no path to the selected target, set the pathfinder's
	'xPath and yPath equal to its current location and return that the
	'path is nonexistent.
'#noPath
	unit.xPath = startX
	unit.yPath = startY
	Return nonexistent

End Function
	

'==========================================================
'READ PATH DATA: These functions read the path data and convert
'it to screen pixel coordinates.
Function ReadPath(unit:PathFinderUnit)			
	unit.xPath = ReadPathX(unit:PathFinderUnit,unit.pathLocation)
	unit.yPath = ReadPathY(unit:PathFinderUnit,unit.pathLocation)
End Function

Function ReadPathX#(unit:PathFinderUnit,pathLocation)
	If pathLocation <= unit.pathLength
		Local x = PeekShort (unit.pathBank,pathLocation*4)
		Return tileSize*x + .5*tileSize 'align w/center of square	
	End If
End Function	

Function ReadPathY#(unit:PathFinderUnit,pathLocation)
	If pathLocation <= unit.pathLength
		Local y = PeekShort (unit.pathBank,pathLocation*4+2)
		Return tileSize*y + .5*tileSize 'align w/center of square		
	End If
End Function


'This function checks whether the unit is close enough to the next
'path node to advance to the next one or, if it is the last path step,
'to stop.
Function CheckPathStepAdvance(unit:PathFinderUnit)
	If (unit.xLoc = unit.xPath And unit.yLoc = unit.yPath) Or unit.pathLocation = 0
		If unit.pathLocation = unit.pathLength 
			unit.pathStatus = notstarted	
		Else 		
			unit.pathLocation = unit.pathLocation + 1
			ReadPath(unit) 'update xPath and yPath
		End If	
	End If	
End Function
