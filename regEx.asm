# Mason Bair
# Savar Shrestha
# Sumedh Joshi

## ------ TOKENIZER ----- ##
# This is the idea for the Tokenizer, which will produce computable results for evaluation.
# We have an 8 byte Register per token, and each token will represent a difference piece of information for the token

#Byte 1: Type (1= a 2=[])
#Byte 2: ^ (1=^ 2=az 0=a-z)
#Byte 3: Len (How many chars of data does this token have)
#Byte 4: 1 represents * and 2 represents . and 3 represents .*
#Byte 5-6 is either one of two things
# IF A RANGE byte 5-6 is a and z for [a-z]
# IF LITERAL BYTE 5-6, BYTE 6 does not exist, and instead byte 5 is a memerory address pointing to the literal value in a seperate buffer

## TOKEN TYPES ##
# 1. Literal: "a" or "hello": needs to match exactly
# 2. Char class: Matches any character inside of the char list: [a-z], [c-d], [A-z]
############################################################

.data
	regularExpressionInput: .space 52
	InputToEvaluate: .space 52
	
	expressionPrompt: .asciiz "Please enter a valid regular expression: \n"
	evaluatePrompt: .asciiz "Please enter an expression to evaluate: \n"
	
	tsc9_literal: .asciiz "@kent.edu"		#for test case 9
	
	.align 2                    # Align to word boundary (2^2 = 4 bytes)
    	tokenArray: .space 64
    	tokenDebugMsg: .asciiz "Token: "
    
    	.align 2                    # Align literal buffer too
    	literalDataBuffer: .space 128
    	
    	#3 Buffer for test cases 8 and 9
    	buffer1: .space 64	#holds matched letters	
    	buffer2: .space 64	# holds literals 
    	buffer3: .space 128	#concatenates token 1 and 2
	
.text
main:
	la $a0, expressionPrompt		# Loads the beginning prompt
	li $v0, 4			#V0 means it will print a string
	syscall

	li $v0, 8			#Telling the syscall to take in a user input string
	la $a0, regularExpressionInput		#The stored location of the input
	li $a1, 50			# Allocates the byte space for the input
	move $t0, $a0			# Saves the a0 address (The string address) into t0
	syscall
	
	
	la $a0, evaluatePrompt		# Loads the beginning prompt
	li $v0, 4			#V0 means it will print a string
	syscall
	
	li $v0, 8			#Telling the syscall to take in a user input string
	la $a0, InputToEvaluate		#The stored location of the input
	li $a1, 50			# Allocates the byte space for the input
	move $t0, $a0			# Saves the a0 address (The string address) into t0
	syscall
	
	li $a3, 1		# REPRESENTS THE NUMBER OF TOKENS THAT ARE CREATED
	
	li $t0, 1			# Represents the value of 1, when we go through a loop we go to the next one by 1
	
	# Values for the regex input
	la $t1, regularExpressionInput		# Loads the first address of the buffer into t1
	move $t2, $t1 			# Loads beginning of the buffer
	lb $t3, 0($t1)			# Loads byte value
	
	# Values for the token arrary
	la $t4, tokenArray		# Loads the first address of the buffer into t1
	move $t5, $t4 			# Loads beginning of the buffer
	
reset:		# Called when a token is finished building and the values need to be reset
	li $t7, 0		# t7 represents what ever value we are adding to the token array
	li $t8, 0		# Represets a byte offset for working with the t5 register. This helps make sure t5 stays on track
	li $s1, 0	# Random value for keeping track of the char range literal length

tokenize:	
	beq $t3, 10, printTokenDone		# Exits the program when it finds the new line char, which is the end of the input
	#j printChar			# Calls a jump to printchar
	
	beq $t3, 91, frontBracket	# Represents the token is a Char class
	# If it is not frontBracket then it needs to be a literal
	j literal
	
	j increment
	

increment:
	add $t2, $t2, $t0		#Finds new index memory location. 
					# t0 is always 1 and since we ar ein a buffer, each byte is only 1 over
					# This means that to move to the next spot for a character we can just add t2 with t0 and store it back in t2
					# This is essentially t2++
					
	lb $t3, 0($t2)			# This loads the next byte of the buffer into t3
	j tokenize
	

literal:
	li $t7, 1		# Represents type 1 which is the literal and it will be stored in the token
    	sb $t7, 0($t5)     	# Byte 0: Type = 2 (char class)
    	li $t8, 0          	# Start with 0 data bytes written
    	
    	beq $t3, 46, period
    	
    	j literalTokenize
   
period:
	li $t7, 2
    	sb $t7, 3($t5)             # Set repetition flag
    	
    	add $t2, $t2, $t0       # Move past the '.'
        lb $t3, 0($t2)          # Load next char
    	
    	j literalTokenize

# Needs to take the whole literal value and store it in the data section of the token	
literalTokenize:
	la $t9, literalDataBuffer		# The t9 register will be pointing at the string buffer for literals
	
	sw $t9, 4($t5)		# Stores the address for the literalDataBuffer in the token at byte 4
	
	li $t6, 0		#Represents the character length of the literal we are dealing with
	

literalLoop:
	beq $t3, 92, forwardSlash	# Used for storing the fancy value
    	beq $t3, 91, literalDone   #Front bracket stop
    	beq $t3, 10, literalDone   #Newline stop
    	beq $t3, 42, literalDone   # If '*', stop
    	
    
    	sb $t3, 0($t9)             # Store char in buffer
    	addi $t9, $t9, 1           # Move buffer pointer
    	addi $t6, $t6, 1           # Increment count
    
    	add $t2, $t2, $t0          # Next input char
    	lb $t3, 0($t2)
    	j literalLoop
    	
forwardSlash:
	add $t2, $t2, $t0          # Next input char
    	lb $t3, 0($t2)

	sb $t3, 0($t9)             # Store char in buffer
    	addi $t9, $t9, 1           # Move buffer pointer
    	addi $t6, $t6, 1           # Increment count
    
    	add $t2, $t2, $t0          # Next input char
    	lb $t3, 0($t2)
    	j literalLoop
    
literalDone:
    	sb $zero, 0($t9)           # Null terminate
    	sb $t6, 2($t5)             # Store length
    
    	# Peek at next character (We do not want to modify t2 directly yet becuase if the value is not a * then we mess up the flow of tokenizing)
    	move $t7, $t2              # temp = t2 
    	lb $t7, 0($t7)             # Load next char into $t7
    	bne $t7, 42, literalNotStar # If not '*', skip
    
    	# IF there is a period and a *, we need to keep track of that
    	lb $t6, 3($t5)             # Load current byte 3 value
        addi $t6, $t6, 1           # Add 1 (star flag)
        sb $t6, 3($t5)             # Store back: 0->1, 2->3
    	
    	
    	add $t2, $t2, $t0          # NOW advance past the '*'
    	lb $t3, 0($t2)             # Load next char after '*'
    
literalNotStar:
    	# $t2 and $t3 are still pointing at the right place
    	j printToken


# Still need to deal with the range of values in the chararray
# Plus the *
# Also need to make a way to print out the tokens so I can make sure everything is working correctly
charArrayTokenize:
	beq $t3, 94, negate
	beq $t3, 93, backBracket
	j charRange

frontBracket:
    	li $t7, 2		# Represents type 2 which is the char class and it will be stored in the token
    	sb $t7, 0($t5)     # Byte 0: Type = 2 (char class)
    	li $t8, 0          # Start with 0 data bytes written
    	j charArrayIncrement

backBracket:
	# Checks for any *'s
   	 # Peek at next character
    	add $t7, $t2, $t0          # temp = current + 1
    	lb $t7, 0($t7)             # Load next char
    	bne $t7, 42, charClassNoStar
    
    	li $t7, 1
    	sb $t7, 3($t5)             # Set repetition
    	add $t2, $t2, $t0          # Advance past '*'
    	lb $t3, 0($t2)             # Load char after '*'
    
charClassNoStar:	
	add $t2, $t2, $t0          # Advance past ']' even when no star
        lb $t3, 0($t2)
    	j printToken	# Breaks out of char array increment loop and goes back to regular tokenizer	

	
#Either called printtoken
nextToken:
    	
    	# Check if reached end of input
    	beq $t3, 10, what_to_do   # If newline, we are finished
    	beq $t3, 0, what_to_do    # If null terminator, we are finsihed
    	
    	add $a3, $a3, $t0	# If there is nother token, add a plus one to the register that keeps track of the # of tokens
    	
    	addi $t5, $t5, 8	# Move to the next token position
    	# Advance to next character before tokenizing
    	#add $t2, $t2, $t0          	# Move to next char
    	#lb $t3, 0($t2)  		# Loads in the next value
    
    	# continue tokenizing if not done yet
    	j reset

negate:
	li $t7, 1 		# One means negate for the second byte
	sb $t7, 1($t5)
	j charArrayIncrement
	
charRange:
	# $t3 currently holds the first character 
	sb $t3, 4($t5)     # Store first char at byte 4
    
	# Skip over the '-' character if it exists, else it is a literal
	add $t2, $t2, $t0  # just like i++
	lb $t3, 0($t2)		# Loads the 2nd char
	
	bne $t3, 45, loadCharRangeLiteral
	
    
	# Load the second character 
	add $t2, $t2, $t0  # i++
	lb $t3, 0($t2)     # Load second char into $t3
	sb $t3, 5($t5)     # Store second char at byte 5
    
	li $t7, 2          # Length = 2 (two characters)
	sb $t7, 2($t5)     # Store length in byte 2
    
	li $t8, 2          # We've written 2 data bytes
	j charArrayIncrement

loadCharRangeLiteral:
	lb $t6, 1($t5)             # Load current byte 3 value
        addi $t6, $t6, 2           # Add 2 for charRangeLiteral)
        sb $t6, 1($t5)             # Store back: 0->1, 2->3
        
	j charRangeLiteral

charRangeLiteral:

	addi $s1, $s1, 1	# For the length of the current literal
	
	move $t7, $s1 		# Stores the length of the current literal
	sb $t7, 2($t5)		# Stores
	
	beq $t3, 93, backBracket
	
	addi $s2, $s1, 4	# Puts s2 in the correct byte position for storing the next char of the literal in the data stream
	
	# Dynamically puts the char in the correct byte value so we can loop it
	add $s2, $t5, $s2      # Calculate: base address + offset
	sb $t3, 0($s2)         # Store at calculated address

	
	add $t2, $t2, $t0		# Moves to next index
	lb $t3, 0($t2)
	
	j charRangeLiteral

charArrayIncrement:
	add $t2, $t2, $t0		#Finds new index memory location. 
					# t0 is always 1 and since we ar ein a buffer, each byte is only 1 over
					# This means that to move to the next spot for a character we can just add t2 with t0 and store it back in t2
					# This is essentially t2++
					
	lb $t3, 0($t2)			# This loads the next byte of the buffer into t3
	j charArrayTokenize

printChar:
	move $a0, $t3		# Loads char value in t3 into a0
	li $v0, 11		#11 means print character, $a0 is the char to print
	syscall
	
	j increment


printToken:
	# Print "Token:  
	 li $v0, 4
	 la $a0, tokenDebugMsg
	 syscall
    
    	# Print Byte 0 (Type)
    	lb $a0, 0($t5)
    	li $v0, 1          # Print integer
    	syscall
    
	li $v0, 11         # Print space
    	li $a0, 32
    	syscall
    
    	# Print Byte 1 (Flags)
    	lb $a0, 1($t5)
    	li $v0, 1
    	syscall
    
    	li $v0, 11
    	li $a0, 32
    	syscall
    	
    	# Print Byte 2 (Length)
    	lb $a0, 2($t5)
    	li $v0, 1
    	syscall
    	
    	li $v0, 11
    	li $a0, 32
    	syscall
    
    	# Print 0 for placeholder and 1 for star
    	lb $a0, 3($t5)
    	li $v0, 1
    	syscall
    	
    	li $v0, 11
    	li $a0, 32
    	syscall
    	
    	 # Check for char range or literal
    	lb $t7, 0($t5)         		
    	beq $t7, 1, printLiteralString   	# If type == 1, print literal string
    	
    	# Print Byte 4-7 (Data as characters)
    	lb $a0, 4($t5)
    	li $v0, 11         # Print char
    	syscall
   	 
    	li $v0, 11 		#Space
    	li $a0, 32
    	syscall
    	
    	lb $a0, 5($t5)
    	li $v0, 11
    	syscall
    	
    	li $v0, 11 		#Space
    	li $a0, 32
    	syscall
    	
    	lb $a0, 6($t5)
    	li $v0, 11         # Print char
    	syscall
    	
    	li $v0, 11 		#Space
    	li $a0, 32
    	syscall
    	
    	lb $a0, 7($t5)
    	li $v0, 11
    	syscall
    	
    	li $v0, 11 		#Space
    	li $a0, 32
    	syscall
    	
    	j printTokenDone
	
        
printLiteralString:
    	# Load pointer from bytes 4-7
    	lw $a0, 4($t5)         # Load address of literal string
    	li $v0, 4              # Print string syscall
    	syscall
    	
    	li $v0, 11             # Print space
    	li $a0, 32
    	syscall
    	
    	j printTokenDone
    	
    	
printTokenDone:
    	# Print newline
    	li $v0, 11
    	li $a0, 10
    	syscall
    	
    	j nextToken
    	#j what_to_do
  	
# ===============================================================   
what_to_do:

    	lb $t0, 0($t5)         # load token type (byte 0)
    	
    	

    	li $t1, 0
    	beq $t0, $t1, exit     # if type=0 = end of tokens
    	
	
    	li $t1, 1
    	beq $t0, $t1, do_literal   # type 1 = literal or wildcard
    	
  	
    	li $t1, 2
    	beq $t0, $t1, do_charclass # type 2 = char class
    
	
    	j exit                 #  unknown type =exit


do_literal: # byte 1 always 1
    	lb $t2, 3($t5)    # repetition & wildcard flags
     
    	li $t3, 2
    	beq $t2, $t3, call_tc4   # if '.' wildcard 
    	
    	li $t3, 3
    	beq $t2, $t3, call_tc5   # if '.*' 

    	jal Test_case_1         # normal literal matcher
    	j next_token_dispatch
    
call_tc4:
    	jal Test_case_4
    	j next_token_dispatch
    	
call_tc5:
    	jal Test_case_5
    	j next_token_dispatch


do_charclass: 
    	
    	# load star flag
    	lb $t2, 3($t5)

    	# load next token
    	addi $t0, $t5, 8
    	lb $t1, 0($t0)


    	# TEST CASE 8:
   
    	li $t3, 1           # literal type
    	beq $t2, 1, check_tc8_token1   # if charclass has *
    	j other_charclass

check_tc8_token1:
    beq $t1, $t3, run_tc8
    j other_charclass

run_tc8:
    	jal test_case_8
    	j next_token_dispatch

    # TEST CASE 9:
check_tc9:
    	beq $t1, $t3, check_tc9_literal_start
    	j other_charclass

check_tc9_literal_start:
    	lw $t4, 4($t0)
    	lb $t4, 0($t4)
    	li $t5, '@'
    	beq $t4, $t5, run_tc9
    	j other_charclass

run_tc9:
    	jal test_case_9
    	j next_token_dispatch
	
other_charclass:
    	li $t3,0
    	beq $t2, $t3, call_tc2	 # if '[]'
    	
    	li $t3, 2	   # if '[]*' 
    	beq $s1, $t3, call_tc3	# when byte 2 = 2 & byte 3 = 1 test case 3  
    	li $t3, 0    # if '[-]*'
    	beq $s1, $t3, call_tc6   # when byte 2 = 0 & byte 3 = 1 test case 6
    	
    	li $t3, 1
    	beq $s1, $t3, call_tc7   # if '[^-]*'
    	
    	j next_token_dispatch
    
call_tc2:
    	jal test_case_2
    	j next_token_dispatch

call_tc3:
    	jal test_case_3
    	j next_token_dispatch
    
call_tc6:
    	jal Test_case_6
    	j next_token_dispatch
    
call_tc7:
    	jal Test_case_7
    	j next_token_dispatch
    
next_token_dispatch: #(for test case 8 & 9 )
    	addi $t5, $t5, 8    # move to next token in tokenArray
    	j what_to_do


#============================================================
Test_case_1:
    	lw $t1, 4($t5)         #   literal data in token
    	la $t2, InputToEvaluate  
    	lb $t3, 2($t5)         # token length
	
    	li $t4, 0              # index inside literal
    	li $t6, 0              # index inside input
	li $s7, 0       # firstMatchFlag = 0 (no matches yet)

match_loop:
    	lb $t7, 0($t2)         # load next input char
    	beqz $t7, match_done   # end of input → stop
	
    	lb $t8, 0($t1)         # load token character

    	bne $t7, $t8, mismatch # branch to mis match if t7 and 8 are nnot same
	 # else increment
    	addi $t4, $t4, 1        # literal index++
    	addi $t2, $t2, 1        # input pointer++
    	addi $t1, $t1, 1        # token pointer++

 # if all literals match jump to full match
    	beq  $t4, $t3, full_match

    	j match_loop

mismatch:
    	lw $t1, 4($t5)      # reset literal pointer
    	li $t4, 0           # reset index to 0
    	lb $t3, 2($t5)      #  reload literal length 
    	addi $t2, $t2, 1    # increment input pointer
    	j match_loop


full_match:
    	jal printMatch

    	lw $t1, 4($t5)      # reset pointer to literal start
    	li $t4, 0           # reset literal index
    	lb $t3, 2($t5)      # reload literal length
	
   	 j match_loop


match_done:
    	jr $ra

printMatch:
    # If this is NOT the first match, print the comma first
    bnez $s7, print_commatc1

    # Mark that a match has occurred
    li $s7, 1
    j printMatch_continue

print_commatc1:
    li $a0, ','
    li $v0, 11
    syscall

printMatch_continue:
    # Restore match start position
    move $t8, $t2
    move $t9, $t3
    sub $t8, $t8, $t9    # start = end - length

printMatch_loop:
    beqz $t9, printMatch_done

    lb $a0, 0($t8)
    li $v0, 11
    syscall

    addi $t8, $t8, 1
    addi $t9, $t9, -1
    j printMatch_loop

printMatch_done:
    jr $ra


#================================================
# t0 = holds input text
# t1 = holds current input char
# t2 = has num of char in class
# t3 = holds flags like negate
#t4  = match the flag
#t6 = holds the index counter
#t7 = holds offset of byte
#t8 = holds address of token
#s0 = stores char to check

test_case_2: 
	la $t0, InputToEvaluate	# load the input text to address	
	lb $t1, 0($t0)		# load the first input character
	lb $t2, 2($t5)	# read token at t5
	lb $t3, 1($t5)
	li $s7, 0     # firstMatchFlag = 0 (no output printed yet)

char_input_loop: 
	beq $t1, 10, exit # check for new line
	beq $t1, 0, exit	# exit the loop when the input ends
	li $t4, 0 		# match the flag
	li $t6, 0 		# index

char_check_loop: 
	beq $t6, $t2, char_print	#when index = token stop loop
	addi $t7, $t6, 4	# need address of the token byte
	add $t8, $t5, $t7		# address
	lb $s0, 0($t8) 	# holds char to check
	beq $s0, $t1, char_match	#compare char to input to check if they match
	addi $t6, $t6, 1	#move to next index
	j char_check_loop	#loop to check another char

char_match:
	li $t4, 1		# set the flag matches to 1
	j char_print
	
char_print:
    beq $t4, 0, char_input_increment   # if not matched skip

    # If this is not the first match, print a comma BEFORE character
    bnez $s7, print_commatc2

    # Otherwise mark first match
    li $s7, 1
    j print_char

print_commatc2:
    li $v0, 11
    li $a0, ','
    syscall
    j print_char

print_char:
    li $v0, 11
    move $a0, $t1
    syscall

    j char_input_increment
	

char_input_increment:
	addi $t0, $t0, 1 	# increment the input string
	lb $t1, 0($t0)		# continue scanning
	j char_input_loop
#=================================================
#t0 = holds first input
#t1 = current char
#t2 = num of char inside []
#t4 = flag a star (0  = doesn't exist & 1 = exists)
#t6 = length of matched char
#t7 = holds the start of input 1
# t8 = marks matched flag (0  = doesn't match & 1 = match)
#s1 = holds index inside []
#s2 = holds offset for next char
#s3 = address of [] char
#s4 = holds [] char
#s5 = number of char
#s6 = start of input


test_case_3:
	la $t0, InputToEvaluate
	lb $t1, 0($t0)
	lb $t2, 2($t5)	
	lb $t4, 3($t5)
	beq $t4, 0, exit	#if there's no * leave test_case_3
	li $s7, 0		#first match flag = 0
	
test3_loop:
	beq $t1, 10, exit # check for new line
	beq $t1, 0, exit	# exit the loop when the input ends
	li $t6, 0 		# length of matched char
	move $t7, $t0	# start of the check
	
check_mark:
	li $t8, 0 		# marks matched flag
	li $s1, 0 		# holds index
	
check_matched: 
	beq $s1, $t2, finish_mark		# finish when check all chars
	addi $s2, $s1, 4		# offset to check next char
	add $s3, $t5, $s2		# address of char
	lb $s4, 0($s3)		# char in range
	beq $s4, $t1, mark_match		# if matched mark it
	addi $s1, $s1, 1	# increment and keep looping
	j check_matched

mark_match: 
	li $t8, 1 		# found a match and mark it

finish_mark:
	beq $t8, 0, finish_check	# end checking for match
	addi $t6, $t6, 1	#increment to check mark
	addi $t0, $t0, 1	# check the second char in first input
	lb $t1, 0($t0)		# load next input char
	j check_mark		# loop to match next char
	
finish_check:
	beq $t6, 0, check_char_increment	#increment if length of char finish
	beq $s7, 0, no_commatc3
	li $a0, ','
	li $v0, 11
	syscall

no_commatc3:
	li $s7,1		#at least one match
	move $s5, $t6 	# number of char
	move $s6, $t7	# start of input
	
print_check:
	beq $s5, 0, continue_loop	# stop printing if no char
	lb $a0, 0($s6)	# load char to print
	li $v0, 11
	syscall
	addi $s6, $s6, 1 	# move to next char
	addi $s5, $s5, -1	# decrement counter
	j print_check

continue_loop:
	j test3_loop		#continue scanning input

check_char_increment:
	addi $t0, $t0, 1 	# increment the input string
	lb $t1, 0($t0)		# load next char
	j test3_loop
	
#=====================================================
Test_case_4:
    la $t2, InputToEvaluate     # pointer to input string
    li $t8, 0                   # flag: 0 = first item, 1 = already printed something

TC4_loop:
    lb $t7, 0($t2)
    beqz $t7, TC4_done      # end of string

    li $t0, 10              # ASCII newline (\n)
    beq $t7, $t0, Skip_chartc4

    li $t0, 13              # ASCII carriage return (\r)
    beq $t7, $t0, Skip_chartc4

    # If not first printed char, print comma
    beqz $t8, Print_chartc4
    li $a0, ','
    li $v0, 11
    syscall

Print_chartc4:
    move $a0, $t7
    li $v0, 11
    syscall

    li $t8, 1               # mark we printed a valid char

Skip_chartc4:
    addi $t2, $t2, 1
    j TC4_loop

TC4_done:
    jr $ra


#=================================================
Test_case_5:
    	la $t0, InputToEvaluate   

tc5_loop:
    	lb $t1, 0($t0)            # read character
    	beqz $t1, tc5_done        # end of string
	
    	li $v0, 11                # print character
    	move $a0, $t1
    	syscall

    	addi $t0, $t0, 1          # next char
    	j tc5_loop

tc5_done:
    	jr $ra
#===================================================
Test_case_6:

    la $t0, InputToEvaluate      # input string pointer
    lb $t2, 4($t5)               # start range
    lb $t3, 5($t5)               # end range
    li $t8, 0                    # flag: printed at least one character?

tc6_loop:
    lb $t1, 0($t0)               # current char
    beqz $t1, tc6_done           # null terminator → stop

    # ignore newline '\n' (10) and carriage return '\r' (13)
    li $t9, 10
    beq $t1, $t9, tc6_next
    li $t9, 13
    beq $t1, $t9, tc6_next

    # check if in range
    blt $t1, $t2, tc6_next
    bgt $t1, $t3, tc6_next

    # If not first printed value → print comma first
    beqz $t8, Print_tc6
    li $a0, ','
    li $v0, 11
    syscall

Print_tc6:
    move $a0, $t1
    li $v0, 11
    syscall

    li $t8, 1                    # mark printed

tc6_next:
    addi $t0, $t0, 1
    j tc6_loop

tc6_done:
    jr $ra

#==================================================
Test_case_7:
    la   $t0, InputToEvaluate
    lb   $t2, 4($t5)
    lb   $t3, 5($t5)

    li   $t8, 0         # printed token flag
    li   $t6, 0         # group length
    move $s0, $t0       # start of current group

tc7_loop:
    lb   $t1, 0($t0)
    beqz $t1, tc7_finish_group
    beq  $t1, 10, tc7_finish_group

    blt  $t1, $t2, tc7_add    # outside below = match
    bgt  $t1, $t3, tc7_add    # outside above = match

    # inside range = break group if one exists
    bnez $t6, tc7_finish_group
    addi $t0, $t0, 1
    move $s0, $t0
    j    tc7_loop

tc7_add:
    addi $t6, $t6, 1
    addi $t0, $t0, 1
    j    tc7_loop

tc7_finish_group:
    beqz $t6, tc7_done   # nothing to print

    # print comma BEFORE token if not first
    beqz $t8, no_comma
    li   $a0, ','
    li   $v0, 11
    syscall
no_comma:

    # print the group
print_group:
    beqz $t6, end_group

    lb   $a0, 0($s0)
    li   $v0, 11
    syscall

    addi $s0, $s0, 1
    addi $t6, $t6, -1
    j print_group

end_group:
    li $t8, 1

    move $s0, $t0
    j tc7_loop

tc7_done:
    jr $ra

#============================================================
test_case_8:
    	# t0 = input pointer
    	la  $t0, InputToEvaluate

    	# clear buffer write indexes
    	li  $s6, 0          # buffer1 index
    	li  $s7, 0          # buffer2 index

tc8_main_loop:
    	lb  $t1, 0($t0)
    	beq $t1, 0, tc8_done
    	beq $t1, 10, tc8_done

    	move $t2, $t0       # t2 = scan pointer
    	li   $t3, 0         # t3 = count of [A-z]* chars

# ---------- MATCH [A-z]* ----------
tc8_star_loop:
    	lb  $t4, 0($t2)
    	beq $t4, 0, tc8_after_star
    	beq $t4, 10, tc8_after_star

    	# Check A-Z
    	blt $t4, 'A', tc8_check_lower
    	ble $t4, 'Z', tc8_accept_char
	
tc8_check_lower:
    	# Check a-z
    	blt $t4, 'a', tc8_after_star
    	bgt $t4, 'z', tc8_after_star

tc8_accept_char:
    	addi $t3, $t3, 1
    	addi $t2, $t2, 1
    	j    tc8_star_loop

# ---------- CHECK LITERAL ".edu" ----------
tc8_after_star:
    	addi $t8, $t5, 8         # token1 address
    	lb   $t9, 2($t8)         # literal length
    	lw   $s0, 4($t8)         # literal pointer
	
    	move $s1, $t2           # input pointer for literal
    	li   $s2, 0             # literal index
	
tc8_literal_check:
    	beq  $s2, $t9, tc8_match_found  # matched entire literal

    	lb   $s3, 0($s1)
    	lb   $s4, 0($s0)
    	bne  $s3, $s4, tc8_advance_input

    	addi $s1, $s1, 1
    	addi $s0, $s0, 1
    	addi $s2, $s2, 1
    	j    tc8_literal_check

# literal did not match
tc8_advance_input:
    	addi $t0, $t0, 1
    	j    tc8_main_loop

tc8_match_found:
    	# s5 = total length = token1-length + literal-length
    	add  $s5, $t3, $t9

    	# s3 = print start pointer
    	move $s3, $t0

# -write to buffer 1
tc8_write_buf1:
    	beq $t3, 0, tc8_write_buf2

    	lb  $t4, 0($s3)
    	sb  $t4, buffer1($s6)
    	addi $s6, $s6, 1
    	addi $s3, $s3, 1
    	addi $t3, $t3, -1
    	j   tc8_write_buf1

# write to buffer 2
tc8_write_buf2:
    	beq $t9, 0, tc8_advance_after_match
	
    	lb  $t4, 0($s1)
    	sb  $t4, buffer2($s7)
    	addi $s7, $s7, 1
    	addi $s1, $s1, 1
    	addi $t9, $t9, -1
    	j   tc8_write_buf2

tc8_advance_after_match:
    	addi $t0, $t0, 1
    	j    tc8_main_loop
	
tc8_done:
    	jr $ra
	

#============================================================

test_case_9:
    	la  $t0, InputToEvaluate

    	li  $s6, 0       # buffer1 index
    	li  $s7, 0       # buffer2 index

tc9_main:
    	lb  $t1, 0($t0)
    	beq $t1, 0, tc9_done
    	beq $t1, 10, tc9_done

    	move $t2, $t0
    	li   $t3, 0      # count of [A-z]* chars

# match [A-z]* 
tc9_star:
    	lb  $t4, 0($t2)
    	beq $t4, 0, tc9_after_star
    	beq $t4, 10, tc9_after_star

    	blt $t4, 'A', tc9_lower
    	ble $t4, 'Z', tc9_accept
tc9_lower:
    	blt $t4, 'a', tc9_after_star
    	bgt $t4, 'z', tc9_after_star

tc9_accept:
    	addi $t3, $t3, 1
    	addi $t2, $t2, 1
    	j    tc9_star

# check for "@kent.edu" 
tc9_after_star:
    	addi $t8, $t5, 8
    	lb   $t9, 2($t8)      # literal length
    	lw   $s0, 4($t8)      # literal pointer

    	move $s1, $t2
    	li   $s2, 0

tc9_lit:
    	beq $s2, $t9, tc9_match

    	lb  $s3, 0($s1)
    	lb  $s4, 0($s0)
    	bne $s3, $s4, tc9_advance

    	addi $s1, $s1, 1
    	addi $s0, $s0, 1
    	addi $s2, $s2, 1
    	j    tc9_lit

tc9_advance:
    	addi $t0, $t0, 1
    	j    tc9_main

# -matches
tc9_match:
    	add $s5, $t3, $t9
    	move $s3, $t0

# write token1 match → buffer1
tc9_write_buf1:
    	beq $t3, 0, tc9_write_buf2
    	lb  $t4, 0($s3)
    	sb  $t4, buffer1($s6)
    	addi $s6, $s6, 1
    	addi $s3, $s3, 1
    	addi $t3, $t3, -1
    	j    tc9_write_buf1

# write literal → buffer2
tc9_write_buf2:
    	beq $t9, 0, tc9_next
    	lb  $t4, 0($s1)
    	sb  $t4, buffer2($s7)
    	addi $s7, $s7, 1
    	addi $s1, $s1, 1
    	addi $t9, $t9, -1
    	j    tc9_write_buf2

tc9_next:
    	addi $t0, $t0, 1
    	j    tc9_main
	
tc9_done:
    	jr $ra

# Combine buffer1 + buffer2 into buffer3
	la $t0, buffer1
	la $t1, buffer3
	move $t2, $zero

tc_copy_b1:
    	lb $t3, 0($t0)
    	beq $t3, 0, tc_copy_b2
    	sb $t3, 0($t1)
    	addi $t0, $t0, 1
    	addi $t1, $t1, 1
    	j tc_copy_b1

tc_copy_b2:
    	la $t0, buffer2

tc_copy_b2_loop:
    	lb $t3, 0($t0)
    	beq $t3, 0, tc_print_final
    	sb $t3, 0($t1)
    	addi $t0, $t0, 1
    	addi $t1, $t1, 1
    	j tc_copy_b2_loop

tc_print_final:
    	la $a0, buffer3
    	li $v0, 4
    	syscall

	
#==================================================
exit:
	li $v0, 10
	syscall
