#--------------------------------------------------------
# Name: Kyle Stoltfus
# Date: November 21, 2013
# Assignment: RA1
# This assignment moves the robot in a straight line
# and stops the robot when it senses an obstacle in
# it's path.
#--------------------------------------------------------

	rinit			# initialize communication with robot
	rsens			# get robot sensor values
	jgt	Rb,$500,rstop	# check for obstacles
	rspeed	$1,$1		# move robot forward

snsloop:
	rsens			# get robot sensor values
	jgt  	Rb,$500,rstop	# check for obstacles
	jmp 	snsloop

rstop:
	rspeed	$0,$0		# stop robot

pend:
	jmp  pend		