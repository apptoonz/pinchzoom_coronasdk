function calculateDelta( previousTouches, event )
	local id,touch = next( previousTouches )
	if event.id == id then
		id,touch = next( previousTouches, id )
		assert( id ~= event.id )
	end

	local dx = touch.x - event.x
	local dy = touch.y - event.y

	midX=math.abs((touch.x + event.x)/2)
	midY=math.abs((touch.y + event.y)/2)
	
	offX=imageContainer.x-midX
	offY=imageContainer.y-midY
	
	return dx, dy,midX,midY,offX,offY
end

function loadImage()

	system.activate( "multitouch" )
	imageContainer=display.newContainer(2048,1536)
		
	chartImage=display.newImageRect("photo.jpg",2048,1536)	
	imageContainer:insert(chartImage)
	imageContainer:addEventListener( "touch", imageContainer )
	
	imageContainer.x=512
	imageContainer.y=386
	imageContainer.anchorChildren = true
	prevX=imageContainer.x
	prevY=imageContainer.y
	
	isMulti=false

	function imageContainer:touch( event )
		display.remove(buttonText)
		local scale
		local result = true
			local phase = event.phase
			local previousTouches = self.previousTouches

			local numTotalTouches = 1
			if ( previousTouches ) then
				-- add in total from previousTouches, subtract one if event is already in the array
				numTotalTouches = numTotalTouches + self.numPreviousTouches
				if previousTouches[event.id] then
					numTotalTouches = numTotalTouches - 1
				end
			end

			if "began" == phase then
				-- Very first "began" event
				imageContainer.xScaleOriginal=imageContainer.xScale
				if ( not self.isFocus ) then
					-- Subsequent touch events will target button even if they are outside the contentBounds of button
					display.getCurrentStage():setFocus( self )
					self.isFocus = true
					previousTouches = {}
					self.previousTouches = previousTouches
					self.numPreviousTouches = 0
					----ADDED BY CON TO ORIGINAL PINCHZOOM CODE
					startX=event.x
					startY=event.y
					--------------------------------
					
				elseif ( not self.distance ) then
					local dx,dy
					isMulti=true
					if previousTouches and ( numTotalTouches ) >= 2 then
						
						dx,dy,midX,midY,offX,offY = calculateDelta( previousTouches, event )
					end
					-- initialize to distance between two touches
					if ( dx and dy ) then
						local d = math.sqrt( dx*dx + dy*dy )
						if ( d > 0 ) then
							
							imageContainer.distance = d
							offCX=(imageContainer.width*imageContainer.xScale/2)-imageContainer.x
							offCY=(imageContainer.height*imageContainer.yScale/2)-imageContainer.y
							local newAnchorY=(midY+offCY)/(imageContainer.height*imageContainer.yScale)
							local newAnchorX=(midX+offCX)/(imageContainer.width*imageContainer.xScale)
							
							imageContainer.anchorX=newAnchorX
							imageContainer.anchorY=newAnchorY							
							imageContainer.x=imageContainer.x-offX
							imageContainer.y=imageContainer.y-offY
	
						end
					end
				end
				
				if not previousTouches[event.id] then
					self.numPreviousTouches = self.numPreviousTouches + 1
				end
				previousTouches[event.id] = event

			elseif self.isFocus then
				if "moved" == phase then
					if ( imageContainer.distance ) then
						local dx,dy
						if previousTouches and ( numTotalTouches ) >= 2 then
							dx,dy = calculateDelta( previousTouches, event )
						end
			
						if ( dx and dy ) then
							local newDistance = math.sqrt( dx*dx + dy*dy )
							modScale = newDistance / imageContainer.distance
							if ( modScale > 0 ) then
								----MODIFIED BY CON
								local newScale=imageContainer.xScaleOriginal * modScale
								-- uncomment below to set max and min scales
								maxScale,minScale=2,0.2
								if (newScale>maxScale) then 
									newScale=maxScale 
								end
								if (newScale<minScale) then 
									newScale=minScale 
								end

								imageContainer.xScale = newScale
								imageContainer.yScale = newScale
								-----------------------------
							end
						end
					----ADDED BY CON TO ORIGINAL PINCHZOOM CODE

					else
							local deltaX = prevX+event.x - startX
							local deltaY = prevY+event.y - startY
							imageContainer.x = deltaX
							imageContainer.y = deltaY	
							--limits on image movement													
							local limit=300
							local bounds = imageContainer.contentBounds 
							if (bounds.xMin>512+limit) then imageContainer.x=imageContainer.x-100 end
							if (bounds.yMin>376+limit) then imageContainer.y=imageContainer.y-100 end							
							if (bounds.xMax<512-limit) then imageContainer.x=imageContainer.x+100 end
							if (bounds.yMax<376-limit) then imageContainer.y=imageContainer.y+100 end
					---------------------------------
					end

					if not previousTouches[event.id] then
						self.numPreviousTouches = self.numPreviousTouches + 1
					end
					previousTouches[event.id] = event

				elseif "ended" == phase or "cancelled" == phase then									
					
					if previousTouches[event.id] then
						self.numPreviousTouches = self.numPreviousTouches - 1
						previousTouches[event.id] = nil
					end
					if (imageContainer.anchorX~=0.5) then
						axOff=imageContainer.anchorX-0.5
						ayOff=imageContainer.anchorY-0.5
						imageContainer.anchorX=0.5
						imageContainer.anchorY=0.5

						imageContainer.x=imageContainer.x-(axOff*(imageContainer.width*imageContainer.xScale))
						imageContainer.y=imageContainer.y-(ayOff*(imageContainer.height*imageContainer.yScale))

					end
					if ( #previousTouches > 0 ) then
						-- must be at least 2 touches remaining to pinch/zoom
						self.distance = nil

					else
						-- previousTouches is empty so no more fingers are touching the screen
						-- Allow touch events to be sent normally to the objects they "hit"
						display.getCurrentStage():setFocus( nil )
						self.isFocus = false
						self.distance = nil
						-- reset array
						self.previousTouches = nil
						self.numPreviousTouches = nil
						
						----ADDED BY CON TO ORIGINAL PINCHZOOM CODE
						-- Detecting a touch event or move event that's less than 12 pixels as a selection within the image
						if (math.abs(startX-event.x)<12) and (math.abs(startY-event.y)<12) and (not isMulti) then submitTouch(event.x,event.y) end
						prevX = imageContainer.x
						prevY = imageContainer.y

						----------------------------
					end
				end
			end
		end
		isMulti=false
		return result

end

function submitTouch(x,y)
	--use this for a single touch event
end

loadImage()
