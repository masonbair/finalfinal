# Mason Bair
# Savar Shrestha
# Sumedh Joshi

## ------ TOKENIZER ----- ##
# This is the idea for the Tokenizer, which will produce computable results for evaluation.
# We have an 8 byte Register per token, and each token will represent a difference piece of information for the token

#Byte 1: Type
#Byte 2: ^
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
	
	.align 2                    # Align to word boundary (2^2 = 4 bytes)
    	tokenArray: .space 64
    	tokenDebugMsg: .asciiz "Token: "
    
    	.align 2                    # Align literal buffer too
    	literalDataBuffer: .space 128
	
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
	beq $t3, 10, exit		# Exits the program when it finds the new line char, which is the end of the input
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
    	addi $t5, $t5, 8	# Move to the next token position
    
    	# Check if reached end of input
    	beq $t3, 10, exit   # If newline, we are finished
    	beq $t3, 0, exit    # If null terminator, we are finsihed
    	
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
    # Print "Token: "
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
    
    j what_to_do
    
# ===============================================================   
what_to_do:
	la $t5, tokenArray     # first token
	lb $t0, 0($t5)         # token type
	
	# Branch for test case 1
	li $t1, 1
	beq $t0, $t1, Test_case_1
	
	# Branch for test case 2
	li $t1, 2 
	beq $t0, $t1, test_case_2
	
	j exit                 # Till all the functions are made this is just a precausino
#============================================================
Test_case_1:
    lw $t1, 4($t5)         #   literal data in token
    la $t2, InputToEvaluate  
    lb $t3, 2($t5)         # token length

    li $t4, 0              # index inside literal
    li $t6, 0              # index inside input

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
    lb $t3, 2($t5)      # *** reload literal length ***
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
    # making copies so not to mess up original pointers
    move $t8, $t2      # end pointer
    move $t9, $t3      # length

    sub $t8, $t8, $t9  # t8 = start of matched substring

printMatch_loop:
    beqz $t9, printMatch_done   # finished printing substring

    lb $a0, 0($t8)      # print each character
    li $v0, 11
    syscall

    addi $t8, $t8, 1    # next input char
    addi $t9, $t9, -1   # reduce length
    j printMatch_loop

printMatch_done:
    # Print comma
    li $a0, ','
    li $v0, 11
    syscall

    jr $ra

	
#################################
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
	beq $t4, 0, char_input_increment	#check if the flag is set to 0
	
	#print matched char
	li $v0, 11
	move $a0, $t1
	syscall	
	
	#print comma
	li $v0, 11
	li $a0, ','
	syscall
	

char_input_increment:
	addi $t0, $t0, 1 	# increment the input string
	lb $t1, 0($t0)		# continue scanning
	j char_input_loop

###################################3
exit:
	li $v0, 10	# exit elegantly
	syscall
