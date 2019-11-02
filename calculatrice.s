################################################################################
## calculatrice.s
################################################################################
##
## Examples (assuming 'Mars4_5.jar' is present in the current directory):
## $ echo -en "10\n+\n10\n\n" java -jar Mars4_5.jar nc calculatrice.s
## $ java -jar Mars4_5.jar nc calculatrice.s <test_001.txt 2>/dev/null
## $ java -jar Mars4_5.jar nc calculatrice.s pa "integer"
## $ java -jar Mars4_5.jar nc calculatrice.s pa "float"
##
################################################################################
##
## Copyright (c) 2019 John Doe <user@server.tld>
## This work is free. It comes without any warranty, to the extent permitted by
## applicable law.You can redistribute it and/or modify it under the terms of
## the Do What The Fuck You Want To Public License, Version 2, as published by
## Sam Hocevar. See http://www.wtfpl.net/ or below for more details.
##
################################################################################
##        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##                    Version 2, December 2004
##
## Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>
##
## Everyone is permitted to copy and distribute verbatim or modified
## copies of this license document, and changing it is allowed as long
## as the name is changed.
##
##            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
##   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
##
##  0. You just DO WHAT THE FUCK YOU WANT TO.
################################################################################


################################################################################
# Misc.
################################################################################
#
# I/O
# ===
#
# Input is on stdin, the expected output (and only the expected output) is on
# stdout. The output on stderr does not matter.
#
# Float functions conventions
# ===========================
#
# - Use float registers ($f0, $f1, ..., $f12, $f13, ..., $f31)
# - Place function arguments in $f12, $f13, etc.
# - Place function results in $f0, $f1
# - Double values "take" two registers: use even numbered registers
#   ($f0, $f2, $f4, ..., $f30).
#
# Float <-> integer conversion
# ===========================
#
# Two steps:
# (1) convert into an integer (but the result is stored in a float register!)
# (2) move the converted value into the appropriate register
#
#   # Convert $f12 into an integer and store it in $f13:
#   cvt.w.s $f13, $f12
#   # Move the integer into an integer register:
#   mfc1 $a0 $f13
#
# Use mtc1 and cvt.s.w to reverse the process:
#
#   mtc1 $a0 $f0
#   cvt.s.w $f0 $f0
#
# Misc. recommendations
# =====================
#
# 1. Implement basic integer operations (+, -, /, *) and calculator_integer
# 2. Implement basic floating point operations (+, -, /, *) and calculator_float
#    (Set $v0 to 1 instead of 0 at 'ignore_cli_args' to "manually" switch into
#     float mode)
# 3. Complete handle_cli_args
#
################################################################################
# Data
################################################################################

.data

	# Floating point values
	fp0: 			.float 		0.0
	fp1: 			.float 		1.0
	fp2:			.float		2.0

	# Characters
	operators: 		.byte 		'+' '-' '*' '/'
	space: 			.byte 		' '
	operatorSpace: 		.space 		10

#-------------------------------------------------------------------------------
# Strings
#-------------------------------------------------------------------------------

# Misc.
	string_space: 		.asciiz		" "
	string_newline: 	.asciiz 	"\n"
	string_output_prefix: 	.asciiz 	"> "
	string_arg: 		.asciiz 	"arg: "
	string_calculator: 	.asciiz 	"calculator: "
	string_0:		.asciiz		"0"
	string_1:		.asciiz		"1"

# Cli args
	string_integer: 	.asciiz 	"integer"
	string_float: 		.asciiz 	"float"
	string_double: 		.asciiz 	"double"

# Operations
	string_min: 		.asciiz 	"min"
	string_max: 		.asciiz 	"max"
	string_pow: 		.asciiz 	"pow"
	string_abs: 		.asciiz 	"abs"
	
# Bonus
	string_print_binary:	.asciiz		"print_binary"
	string_print_hexa:	.asciiz		"print_hexa"
	print_significand:	.asciiz		"print_significand"
	print_exponent:		.asciiz		"print_exponent"
	string_switch_modes:	.asciiz		"switch_modes"
	string_opposite:	.asciiz		"opposite"
	string_inverse:		.asciiz		"inverse"
	hex_value:		.byte		'0' '0' '0' '0' '0' '0' '0' '0'
	mantissa_value:		.byte		'0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0' '0'

################################################################################
				# Text
################################################################################

.text
.globl __start

__start:

	# if no arguments are passed, ignore them
	beq 		$a0 		$0 		ignore_cli_args
	jal 		handle_cli_args
	# select calculator
	j 		calculator_selection

	ignore_cli_args:
  		li 		$v0 		0
		j 		calculator_selection
		
	switch_modes:
		beq		$v0		0		trigger_mode_float
		beq		$v0		1		trigger_mode_integer
		
	trigger_mode_float:
		li		$v0		0
		j 		calculator_selection
		
	trigger_mode_integer:
		li		$v0		1		
		
	calculator_selection: 
  		bne 		$v0 		$0 		calculator_select_float	
  		calculator_select_integer:
    			jal 		calculator_integer
    			j 		program_exit
    			
	  	calculator_select_float:
    			jal 		calculator_float
    			j 		program_exit
  		
  		calculator_select_default:
    			j program_exit

		program_exit:
  			li 		$v0 		10
  			syscall

################################################################################
				# Calculator main
################################################################################

	
	calculator_integer:
  		subu 		$sp 		$sp 		32
  		sw 		$ra 		0($sp)
  		sw 		$a0 		4($sp)
  		sw 		$a1 		8($sp)
  		sw 		$a2 		12($sp)
  		sw 		$s0 		16($sp)
  		sw 		$s1 		20($sp)
  		sw 		$s2 		24($sp)
  		sw 		$s3 		28($sp)

  	debugger_integer_mode_stderr:
  		la 		$a0 		string_calculator
  		jal 		print_string_stderr
  		la 		$a0 		string_integer
  		jal 		print_string_stderr
  		jal 		print_newline_stderr

  	calculator_integer_start:
  		# read first operand
    		jal 		read_int
    		# save it to $s0
    		move 		$s0 		$v0


  	calculator_integer_loop:
    		# read operation function and write to $a0
    		jal 		read_operator 
    		# check operator's length function
    		jal 		strlen	
    		# if operator's length greater than 4, go to find_advanced_operator
    		bge		$v0 		4 		find_advanced_operator
    		# save index in $s3
    		li 		$s3 		0
    		# load @ of operators array in $s1
    		la 		$s1		operators
    
        
    		find_basic_operator_loop:
    			# if index out of bounds
    			beq 		$s3 		4 		calculator_integer_exit
    			# load first operator into $a1
    			la		$a1 		0($s1)
    			# load desired character length into $a2
    			li  		$a2 		1
    			# execute simple_strncmp(string $a1, int $a2)
    			jal 		simple_strncmp      
    			# if operator found to be equal to the one in the input exit the loop
    			beq		$v0 		1 		execute_basic_operator
			# if not found increment to the next operator
   	 		addi 		$s1 		$s1 		1
   	 		# increment index
    			addi 		$s3 		$s3 		1
    			j 		find_basic_operator_loop
    
    		execute_basic_operator:
    			# read second operand
    			jal 		read_int
    			# save second operand to $a0
    			move 		$a0 		$v0
       			# move first operand to $a1
    			move 		$a1 		$s0
    
    			# redirect to target function based on the index reached in find_basic_operator_loop
    			beq 		$s3		0		add_integers
    			beq 		$s3		1		subtract_integers
    			beq 		$s3		2		multiply_integers
    			beq 		$s3		3		divide_integers
    		
    		# execute function
    		add_integers:
    			jal 		operation_integer_addition
    			j 		calculator_integer_loop_end
    
    		subtract_integers:
    			jal 		operation_integer_substraction
    			j		calculator_integer_loop_end
    
   		divide_integers:
    			jal 		operation_integer_division
    			j 		calculator_integer_loop_end
    
    		multiply_integers:
    			jal 		operation_integer_multiplication
    			j 		calculator_integer_loop_end
    		
		find_advanced_operator:
			# get operator's length
			jal 		strlen
			# get rid of the extra \0
			addi		$v0			$v0			-1
			# save operator's length in $a2
			move		$a2			$v0
			
			# check against "max"
			la	 	$a1			string_max
			jal 		simple_strncmp
			beq 		$v0			1			get_max
		
			# check against "min"
    			la 		$a1			string_min
			jal 		simple_strncmp
			beq 		$v0			1 			get_min
		
			# check against "abs"
			la 		$a1			string_abs
			jal 		simple_strncmp
			beq 		$v0			1 			get_abs
		
			#check against "pow"
			la 		$a1			string_pow
			jal 		simple_strncmp
			beq 		$v0			1 			get_pow
			
			j		continue_to_bonus_functions_integer
		
		
		# execute advanced operator function
		get_min:
			jal		move_ints
			jal 		operation_integer_minimum
			j 		calculator_integer_loop_end
		get_max:
			jal		move_ints	
			jal 		operation_integer_maximum
			j 		calculator_integer_loop_end		
		get_abs:
			# move first operand in $a0
			move 		$a0 		$s0
			jal 		operation_integer_abs
			j 		calculator_integer_loop_end
    		get_pow:
			jal		move_ints
			jal 		operation_integer_pow
			
			j		calculator_integer_loop_end
			
		move_ints:
			addi		$sp		$sp		-4
			sw		$ra		0($sp)
			
			move		$a0		$s0
			jal		read_int
			move		$a1		$v0
			
			lw		$ra		0($sp)
			addi		$sp		$sp		4
			jr		$ra
			
		continue_to_bonus_functions_integer:
			# load global trigger for unchecked functions
			li		$t7		0
			# set calculator mode in $v0
			li		$v0			1
			
			# check for "switch_modes" command
			jal		check_for_switch_string

			# check for "print_binary" command
			jal		check_for_print_binary_string
			
			# check for "print_hex" command
			jal		check_for_print_hexa_string
			
			# check for "opposite" command
			jal		check_for_opposite_string_integer
			
			# check for "inverse" command
			jal		check_for_inverse_string_integer
			
			beqz		$t1		unknown_operator
			
					
    		# loop or exit the program
    		calculator_integer_loop_end:
      			# set the result as new first arg
      			move 		$s0 		$v0
      			# print result
      			move 		$a0 		$v0
      			jal 		print_int
      			jal 		print_newline
      
      			# loop
      			j calculator_integer_loop

  	calculator_integer_exit:
    		lw 		$ra 		0($sp)
    		lw 		$a0 		4($sp)
    		lw 		$a1 		8($sp)
    		lw 		$a2 		12($sp)
    		lw 		$s0 		16($sp)
    		lw 		$s1 		20($sp)
    		lw 		$s2 		24($sp)
    		lw 		$s3 		28($sp)
    		addu 		$sp 		$sp 		32
    		jr 		$ra

########################################################################

########################################################################

	calculator_float:
  		subu 		$sp 			$sp 		24
  		sw 		$ra 			0($sp)
  		sw 		$a0 			4($sp)
  		swc1 		$f0 			8($sp)
  		swc1 		$f12 			12($sp)
  		swc1 		$f13 			16($sp)
  		swc1 		$f3 			20($sp)

  	debugger_float_mode_stderr:
  		la 		$a0 			string_calculator
  		jal 		print_string_stderr
  		la 		$a0 			string_float
  		jal 		print_string_stderr
  		jal 		print_newline_stderr

  	calculator_float_start:
    		# read first operand
    		jal 		read_float
      		mov.s 		$f3 		$f0

  		# calculator loop
  		calculator_float_loop:
	    		# read operation
    			jal 		read_operator
    			# check operation's length
    			jal 		strlen
    			# if length == 4 go to advanced operations
    			bge 		$v0 		4 		find_advanced_operator_float
        		# save index == 0 in $s3
    			add 		$s3 		$0 		$0
    			# load @ of array containing basic operators chars in $s1
    			la 		$s1		operators
    
    		find_basic_operator_loop_float:
    			# if nothing matched within our array of basic operations, exit the loop
    			beq 		$s3 		4 		calculator_integer_exit
    			# load first operation from our array
    			la		$a1 		0($s1)
    			# load length of substring to be checked
    			li  		$a2 		1
    			# execute string compare function
    			jal 		simple_strncmp      
    			# if a match has been found exit towards execution
    			beq		$v0 		1 		execute_basic_operator_float
    			# else check against next operator
    			addi 		$s1 		$s1		1
    			addi 		$s3 		$s3		1
    			# loop		
    			j 		find_basic_operator_loop_float
    			
    		execute_basic_operator_float:
    			# move first operand to $f12
    			mov.s 		$f12 		$f0
    			# read second operand
    			jal 		read_float
    			# move second operand to $f13
    			mov.s 		$f13 		$f0
    
    			# match index to the proper function
    			beq 		$s3		0		add_floats
    			beq 		$s3		1		subtract_floats
    			beq 		$s3		2		multiply_floats
    			beq 		$s3		3		divide_floats
    
    			# Compute the result and loop again
    			add_floats:
    				jal 		operation_float_addition
    				j 		calculator_float_loop_end
    
    			subtract_floats:
    				jal 		operation_float_substraction
    				j 		calculator_float_loop_end
    
   			divide_floats:
    				jal 		operation_float_division
    				j 		calculator_float_loop_end
    
    			multiply_floats:
    				jal 		operation_float_multiplication
    				j 		calculator_float_loop_end
    		
		find_advanced_operator_float:
			# get operator's length
			jal 		strlen
			# get rid of the extra \0
			addi		$v0			$v0			-1
			# save operator's length in $a2
			move		$a2			$v0
		
			# check against "max"
			la 		$a1			string_max
			jal 		simple_strncmp
			beq 		$v0			1 		get_max_float
		
			# check against "min"
    			la 		$a1			string_min
			jal 		simple_strncmp
			beq 		$v0			1 		get_min_float
		
			# check against "abs"
			la 		$a1			string_abs
			jal 		simple_strncmp
			beq 		$v0			1 		get_abs_float
		
			# check against "pow"
			la 		$a1			string_pow
			jal 		simple_strncmp
			beq 		$v0			1 		get_pow_float
			
			j		continue_bonus_functions_float
					
			# execute advanced operator function
			get_min_float:
				jal		move_floats
				jal 		operation_float_minimum
				j 		calculator_float_loop_end
				
			get_max_float:
				jal		move_floats
				jal 		operation_float_maximum
				j 		calculator_float_loop_end
						
			get_abs_float:
				mov.s 		$f12 				$f3
				jal 		operation_float_abs
				j 		calculator_float_loop_end
				
    			get_pow_float:
    				jal		move_floats
				jal 		operation_float_pow
				j 		calculator_float_loop_end
				
			move_floats:
				addi		$sp		$sp		-4
				sw		$ra		0($sp)
				
				mov.s		$f12		$f3
				jal		read_float
				mov.s		$f13		$f0
				
				lw		$ra		0($sp)
				addi		$sp		$sp		4
				jr	$ra
			
			continue_bonus_functions_float:

			# set calculator mode in $v0
			li		$v0			0
			la	$a0		string_abs
			li	$v0		4
			syscall
			# set trigger for unknown operations
			li		$t7			1
			# check for "switch_modes" command
			jal 		check_for_switch_string
			
			# check for "print_significand" command
			jal		check_for_print_significand
			
			# check for "print_exponent"
			jal		check_for_print_exponent
			
			# check for "opposite"
			jal		check_for_opposite_string_float
			
			# check for "inverse"
			jal		check_for_inverse_string_float
			
			beqz		$t7		unknown_operator
			
			j		calculator_float_loop_end
			unknown_operator:
				li	$v0	10
				syscall

    		calculator_float_loop_end:
      			# Set the result as 'new first arg'
      			mov.s 		$f3 		$f0
      			# Print result
      			mov.s 		$f12 		$f0
      			jal 		print_float
      			jal 		print_newline

      		j 	calculator_float_loop

  	calculator_float_exit:
    		lw 		$ra 		0($sp)
    		lw 		$a0 		4($sp)
    		lwc1 		$f0 		8($sp)
    		lwc1 		$f12 		12($sp)
    		lwc1 		$f13 		16($sp)
    		lwc1 		$f3 		20($sp)
    		addu 		$sp 		$sp 		24
    		jr 		$ra

################################################################################
				# CLI
################################################################################

	## Handle CLI arguments (currently just prints them...)
	##
	## Inputs:
	## $a0: argc
	## $a1: argv
	##
	## Outputs:
	## $v0: 0 if we choose integer mode, 1 if we choose float mode
	handle_cli_args:
  		subu 		$sp 		$sp 		20
  		sw 		$ra 		0($sp)
  		sw 		$a0 		4($sp)
  		sw 		$a1 		8($sp)
  		sw 		$s0 		12($sp)
  		sw 		$s1 		16($sp)

  	# Copy argc and argv in $s0 and $s1
  	move 		$s0 		$a0
  	move 		$s1 		$a1
  	# Set default return value
  	li 		$v0 		0

  handle_cli_args_loop:
    beq $s0 $0 handle_cli_args_exit

    # Debugging info on stderr
    handle_cli_args_loop_debug:
      # Print the prefix "arg: "
      la $a0 string_arg
      jal print_string_stderr
      # Print current arg on stderr
      lw $a0 ($s1)
      jal print_string_stderr
      jal print_space_stderr
      jal print_newline_stderr

    # Process the current argument
    handle_cli_args_loop_current_arg_handling:
      # Compare the argument with authorized values
      # Set $v0 and exit if an authorized value is detected
      #
      # TODO
      la $a1 string_float
      jal simple_strncmp
      beq $v0 1 handle_cli_args_exit

    handle_cli_args_loop_end:
      # Move on to the next argument (akin to argc--, argv++)
      add $s0 $s0 -1
      add $s1 $s1 4
      j handle_cli_args_loop

  handle_cli_args_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $s0 12($sp)
    lw $s1 16($sp)
    addu $sp $sp 20
    jr $ra

################################################################################
# I/O
################################################################################

#-------------------------------------------------------------------------------
# stdout
#-------------------------------------------------------------------------------

## Print a string on stdout
##
## Inputs:
## $a0: string
##
## Outputs:
## none
print_string:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  li $v0 4
  syscall

  print_string_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a newline on stdout
##
## Inputs:
## none
##
## Outputs:
## none
print_newline:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_newline
  jal print_string

  print_newline_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a space on stdout
##
## Inputs:
## none
##
## Outputs:
## none
print_space:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_space
  jal print_string

  print_space_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print an integer on stdout
##
## Inputs:
## $a0: integer
##
## Outputs:
## none
print_int:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  li $v0 1
  syscall

  print_int_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a float (single precision) on stdout
##
## Inputs:
## $f12: float
##
## Outputs:
## none
print_float:
  subu $sp $sp 8
  sw $ra 0($sp)
  swc1 $f12 4($sp)

  li $v0 2
  syscall

  print_float_exit:
    lw $ra 0($sp)
    lwc1 $f12 4($sp)
    addu $sp $sp 8
    jr $ra

#-------------------------------------------------------------------------------
# stderr
#-------------------------------------------------------------------------------

## Print a string on stderr
##
## Inputs:
## $a0: string
##
## Outputs:
## none
print_string_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  jal strlen
  move $a2 $v0
  move $a1 $a0
  li $a0 2
  # syscall 15 (write to file)
  # a0: file descriptor
  # a1: address of buffer
  # a2: number of characters to write
  li $v0 15
  syscall

  print_string_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a newline on stderr
##
## Inputs:
## none
##
## Outputs:
## none
print_newline_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_newline
  jal print_string_stderr

  print_newline_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Print a space on stderr
##
## Inputs:
## none
##
## Outputs:
## none
print_space_stderr:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_space
  jal print_string_stderr

  print_space_stderr_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

print_result_prefix:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $a0 string_output_prefix
  jal print_string_stderr

  print_result_prefix_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

#-------------------------------------------------------------------------------
# misc.
#-------------------------------------------------------------------------------

## Read an integer
##
## Inputs:
## none
##
## Outputs:
## $v0: read integer
read_int:
  li $v0 5
  syscall
  jr $ra

## Read a float
##
## Inputs:
## none
##
## Outputs:
## $f0: read float
read_float:
  li $v0 6
  syscall
  jr $ra

## Reads an operator
##
## Inputs:
## none
##
## Outputs:
## $a0: read operator  
read_operator:
    la	$a0	operatorSpace
    li	$a1	20
    li 	$v0	8
    syscall
    jr $ra

################################################################################
# Strings
################################################################################

## Ignore spaces in a string
##
## Inputs:
## $a0: null terminated string
##
## Outputs:
## $v0: first non-space character
ignore_spaces:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  la $t0 space
  lb $t0 0($t0)

  move $v0 $a0
  ignore_spaces_loop:
    lb $t1 0($v0)
    beq $t0 $0 ignore_spaces_exit
    bne $t0 $t1 ignore_spaces_exit
    addu $v0 $v0 1
    j ignore_spaces_loop

  ignore_spaces_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## strlen
##
## Inputs:
## $a0: input null terminated string
##
## Outputs:
## $v0: string length
strlen:
  subu $sp $sp 8
  sw $ra 0($sp)
  sw $a0 4($sp)

  move $v0 $0

  strlen_loop:
    lb $t1 0($a0)
    beq $t1 $0 strlen_exit
    add $v0 $v0 1
    add $a0 $a0 1
    j strlen_loop

  strlen_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    addu $sp $sp 8
    jr $ra

## Simplified strncmp
##
## Simplified strncmp outputs a boolean value as opposed to the common behaviour
## (Usually it outpus 0 for perfect match or either a negative or positive
## value if the (sub)strings do not exactly match)
##
## Inputs:
## $a0: string 1
## $a1: string 2
## $a2: n
##
## Outputs:
## $v0: boolean
simple_strncmp:
  subu $sp $sp 16
  sw $ra 0($sp)
  sw $a0 4($sp)
  sw $a1 8($sp)
  sw $a2 12($sp)

  # Initialize result to true
  li $v0 1

  simple_strncmp_loop:
    # Have we compared n characters?
    ble $a2 $0 simple_strncmp_exit

    # Load the characters for comparison
    lb $t0 0($a0)
    lb $t1 0($a1)

    # Characters differ
    bne	$t0 $t1 simple_strncmp_false

    # Identical characters

    addi $a0 $a0 1
    addi $a1 $a1 1
    addi $a2 $a2 -1
    j simple_strncmp_loop
    beqz $t0 simple_strncmp_exit_of_string
    

  simple_strncmp_exit_of_string:
    # (Sub)Strings match
    li $v0 1
    j simple_strncmp_exit

  simple_strncmp_false:
    # (Sub)Strings do not match
    li $v0 0
    j simple_strncmp_exit

  simple_strncmp_exit:
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    lw $a2 12($sp)
    addu $sp $sp 16
    jr $ra

################################################################################
# Integer Operations
################################################################################

## Inputs:
## $a0: operand 1
## $a1: operand 2
##
## Outputs:
## $v0: $a1 + $a2
operation_integer_addition:
  add $v0 $a0 $a1
  jr $ra

operation_integer_substraction:
  sub $v0 $a1 $a0
  jr $ra

operation_integer_multiplication:
  mul $v0 $a1 $a0
  jr $ra

operation_integer_division:
  div $v0 $a1 $a0
  jr $ra

operation_integer_minimum:
  	ble	$a0	$a1	return_first_arg_min
  	j return_second_arg_min
  	return_first_arg_min:
  		move $v0 $a0
  		j continue_integer_min
  	return_second_arg_min:
  		move $v0 $a1
  	continue_integer_min:		
  		jr $ra

operation_integer_maximum:
  	bge	$a0	$a1	return_first_arg_max
  	j     return_second_arg_max
  	return_first_arg_max:
  		move $v0 $a0
  		j continue_integer_max
  	return_second_arg_max:
	  	move $v0 $a1
  	continue_integer_max:		
  		jr $ra

operation_integer_pow:
      addi $sp, $sp, -8                   # Allocate space in stack
      sw $a0, 0($sp)                       # Store reg that holds current num
      sw $ra, 4($sp)                      # Store previous PC

      li $v0, 1                           # Init return value
      beq $a1, 0, pow_done              # Finish if param is 0

      # Otherwise, continue recursion
      # move $a1, $a0                       # Copy $a0 to $s0
      sub $a1, $a1, 1
      jal operation_integer_pow

      mul $v0, $v0, $a0                   # Multiplication is done

      pow_done:
        lw $a0, 0($sp)
        lw $ra, 4($sp)                     # Restore the PC
        addi $sp, $sp, 8

        jr $ra
  

operation_integer_abs: 
  abs $v0 $a0
  jr $ra

################################################################################
# Floating Point Operations
################################################################################

## Float addition
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 + $f13
operation_float_addition:
  add.s $f0 $f12 $f13
  jr $ra

## Float substraction
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 - $f13
operation_float_substraction:
  sub.s $f0 $f12 $f13
  jr $ra
## Float multiplication
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 * $f13
operation_float_multiplication:
  mul.s $f0 $f12 $f13
  jr $ra

## Float division
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: $f12 / $f13
operation_float_division:
  div.s $f0 $f12 $f13
  jr $ra

## Float minimum
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: min($f12, $f13)
operation_float_minimum:
    	c.le.s	$f12	$f13	
    	bc1t return_first_arg_min_float
  	j return_second_arg_min_float
  	return_first_arg_min_float:
  		mov.s $f0 $f12
  		j continue_integer_min_float
  	return_second_arg_min_float:
  		mov.s $f0 $f13
  	continue_integer_min_float:		
  		jr $ra

## Float maximum
##
## Inputs
## $f12: first argument
## $f13: second argument
##
## Outputs
## $f0: max($f12, $f13)
operation_float_maximum:
      	c.le.s		$f12		$f13	
      	bc1f 		return_first_arg_max_float
  	j 		return_second_arg_max_float
  	
  	return_first_arg_max_float:
  		mov.s 		$f0 		$f12
  		j		continue_integer_max_float
  		
  	return_second_arg_max_float:
  		mov.s		$f0 		$f13
  		
  	continue_integer_max_float:		
  		jr 		$ra

  operation_float_pow:
      addi 		$sp 		$sp		-8            # Allocate space in stack
      swc1 		$f12 		0($sp)                        # Store reg that holds current num
      sw 		$ra 		4($sp)                        # Store previous PC

      lwc1 		$f1 		fp0
      lwc1 		$f0  		fp1                           # Init return value
      c.eq.s 		$f13 		$f1
      bc1t 		pow_done_float              		      # Finish if param is 0

      # Otherwise, continue recursion
      sub.s 		$f13 		$f13 		$f0
      jal 		operation_float_pow

      mul.s 		$f0 		$f0 		$f12          # Multiplication is done

      pow_done_float:
        lwc1 		$f12		0($sp)
        lw		$ra 		4($sp)                     # Restore the PC
        addi 		$sp		$sp		8

        jr $ra

  operation_float_abs:
  	abs.s 		$f0 		$f12
  	jr 		$ra
  	
  check_for_print_significand:
  	addi		$sp		$sp		-4
  	sw		$ra		0($sp)
  	
  	jal		get_string_length_extended
  	
  	la		$a1		print_significand
  	jal		simple_strncmp
  	
  	move		$t1		$v0
  	beq		$v0		1		execute_print_significand
  	
  	lw		$ra		0($sp)
  	addi		$sp		$sp		4
  	jr		$ra
  	
  
  check_for_switch_string:
 	addi		$sp		$sp		-8
 	sw		$ra		0($sp)
 	sw		$a0		4($sp)
 	
  	# save current calculator mode in $t2
  	move		$t2			$v0
  	# get string length for argument
	jal		get_string_length_extended
  	# string to be checked against
	la		$a1			string_switch_modes
	jal		simple_strncmp
	# save output of simple_strncmp() in $t1
	move		$t1			$v0
	# save current calculator mode in $v0
	move		$v0			$t2
	# check whether "switch_mode" instruction has been passed
	beq		$t1			1		switch_modes
	
	lw		$ra		0($sp)
	lw		$a0		4($sp)
	addi		$sp		$sp		8
	
	jr 		$ra
	
 check_for_inverse_string_integer:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	jal		get_string_length_extended
 	la		$a1		string_inverse
 	jal		simple_strncmp
 	beq		$v0		1		get_inverse_integer
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra

  check_for_inverse_string_float:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	jal		get_string_length_extended
 	la		$a1		string_inverse
 	jal		simple_strncmp
 	beq		$v0		1		get_inverse_float
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra	
 	
 get_inverse_integer:
 	li		$t7		1
 	li		$a0		1
 	div		$v0		$a0		$s0
 	jr		$ra
 	
 get_inverse_float:
 	lwc1		$f1		fp1
 	div.s		$f0		$f1		$f3
 	mov.s		$f12		$f0
 	jal		print_float
 	jal		print_newline
	mov.s		$f3		$f12
	j		calculator_float_loop
						
 check_for_opposite_string_float:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	jal		get_string_length_extended
 	la		$a1		string_opposite
 	jal		simple_strncmp
 	beq		$v0		1		get_opposite_float
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra
	
 check_for_opposite_string_integer:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	jal		get_string_length_extended
 	la		$a1		string_opposite
 	jal		simple_strncmp
 	beq		$v0		1		get_opposite_integer
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra
 	
  get_opposite_float:
 	
  	lwc1		$f2		fp2
 	mul.s		$f0		$f3		$f2
 	sub.s		$f0		$f3		$f0		
 	mov.s		$f12		$f0
 	jal		print_float
 	jal		print_newline
 	mov.s		$f3		$f12
 	j		calculator_float_loop
 
  get_opposite_integer:
	li		$t7		1
 	li		$a1		2
 	mul		$a1		$s0		$a1
 	sub		$v0		$s0		$a1		
 	jr		$ra
	
 check_for_print_hexa_string:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	# get string length for argument
 	jal		get_string_length_extended
 	# string to be checked against
 	la		$a1		string_print_hexa
 	jal		simple_strncmp
 	# save output of simple_strncmp() in $t1
 	beq		$v0		1		print_hexa
 	
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra

 check_for_print_binary_string:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	# get string length for argument
	jal		get_string_length_extended
 	# string to be checked against
 	la		$a1		string_print_binary
 	jal		simple_strncmp
 	# save output of simple_strncmp() in $t1
 	beq		$v0		1		print_binary
 	
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	
 	jr		$ra
 	
 check_for_print_exponent:
 	addi		$sp		$sp		-4
 	sw		$ra		0($sp)
 	
 	jal		get_string_length_extended
 	
 	la		$a1		print_exponent
 	jal		simple_strncmp
 	
 	beq		$v0		1		print_exponent_function
 	
 	lw		$ra		0($sp)
 	addi		$sp		$sp		4
 	jr		$ra
 	
 print_exponent_function:
 	# cast to int
 	cvt.w.s		$f0		$f3
 	# move to int register so we can start decomposing
 	mfc1		$a0		$f0
 	# initiate index to $a1 to 0
 	li		$a1		0
 	# load 2 into $a2
 	li		$a2		2
 	# load 1 into $a1
 	li		$a3		1
 	
 	decompose_to_get_exponent_loop:
 		beqz		$a0		exit_decompose_to_get_exponent_loop
 		beq		$a0		$a3		exit_decompose_to_get_exponent_loop	
 		rem		$s0		$a0		$a2
 		beqz		$s0		increment_by_one_pos
 		beq		$s0		$a3		subtract_one
 		
 	subtract_one:
 		addi		$a0		$a0		-1
 		
 		
 	increment_by_one_pos:
 		div		$a0		$a0		$a2
 		addi		$a1		$a1		1
 		j		decompose_to_get_exponent_loop
 	
 	exit_decompose_to_get_exponent_loop:
 		addi		$a1		$a1		127
 		move		$s0		$a1
 		j		print_binary
 
 
 print_binary:
	add		$t0		$zero		$s0
	add		$t1		$zero		$zero
	addi		$t3		$zero		1
	sll		$t3		$t3		31
	addi		$t4		$zero		32
	print_binary_loop:
		and 		$t1		$t0		$t3 
		beq 		$t1 		$zero		print_print_binary 

		add 		$t1		$zero		$zero
		addi 		$t1		$zero 		1 
		j print_print_binary


		print_print_binary: 
			li 		$v0		1
			move 		$a0		$t1
			syscall

		srl 		$t3		$t3		1
		addi 		$t4 		$t4		-1
		bne 		$t4		$zero		print_binary_loop
		addi 		$a0		$0		0xA 	#ascii code for LF, if you have any trouble try 0xD for CR.
        	addi 		$v0 		$0		0xB 	#syscall 11 prints the lower 8 bits of $a0 as an ascii character.
		syscall

	j	calculator_integer_start
# vim:ft=mips

 execute_print_significand:
 	# load 48 into $a0
 	la		$s0		string_0
 	# load 49 into $a1
 	la		$s1		string_1		
 	# store 0.0 in $f0
 	lwc1		$f0		fp0
 	# store 1.0 in $f1
	lwc1		$f1		fp1
	# store 2.0 in $f2
	lwc1		$f2		fp2
	# load max index == 23 in $s1
	li		$s2		23
 	
 	# is number less or equal than 1
 	print_mantissa_loop:
		mul.s		$f3		$f3		$f2
 		beqz		$s2		exit_print_mantissa_loop
 		c.eq.s		$f3		$f1
 		bc1t		print_1_and_exit_mantissa_loop
 		#mov.s		$f12		$f1
 		#jal print_float
 		#jal print_newline
 		c.lt.s		$f3		$f1
 		bc1t		print_0
 		bc1f		print_1
 	continue_post_0:
 		addi		$s2		$s2		-1
 		j		print_mantissa_loop
 	
 	
 	print_0:

		la		$a0		string_0
		li		$v0		4
		syscall
 		j		continue_post_0
 		
 	print_1:
 		la		$a0		string_1
		li		$v0		4
		syscall
		sub.s		$f3		$f3		$f1
 		j		continue_post_0
 
 	print_1_and_exit_mantissa_loop:
 		la		$a0		string_1
		li		$v0		4
		syscall

 	exit_print_mantissa_loop:
		addi 		$a0		$0		0xA 	#ascii code for LF, if you have any trouble try 0xD for CR.
        	addi 		$v0 		$0		0xB 	#syscall 11 prints the lower 8 bits of $a0 as an ascii character.
        	syscall
 		j		calculator_float_start
 	

 print_hexa:
 	la		$a1		hex_value
 	addi		$a1		$a1		8
 	
 	print_hexa_loop:
 		blt		$s0		16		exit_print_hexa_loop
 		div		$s1		$s0		16
 		rem		$s0		$s0		16
 		bge		$s0		10		get_diff_hex
		jal		write_to_array
 		addi		$a1		$a1		-1
 	
 	continue_print_hexa_post_save:
 		move		$s0		$s1
 		j		print_hexa_loop
 	
 	exit_print_hexa_loop:
 		bge		$s0		10		get_diff_hex_and_exit
		jal		write_to_array
 		j		continue_exit_loop
 		
 	get_diff_hex_and_exit:
 		jal		get_diff_hex_function
 		j		continue_exit_loop
 		
 	write_to_array:
 		addi		$s0		$s0		48
 		sb		$s0		0($a1)
 		addi		$s0		$s0		-48
 		jr		$ra
 			
 	get_diff_hex_function:
	 	addi		$s0		$s0		-10
	 	addi		$s0		$s0		65
	 	sb		$s0		0($a1)
	 	addi		$a1		$a1		-1
	 	jr		$ra
 	
 	
 	get_diff_hex:
		jal		get_diff_hex_function
 		j		continue_print_hexa_post_save
 	
 	continue_exit_loop:
        	la		$a0		0($a1)
       	 	li		$v0		4
		syscall
		j 		calculator_integer_start
 	
 	

 get_string_length_extended:
 	addi		$sp		$sp		-8
 	sw		$a0		0($sp)
 	sw		$ra		4($sp)

 	# get string length in $v0
  	jal 		strlen
  	#  substring length to be checked for simple_strncmp()
  	move		$a2			$v0
  	# remove the extra \0
  	addi		$a2			$a2		-1
  	j		get_string_length_extended_done
  	
  	get_string_length_extended_done:
  		lw		$a0		0($sp)
  		lw		$ra		4($sp)
  		addi		$sp		$sp		8
  		jr		$ra
