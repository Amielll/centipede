#####################################################################
#
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Author: Amiel Nurja
#
# Bitmap Display Configuration:
# -Unit width in pixels: 8
# -Unit height in pixels: 8
# -Display width in pixels: 256
# -Display height in pixels: 256
# -Base Address for Display: 0x10008000 ($gp)


.data

	# Player / Centipede data
	# Conventions:
	# centLoc[9] = centipede head
	# centDir: 1 = right		0 = dead		-1 = left
	playerLoc: 			.word 814
	centLoc: 			.word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 
	centDir:			.word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	dartSpawned:		.word 0
	dartLoc:			.word 0
	
	# Colours
	centColour:			.word 0xff0000		# red
	dartColour:			.word 0xdefffb		# light blue
	bgColour:			.word 0x000000		# black
	mushroomColour:		.word 0x964000		# brown
	
	# Screen
	displayAddress: 	.word 0x10008000
	screenWidth:		.word 32
	
.text

# Draws player's initial position and generates mushrooms
init_game:
	la $t0, playerLoc
	lw $t1, 0($t0)
	
	lw $t2, displayAddress
	li $t3, 0xffffffff
	
	sll $t4, $t1, 2		# For offset
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# Draw pixel (white)
	
	li $a1, 31
	li $a2, 32

# Game loop
main:
	jal update_cent
	jal update_dart
	jal check_keystroke
	jal delay
	j main

# Terminate program gracefully	
exit:
	li $v0, 10
	syscall

update_cent:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $a3, $zero, 10 # Loop count (10 cells)
	la $a1, centLoc
	la $a2, centDir
	lw $s0, 0($a1)		# Tail of centipede
	
	cent_loop:
		lw $t1, 0($a1)				# current centipede cell's location
		lw $t2, displayAddress
		lw $t3, centColour
		lw $t5, 0($a2)				# current centipede cell's direction
	
		sll $t4, $t1, 2 			# t4 is(cell's location * 4) to account for bias
		add $t4, $t2, $t4			# location relative to origin
	
		sw $t3, 0($t4)				# Draws red at initial location
		
		
		# Handle "wriggle"
		lw $t6, screenWidth
		div $t1, $t6
		mfhi $t3					# Store cell's location mod 32
		addi $t6, $t6, -1
		
		seq $t7, $t5, 1	
		seq $t8, $t3, $t6
		and $s1, $t7, $t8			# Cell is at right border and cannot move further in its direction
		
		seq $t7, $t5, -1
		seq $t8, $t3, $zero
		and $s2, $t7, $t8			# Cell is at left border and cannot move further in its direction
		
		
		add $t1, $t1, $t5			# Pre-wriggle location
		or $s3, $s1, $s2
		beq $s3, $zero, cont		# No wriggle required, continue
		
		
		sub $t1, $t1, $t5			# Have to wriggle, undo pre-wriggle movement			
		addi $t6, $t6, 1
		add $t1, $t1, $t6			# Cell moves 1 row down
		mul $t5, $t5, -1			# Flip the cell's direction
		
	cont:
		sw $t1, 0($a1)				# save location
		sw $t5, 0($a2)				# save direction
	
		addi $a1, $a1, 4 			# Point to next element in array (the next cell)
		addi $a2, $a2, 4
		addi $a3, $a3, -1			# Decrement loop counter
		bne $a3, $zero, cent_loop	
	
	# Erasing behind centipede tail
	lw $t7, bgColour
	sll $t4, $s0, 2
	add $t4, $t2, $t4
	
	sw $t7, 0($t4)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
check_keystroke:	# Detect if a key was pressed
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8 0xffff0000
	beq $t8, 1, get_key
	addi $t8, $zero, 0
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
get_key:		# Determine which key was pressed
	addi $sp,$sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0 		# Default case
	beq $t2, 0x6A, handle_j
	beq $t2, 0x6B, handle_k
	beq $t2, 0x78, handle_x
	beq $t2, 0x73, handle_s
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
handle_j:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, playerLoc
	lw $t1, 0($t0)
	
	lw $t2, displayAddress
	li $t3, 0x00000000
	
	sll $t4, $t1, 2		# For offset
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# Draw pixel (black)
	
	# Need to prevent player from moving beyond screen
	addi $t1, $t1, -1
	
update_player:
	sw $t1, 0($t0)		# Saves player location
	
	li $t3, 0xffffff
	
	sll $t4, $t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# Draw pixel (white)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
handle_k:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, playerLoc
	lw $t1, 0($t0)
	
	lw $t2, displayAddress
	li $t3, 0x00000000
	
	sll $t4, $t1, 2		# For offset
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# Draw pixel (black)
	
	# Need to prevent player from moving beyond screen
	addi $t1, $t1, 1
	b update_player
	
handle_x:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t5, dartSpawned		# Player can only shoot once old dart expires
	bne $t5, $zero, fin 
	
	
	addi $t5, $t5, 1
	sw $t5, dartSpawned		# Spawned dart
	
	lw $t1, playerLoc
	lw $t2, displayAddress
	lw $t3, dartColour
	
	addi $t1, $t1, -32  # Draw dart one pixel above player
	sll $t4, $t1, 2		# For offset
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# Draw pixel
	sw $t1, dartLoc		# Save dart location
	
	fin:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
		
	
handle_s:
	b update_player


		lw $t1, 0($a1)				# current centipede cell's location
		lw $t2, displayAddress
		lw $t3, centColour
		lw $t5, 0($a2)				# current centipede cell's direction
	
		sll $t4, $t1, 2 			# t4 is(cell's location * 4) to account for bias
		add $t4, $t2, $t4			# location relative to origin
	
		sw $t3, 0($t4)				# Draws red at initial location

update_dart:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, dartSpawned
	beq $t1, $zero, no_dart		# No dart to update
	
	lw $t2, displayAddress
	lw $t3, dartLoc
	lw $t5, dartColour
	lw $t6, bgColour
	
	# Erase behind dart
	sll $t4, $t3, 2
	add $t4, $t2, $t4
	sw $t6, 0($t4)
	
	
	addi $t3, $t3, -32 # New position (1 pixel higher)
	bltz $t3, remove_bullet
	sw $t3, dartLoc
	sll $t4, $t3, 2
	add $t4, $t2, $t4
	sw $t5, 0($t4)
	
	
	no_dart:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
	
	
	remove_bullet:
		li $t3, 0
		sw $t3, dartLoc
		addi $t1, $t1, -1
		sw $t1, dartSpawned
		b no_dart


delay:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $a1, 10000
	
	delay_loop:
		addi $a1, $a1, -1
		bgtz $a1, delay_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
