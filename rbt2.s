#--------------------------------------------------------
# Name: Kyle Stoltfus
# Date: November 25, 2013
# Assignment: RA2
# This program makes the robot follow a wall on the left
# side of the robot. IT WILL NOT WORK FOR A WALL ON THE
# RIGHT SIDE. The robot checks for a wall to follow before
# it begins moving forward. If there is no wall close enough,
# the robot will not do anything. If there is a wall close by,
# the robot will turn toward the wall and begin following it.
# The robot will follow the wall until it detects an obstacle
# in front of it. The robot will then stop before it hits
# the obstacle.
#--------------------------------------------------------

	rinit			# initialize communication with robot
	rsens			# get robot sensor values
	jgt	Rb,$500,rstop	# check for obstacles
	jlt	R8,$30,rstop	# make sure robot has a wall to follow
	rspeed	$1,$1		# move robot forward

snsloop:
	rsens			# get robot sensor values
	jgt  	Rb,$500,rstop	# check for obstacles
	jlt	R9,$500,lturn	# keep robot following wall
	jgt	R9,$500,rturn	# keep robot from hitting wall
	jmp 	snsloop

lturn:
	rspeed	$1,$2		# turn robot toward the wall
	jmp snsloop

rturn:
	rspeed	$2,$1		# turn robot away from the wall
	jmp snsloop

rstop:
	rspeed $0,$0		# stop the robot

end:
	jmp end