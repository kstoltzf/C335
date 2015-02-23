#--------------------------------------------------------
# Name: Kyle Stoltzfus
# Date: December 1, 2013
# Assignment: RA3
# This program makes the robot follow a wall on the left
# side of the robot. IT WILL NOT WORK FOR A WALL ON THE
# RIGHT SIDE. The robot checks for a wall to follow before
# it begins moving forward. If there is no wall close enough,
# the robot will not do anything. If there is a wall close by,
# the robot will turn toward the wall and begin following it.
# If the robot is in a closed course, it will remain in an
# infinite loop around the obstacle course.
#--------------------------------------------------------

	rinit			# initialize communication with robot
	rsens			# get robot sensor values
	jgt	Rb,$200,rturn	# check for obstacles
	jlt	R8,$30,rstop	# make sure robot has a wall to follow
	rspeed	$1,$1		# move robot forward

snsloop:
	rsens			# get robot sensor values
	jgt  	Rb,$200,rturn	# check for obstacles
	jgt	R8,$500,rturn	# keep robot from hitting wall
	jlt	R9,$200,lturn	# keep robot following wall
	jgt	R9,$200,rturn	# keep robot from hitting wall
	jmp 	snsloop

lturn:
	rspeed	$0,$1		# turn robot toward the wall
	jmp snsloop

rturn:
	rspeed	$1,$0		# turn robot away from the wall
	jmp snsloop

rstop:
	rspeed $0,$0		# stop the robot

end:
	jmp end