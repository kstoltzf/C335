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

	.section .data

#-------------------------------------------------------------------------
# Simulator Memory, 16-bit address, 64K max
#-------------------------------------------------------------------------
smem:
	.byte  0x05,0x20
        .long  0
        .byte  0x05,0x40
        .long  -1
        .byte  0x24,0x50
        .word  26
        .byte  0x24,0x50
        .word  38
        .byte  0x08,0x55
        .byte  0x1C,0x00
        .word  48
        .byte  0x0D,0x40
        .long  2863311530
        .byte  0x25,0x50
        .long  2309737967
        .byte  0x04,0x45
        .byte  0x05,0x50
        .long  34
        .byte  0x25,0x40
        .byte  0x05,0x20
        .long  -1
        .byte  0x1C,0x00
        .word  54
        .rept  65478
        .byte  0xFF
        .endr

#-------------------------------------------------------------------------
# Simulator registers, 16 32-bit registers
# Initialized to zero on boot
#-------------------------------------------------------------------------
sregs:
	.rept 16
	.long 0
	.endr

#-------------------------------------------------------------------------
# Operation dispatch table, one/op-code, 256 max
#
# Rd = Destination Register (0-15)
# Rs = Source Register (0-15)
# Iv = Immediate (actual) value
# Ma = Memory address
#
# Memory has a 16-bit address space, high-order bits of any indirect operation
# are discarded
#--------------------------------------------------------------------------
optbl:
	.long srinit 		#00 Robot Init
	.long srsns		#01 Read Sensors
	.long srspdr		#02 Robot Speed (Rd,Rs)
	.long srspdi		#03 Robot Speed (Iv,Iv)

	.long sldr		#04 load (Rd,Rs)
	.long sldi		#05 load (Rd,Iv)
	.long sldm		#06 load (Rd,Ma)
	.long sldmi		#07 load (Rd,Ma[Rs])
	.long sldri		#08 load (Rd,*Rs)

	.long sstrm		#09 store (Rd,Ma)
	.long sstrmi 		#0a store (Rd,Ma[Rs])
	.long sstrri		#0b store (Rd,*Rs)

	.long sandr		#0c and (Rd,Rs)
	.long sandi		#0d and (Rd,Iv)
	.long sandm		#0e and (Rd,Ma)
	.long sandmi		#0f and (Rd,Ma[Rs])
	.long sandri		#10 and (Rd,*Rs)

	.long sorr		#11 or (Rd,Rs)
	.long sori		#12 or (Rd,Iv)
	.long sorm		#13 or (Rd,Ma)
	.long sormi		#14 or (Rd,Ma[Rs])
	.long sorri		#15 or (Rd,*Rs)

	.long sxorr		#16 xor	(Rd,Rs)
	.long sxori		#17 xor (Rd,Iv)
	.long sxorm		#18 xor (Rd,Ma)
	.long sxormi		#19 xor (Rd,Ma[Rs])
	.long sxorri		#1a xor (Rd,*Rs)

	.long snot		#1b not (Rd)

	.long sjmp		#1c jump Ma
	.long sjgtr		#1d jump Ma if Rd > Rs
	.long sjltr		#1e jump Ma if Rd < Rs
	.long sjetr		#1f jump Ma if Rd = Rs
	.long sjet0		#20 jump Ma if Rd = 0
	.long sjgti		#21 jump Ma if Rd > Iv
	.long sjlti		#22 jump Ma if Rd < Iv
	.long sjeti		#23 jump Ma if Rd = Iv
	.long sjal		#24 jump Ma and link
	.long sjmpri		#25 jump *Rd

	.long saddr		#26 add (Rd,Rs)
	.long saddi		#27 add (Rd,Iv)
	.long saddm		#28 add (Rd,Ma)
	.long saddmi		#29 add (Rd,Ma[Rs])
	.long saddri		#2a add (Rd,*Rs)
	
	.rept 256 - ((. - optbl) / 4)
	.long notimp
	.endr

#---------------------------------------------------------------------------
# Misc. data
#---------------------------------------------------------------------------

# Control String for op-codes not yet implemented
nostr:
	.string "Not Implemented: %d\n"

# Temporary storage for simulated instruction pointer (IP)
ipsv:
	.long 0

# Control string for receiving sensor values from the robot
rsnscmd:
	.string "N\n"

# Control string for sending speed values to the robot
rspdcmd:
	.string "D,%d,%d\n"

# Buffer for storing speed values for the robot as ASCII strings
rspdbuf:
	.space 80

	
#----------------------------------------------------------------------------
# Simulator CPU: Fetch, Decode, Execute loop
#----------------------------------------------------------------------------
	.globl _start
	.section .text

_start:
	movl $0,%edi			# the simulated IP

fetch:
	movb smem(,%edi,1),%al		# fetch op-code
	andl $0xff,%eax			# clear high-order bits
	movl optbl(,%eax,4),%eax	# decode: get address of routine
	incl %edi			# bump IP to second instruction byte
	call *%eax			# execute the instruction

# Instructions must leave IP pointing to the next op-code

	jmp fetch


#-------------------------------------------------------------------------
# Instruction Execution Routines
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Initialize: establish communication with the robot or simulator
# Op-code: 00
#-------------------------------------------------------------------------
srinit:
        call open_pipes			# establish communication
	addl $1,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Sensors: get the data from the robot sensors
# Op-code: 01
#------------------------------------------------------------------------
srsns:
	pushl $rsnscmd			# push command to get
					# sensor data onto stack
	pushl $sregs+(8*4)		# push space to store
					# sensor data onto the stack
	call  sndRcv_0			# get sensor data
	addl  $8,%esp			# clear stack
	addl  $1,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Speed: send speed values stored in registers to the robot motors
# Op-code: 02
#-----------------------------------------------------------------------
srspdr:
	movb  smem(,%edi,1),%al		# get Rd and Rs indexes
	andl  $0xff,%eax		# clear high-order bits
	movl  %eax,%ebx			# copy Rd and Rs indexes
	andl  $0xf,%eax			# isolate Rs index
	sarl  $4,%ebx			# isolate Rd index
	movl  sregs(,%eax,4),%eax	# get Rs data
	movl  sregs(,%ebx,4),%ebx	# get Rd data
	pushl %ebx			# push speed value of
					# right motor onto stack
	pushl %eax			# push speed value of
					# left motor onto stack
	pushl $rspdcmd			# push command to set robot
					# motor speeds onto stack
	pushl $rspdbuf			# push space to store
					# speed values onto stack
	call  sprintf			# convert speed values
					# to ASCII strings
	pushl $sregs+(8*4)		# push robot data onto stack
	call  sndRcv_0			# set robot motor speeds
	addl  $20,%esp			# clear stack
	addl  $1,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Speed: send immediate (actual) speed values to the robot motors
# Op-code: 03
#-----------------------------------------------------------------------
srspdi:
	movl  smem+1(,%edi,1),%eax	# get Iv data
	movl  smem+5(,%edi,1),%ebx	# get next Iv data
	pushl %ebx			# push speed value of
					# right motor onto stack
	pushl %eax			# push speed value of
					# left motor onto stack
	pushl $rspdcmd			# push command to set robot
					# motor speeds onto stack
	pushl $rspdbuf			# push space to store
					# speed values onto stack
	call  sprintf			# convert speed values
					# to ASCII strings
	pushl $sregs+(8*4)		# push robot data onto stack
	call  sndRcv_0			# set robot motor speeds
	addl  $20,%esp			# clear stack
	addl  $9,%edi			# point IP to next op-code
	ret
	
#--------------------------------------------------------------------------
# Load: from the source register (Rs) into the destination register (Rd)
# Op-code: 04
#--------------------------------------------------------------------------
sldr:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	movl sregs(,%eax,4),%eax	# get Rs data
	sarl $4,%ebx			# isolate Rd index
	movl %eax,sregs(,%ebx,4)	# place Rs data into Rd
	incl %edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Load: immediate (actual) value (Iv) into the destination register (Rd)
# Op-code: 05
#-------------------------------------------------------------------------
sldi:
	movb smem(,%edi,1),%al		# get Rd index	
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+1(,%edi,1),%ebx	# get Iv data
	movl %ebx,sregs(,%eax,4)	# place Iv into Rd
	addl $5,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Load: from a memory address (Ma) into the destination register (Rd)
# Op-code: 06
#------------------------------------------------------------------------
sldm:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# shift right 4 bits
	movw smem+1(,%edi,1),%bx	# get Ma to read from
	andl $0xffff,%ebx		# clear high-order bits
	movl smem(,%ebx,1),%ebx		# read data from Ma
	movl %ebx,sregs(,%eax,4)	# move data into Rd
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Load: from a memory address indexed by the source register (Ma[Rs]) into
# the destination register (Rd)
# Op-code: 07
#-------------------------------------------------------------------------
sldmi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to read from
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit Ma
	movl smem(,%ecx,1),%ecx		# read data from Ma
	movl %ecx,sregs(,%ebx,4)	# store data in Rd
	addl $3,%edi			# point IP to next op-code
	ret
	
#-------------------------------------------------------------------------
# Load: from a memory address pointed to by the source register (Rs --> Ma)
# into the destination register (Rd)
# Op-code: 08
#-------------------------------------------------------------------------
sldri:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	andl $0xffff,%eax		# force 16-bit Ma
	movl smem(,%eax,1),%eax		# get data at Ma pointer
	movl %eax,sregs(,%ebx,4)	# place data in Rd
	incl %edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Store: the data in the destination register (Rd) into a memory
# address (Ma)
# Op-code: 09
#------------------------------------------------------------------------
sstrm:
	movb smem(,%edi,1),%al 		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movw smem+1(,%edi,1),%bx	# get Ma to store Rd data in
	andl $0xffff,%ebx		# clear high-order bits
	movl sregs(,%eax,4),%eax	# get Rd data
	movl %eax,smem(,%ebx,1)		# store Rd data at Ma
	addl $3,%edi			# point Ip to next op-code
	ret				

#------------------------------------------------------------------------
# Store: the data in the destination register (Rd) into a memory
# address indexed by the source register (Ma[Rs])
# Op-code: 0a
#------------------------------------------------------------------------
sstrmi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to store Rd data in
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit Ma
	movl sregs(,%ebx,4),%ebx	# get Rd data
	movl %ebx,smem(,%ecx,1)		# store Rd data at Ma
	addl $3,%edi			# point Ip to next op-code
	ret

#------------------------------------------------------------------------
# Store: the data in the destination register (Rd) into a memory
# address pointed to by the source register (Rs --> Ma)
# Op-code: 0b
#------------------------------------------------------------------------
sstrri:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%ebx,4),%ebx	# get Rd data
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	movl %ebx,smem(,%eax,1)		# store Rd data at Ma[Rs]
	incl %edi			# point Ip to next op-code
	ret
	
#------------------------------------------------------------------------
# AND: the data from the source register (Rs) and the data from the
# destination register (Rd)
# Op-code: 0c
#------------------------------------------------------------------------
sandr:	
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	movl sregs(,%eax,4),%eax	# get Rs data
	sarl $4,%ebx			# isolate Rd index
	andl %eax,sregs(,%ebx,4)	# AND Rs data with Rd data
	incl %edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# AND: an immediate (actual) value (Iv) and the data from the
# destination register (Rd)
# Op-code: 0d
#-------------------------------------------------------------------------
sandi:
	movb smem(,%edi,1),%al		# get Rd index	
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+1(,%edi,1),%ebx	# get Iv data
	andl %ebx,sregs(,%eax,4)	# AND Iv with Rd data
	addl $5,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# AND: the data from a memory address (Ma) and the destination register (Rd)
# Op-code: 0e
#------------------------------------------------------------------------
sandm:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# shift right 4 bits
	movw smem+1(,%edi,1),%bx	# get Ma to read from
	andl $0xffff,%ebx		# clear high-order bits
	movl smem(,%ebx,1),%ebx		# read data from Ma
	andl %ebx,sregs(,%eax,4)	# AND Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# AND: the data from a memory address indexed by the source register (Ma[Rs])
# and the destination register (Rd)
# Op-code: 0f
#-------------------------------------------------------------------------
sandmi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to read from
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit Ma
	movl smem(,%ecx,1),%ecx		# read data from Ma
	andl %ecx,sregs(,%ebx,4)	# AND Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# AND: the data from a memory address pointed to by the source register (Rs --> Ma)
# and the destination register (Rd)
# Op-code: 10
#-------------------------------------------------------------------------
sandri:	
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	andl $0xffff,%eax		# force 16-bit Ma
	movl smem(,%eax,1),%eax		# get data at Ma pointer
	andl %eax,sregs(,%ebx,4)	# AND Ma data with Rd data
	incl %edi			# point IP to next op-code
	ret

#--------------------------------------------------------------------------
# OR: the data from the source register (Rs) and the data from the
# destination register (Rd)
# Op-code: 11
#--------------------------------------------------------------------------
sorr:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	movl sregs(,%eax,4),%eax	# get Rs data
	sarl $4,%ebx			# isolate Rd index
	orl %eax,sregs(,%ebx,4)		# OR Rs data and Rd data
	incl %edi			# point IP to next op-code
	ret
	
#-------------------------------------------------------------------------
# OR: an immediate (actual) value (Iv) and the data from the
# destination register (Rd)
# Op-code: 12
#-------------------------------------------------------------------------
sori:
	movb smem(,%edi,1),%al		# get Rd index	
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+1(,%edi,1),%ebx	# get Iv data
	orl %ebx, sregs(,%eax,4)	# OR Iv with Rd data
	addl $5,%edi			# point IP to next op-code
	ret
	
#------------------------------------------------------------------------
# OR: the data from a memory address (Ma) and the destination register (Rd)
# Op-code: 13
#------------------------------------------------------------------------
sorm:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# shift right 4 bits
	movw smem+1(,%edi,1),%bx	# get Ma to read from
	andl $0xffff,%ebx		# clear high-order bits
	movl smem(,%ebx,1),%ebx		# read data from Ma
	orl %ebx,sregs(,%eax,4)		# OR Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# OR: the data from a memory address indexed by the source register (Ma[Rs])
# and the destination register (Rd)
# Op-code: 14
#-------------------------------------------------------------------------
sormi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to read from
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit Ma
	movl smem(,%ecx,1),%ecx		# read data from Ma
	orl %ecx,sregs(,%ebx,4)		# OR Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# OR: the data from a memory address pointed to by the source register (Rs --> Ma)
# and the destination register (Rd)
# Op-code: 15
#-------------------------------------------------------------------------
sorri:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	andl $0xffff,%eax		# force 16-bit Ma
	movl smem(,%eax,1),%eax		# get data at Ma pointer
	orl %eax,sregs(,%ebx,4)		# OR Ma data with Rd data
	incl %edi			# point IP to next op-code
	ret

#--------------------------------------------------------------------------
# XOR: the data from the source register (Rs) and the data from the
# destination register (Rd)
# Op-code: 16
#--------------------------------------------------------------------------
sxorr:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	movl sregs(,%eax,4),%eax	# get Rs data
	sarl $4,%ebx			# isolate Rd index
	xorl %eax,sregs(,%ebx,4)	# XOR Rs data and Rd data
	incl %edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# XOR: an immediate (actual) value (Iv) and the data from the
# destination register (Rd)
# Op-code: 17
#-------------------------------------------------------------------------
sxori:
	movb smem(,%edi,1),%al		# get Rd index	
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+1(,%edi,1),%ebx	# get Iv data
	xorl %ebx,sregs(,%eax,4)	# XOR Iv with Rd data
	addl $5,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# XOR: the data from a memory address (Ma) and the destination register (Rd)
# Op-code: 18
#------------------------------------------------------------------------
sxorm:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4, %eax			# shift right 4 bits
	movw smem+1(,%edi,1),%bx	# get Ma to read from
	andl $0xffff,%ebx		# clear high-order bits
	movl smem(,%ebx,1),%ebx		# read data from Ma
	xorl %ebx,sregs(,%eax,4)	# XOR Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# XOR: the data from a memory address indexed by the source register (Ma[Rs])
# and the destination register (Rd)
# Op-code: 19
#-------------------------------------------------------------------------
sxormi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to read from
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit memory address
	movl smem(,%ecx,1),%ecx		# read data from Ma
	xorl %ecx,sregs(,%ebx,4)	# XOR Ma data with Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# XOR: the data from a memory address pointed to by the source register (Rs --> Ma)
# and the destination register (Rd)
# Op-code: 1a
#-------------------------------------------------------------------------
sxorri:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	andl $0xffff,%eax		# force 16-bit Ma
	movl smem(,%eax,1),%eax		# get data at Ma pointer
	xorl %eax,sregs(,%ebx,4)	# XOR Ma data with Rd data
	incl %edi			# point IP to next op-code
	ret

#--------------------------------------------------------------------------
# NOT: the data in the destination register (Rd)
# Op-code: 1b
#--------------------------------------------------------------------------
snot:
	movb smem(,%edi,1),%al 		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	notl sregs(,%eax,4)		# NOT Rd data
	incl %edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Jump: to a memory address (Ma)
# Op-code: 1c
#-------------------------------------------------------------------------
sjmp:
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

#-------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is greater than the data in the source register (Rs)
# Op-code: 1d
#-------------------------------------------------------------------------
sjgtr:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%ebx,4),%ebx	# get Rd data
	cmpl sregs(,%eax,4),%ebx	# compare Rd data and Rs data
	jle  sjgtrxit			# jump to exit code if
					# Rd data <= Rs data
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjgtrxit:				# exit without jumping
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is less than the data in the source register (Rs)
# Op-code: 1e
#-------------------------------------------------------------------------
sjltr:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%ebx,4),%ebx	# get Rd data
	cmpl sregs(,%eax,4),%ebx	# compare Rd data and Rs data
	jge  sjltrxit			# jump to exit code if
					# Rd data >= Rs data
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjltrxit:				# exit without jumping
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is equal to the data in the source register (Rs)
# Op-code: 1f
#-------------------------------------------------------------------------
sjetr:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%ebx,4),%ebx	# get Rd data
	cmpl sregs(,%eax,4),%ebx	# compare Rd data and Rs data
	jne  sjetrxit			# jump to exit code if
					# Rd data =/= Rs data
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjetrxit:				# exit without jumping
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is equal to 0
# Op-code: 20
#-------------------------------------------------------------------------
sjet0:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	cmpl $0,sregs(,%eax,4)		# compare Rd data and 0
	jne  sjet0xit			# jump to exit code if
					# Rd data =/= 0
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjet0xit:				# exit without jumping
	addl $3,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is greater than an immediate (actual) value (Iv) 
# Op-code: 21
#------------------------------------------------------------------------
sjgti:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+3(,%edi,1),%ebx	# get Iv data
	cmpl %ebx,sregs(,%eax,4)	# compare Rd data and Iv
	jle  sjgtixit			# jump to exit code if Rd
					# data <= Iv
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjgtixit:				# exit without jumping
	addl $7,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is less than an immediate (actual) value (Iv) 
# Op-code: 22
#------------------------------------------------------------------------
sjlti:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+3(,%edi,1),%ebx	# get Iv data
	cmpl %ebx,sregs(,%eax,4)	# compare Rd data and Iv
	jge  sjltixit			# jump to exit code if Rd
					# data >= Iv
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjltixit:				# exit without jumping
	addl $7,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Jump: to a memory address (Ma) if the data in the destination register
# (Rd) is equal to an immediate (actual) value (Iv) 
# Op-code: 23
#------------------------------------------------------------------------
sjeti:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+3(,%edi,1),%ebx	# get Iv data
	cmpl %ebx,sregs(,%eax,4)	# compare Rd data and Iv
	jne  sjetixit			# jump to exit code if Rd
					# data =/= Iv
	movw smem+1(,%edi,1),%ax	# get Ma to jump to
	andl $0xffff,%eax		# clear high-order bits
	movl %eax,%edi			# put Ma to jump to into IP
	ret

sjetixit:				# exit without jumping
	addl $7,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Jump: store current location of instruction pointer (IP) in the
# destination register (Rd) then jump to a memory address (Ma)
# Op-code: 24
#------------------------------------------------------------------------
sjal:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl %edi,sregs(,%eax,4)	# move IP into Rd
	addl $3,sregs(,%eax,4)		# point Ip to next op-code
	movw smem+1(,%edi,1),%bx	# get Ma to jump to
	andl $0xffff,%ebx		# clear high-order bits
	movl %ebx,%edi			# put Ma to jump to into IP
	ret

#-------------------------------------------------------------------------
# Jump: to the memory address (Ma) stored in the destination
# register (Rd)
# Op-code: 25
#-------------------------------------------------------------------------
sjmpri:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl sregs(,%eax,4),%edi	# put Ma to jump to into IP
	ret
	
#--------------------------------------------------------------------------
# Add: the data from the source register (Rs) and the data from the
# destination register (Rd)
# Op-code: 26
#--------------------------------------------------------------------------
saddr:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	movl sregs(,%eax,4),%eax	# get Rs data
	sarl $4,%ebx			# isolate Rd index
	addl %eax,sregs(,%ebx,4)	# add Rs data to Rd data
	incl %edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Add: an immediate (actual) value (Iv) and the data from the
# destination register (Rd)
# Op-code: 27
#-------------------------------------------------------------------------
saddi:	
	movb smem(,%edi,1),%al		# get Rd index	
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# isolate Rd index
	movl smem+1(,%edi,1),%ebx	# get Iv data
	addl %ebx,sregs(,%eax,4)	# add Iv to Rd data
	addl $5,%edi			# point IP to next op-code
	ret

#------------------------------------------------------------------------
# Add: the data from a memory address (Ma) and the destination register (Rd)
# Op-code: 28
#------------------------------------------------------------------------
saddm:
	movb smem(,%edi,1),%al		# get Rd index
	andl $0xff,%eax			# clear high-order bits
	sarl $4,%eax			# shift right 4 bits
	movw smem+1(,%edi,1),%bx	# get Ma to read from
	andl $0xffff,%ebx		# clear high-order bits
	movl smem(,%ebx,1),%ebx		# read data from Ma
	addl %ebx,sregs(,%eax,4)	# add Ma data to Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Add: the data from a memory address indexed by the source register (Ma[Rs])
# and the destination register (Rd)
# Op-code: 29
#-------------------------------------------------------------------------
saddmi:
	movb smem(,%edi,1),%al 		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movw smem+1(,%edi,1),%cx	# get Ma to read from
	andl $0xffff,%ecx		# clear high-order bits
	addl sregs(,%eax,4),%ecx	# determine Ma index
	andl $0xffff,%ecx		# force 16-bit Ma
	movl smem(,%ecx,1),%ecx		# read data from Ma
	addl %ecx,sregs(,%ebx,4)	# add Ma data to Rd data
	addl $3,%edi			# point IP to next op-code
	ret

#-------------------------------------------------------------------------
# Add: the data from a memory address pointed to by the source register (Rs --> Ma)
# and the destination register (Rd)
# Op-code: 2a
#-------------------------------------------------------------------------
saddri:
	movb smem(,%edi,1),%al		# get Rd and Rs indexes
	andl $0xff,%eax			# clear high-order bits
	movl %eax,%ebx			# copy Rd and Rs indexes
	andl $0xf,%eax			# isolate Rs index
	sarl $4,%ebx			# isolate Rd index
	movl sregs(,%eax,4),%eax	# get Ma pointer from Rs
	andl $0xffff,%eax		# force 16-bit Ma
	movl smem(,%eax,1),%eax		# get data at Ma pointer
	addl %eax,sregs(,%ebx,4)	# add Ma data to Rd data
	incl %edi			# point IP to next op-code
	ret
	
#-------------------------------------------------------------------------
# Not implemented: used to fill the op-code table
#-------------------------------------------------------------------------
notimp:
	addl $1, %edi			# point IP to next op-code
	ret
