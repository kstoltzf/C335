#PURPOSE: This program searches a set of data items for the index of a
# specific item.

#VARIABLES: The registers have the following uses:
#
# %edi - Holds the index of the data item being examined
# %ebx - Saves the index of the specific item being searched for
# %eax - Current data item

	.section .data

data_items:		# These are the data items
	.long 3,67,34,222,45,75,54,33,44,32,22,11,66,0

	.section .text

	.globl _start
_start:
	movl $0, %edi			# move 0 into the index register
	movl data_items(,%edi,4), %eax	# load the first byte of data

start_loop:				# start loop
	cmpl $0, %eax			# check to see if we've hit the end
	je loop_exit
	cmpl $54, %eax			# check if this is the desired item
	je loop_exit
	incl %edi			# increment index value
	movl data_items(,%edi,4), %eax	# load next data item
	jmp start_loop

loop_exit:
	movl %edi, %ebx			# move the value of the index stored in
					# %edi into %ebx
	# By storing this value in %ebx, we are able to output this value using
	# the command 'echo $?'
	movl $1, %eax			# 1 is the exit() syscall
	int $0x80