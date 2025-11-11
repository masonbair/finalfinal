# Mason Bair

# This is the beginning of the final final for computer org.
# The goal is to make a regular expression program

############################################################
#                REGULAR EXPRESSION TEST CASES
#-----------------------------------------------------------
# Each test demonstrates a different regular expression 
# pattern, what it matches, and the expected output.
############################################################

#-----------------------------------------------------------
# 1. Basic String Match
# Expression:      abc
# Description:     Matches the exact sequence "abc".
# Input 1:         abc
# Output:          abc
# Example 2 Input: abcdbefabc
# Expected Matches: abc, abc
#-----------------------------------------------------------

# 2. Character Class
# Expression:      [abc]
# Description:     Matches any single character a, b, or c.
# Input 1:         a, b, c, a, b, b, b, c
# Output:          a b c a b b b c
# Example Input:   abcdefabbbc
# Expected Matches: a, b, c, a, b, b, b, c
#-----------------------------------------------------------

# 3. Character Class with Repetition
# Expression:      [abc]*
# Description:     Matches zero or more characters that are 
#                  either a, b, or c in a row.
# Input 1:         abc, abbc
# Example Input:   abcefabbc
# Expected Matches: abc, abbc
#-----------------------------------------------------------

# 4. Wildcard
# Expression:      .
# Description:     Matches any single character (letter, 
#                  number, or symbol).
# Input 1:         1, 2, 3, a, b, c
# Example Input:   123abc
# Expected Matches: 1, 2, 3, a, b, c
#-----------------------------------------------------------

# 5. Wildcard with Repetition
# Expression:      .*
# Description:     Matches any number of any characters.
# Input 1:         .*
# Example Input:   345Hello There
# Expected Matches: 345Hello There
#-----------------------------------------------------------

# 6. Uppercase Letters Only
# Expression:      [A-Z]*
# Description:     Matches zero or more uppercase letters.
# Input 1:         [A-Z]* 
# Example Input:   345Hello There
# Expected Matches: H, T
#-----------------------------------------------------------

# 7. Negated Character Class
# Expression:      [^A-z]*
# Description:     Matches characters that are NOT letters.
# Input 1:         [^A-z]*
# Example Input:   345Hello There
# Expected Matches: 345, ' '
#-----------------------------------------------------------

# 8. Domain Ending (.edu)
# Expression:      [A-z]*\.edu
# Description:     Matches any sequence of letters ending 
#                  with ".edu".
# Example Input:   emgail@kent.edumjmhb
# Expected Matches: kent.edu
#-----------------------------------------------------------

# 9. Email at Kent Domain
# Expression:      [A-z]*@kent\.edu
# Description:     Matches any email that ends with 
#                  "@kent.edu".
# Example Input:   123some@kent.edumjmhb
# Expected Matches: some@kent.edu
#-----------------------------------------------------------

# EXTRA CREDIT
# Expression:      [a-z0-9]*
# Description:     Matches lowercase letters and digits.
# Input 1:         Ello, here, 2006
# Expected Matches: Ello, here, 2006
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
	
	
# For the actual development of the reg expressions, I think it would be best to build it recursively.
# Here is an example:
# [^a-z]*
# This expression would first say, we are dealing with a string a-z
# And then we see the negate and say, we are dealing with a string not a-z
# and then we see the [] and say, we are dealing with macthing single characters not in a-z
# and then we see the * and say, we are dealing with matching set of chracters not in a-z
	
# After chatting with ChatGPT, it agreed with the recursion approach
# In addition I also think we should split up the regular expression into tokens
# EI [^a-z]* becomes -> "[", "^", "a-z", "]", "*" and then we evaluate

# The tricky part comes from figuring out how to make the recursion work. Like how would that be accomplished, idk hahahaa

###---------###
# Okay here is the idea. 
# We first make a tokenizer for the Regex expression.
# Then this tokenized version gets stored in an array and gets looped through for one or more characters. 
# Still needs some thinking


## ------ TOKENIZER ----- ##
# This is the idea for the Tokenizer, which will produce computable results for evaluation.
# We have an 8 byte Register per token, and each token will represent a difference piece of information for the token

#Byte 1: Type
#Byte 2: Flags ( Negate ^ or Escaped ]\ )
#Byte 3: Len (How many chars of data does this token have)
#Byte 4: Padding (Does not represent anything, just used to keep the token 8 bytes
#Byte 5-8: Data - byte 5: A, byte 6: z for example.

## TOKEN TYPES ##
# 1. Literal: "a" or "hello": needs to match exactly
# 2. Char class: Matches any character inside of the char list: [a-z], [c-d], [A-z]



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
    	j literalTokenize

# Needs to take the whole literal value and store it in the data section of the token	
literalTokenize:
	la $t9, literalDataBuffer		# The t9 register will be pointing at the string buffer for literals
	
	sw $t9, 4($t5)		# Stores the address for the literalDataBuffer in the token at byte 4
	
	li $t6, 0		#Represents the character length of the literal we are dealing with
	

literalLoop:
    	beq $t3, 91, literalDone   #Front bracket stop
    	beq $t3, 10, literalDone   #Newline stop
    	beq $t3, 42, literalDone   # If '*', stop
    
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
    
    	li $t7, 1
    	sb $t7, 3($t5)             # Set repetition flag
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
    	j printToken	# Breaks out of char array increment loop and goes back to regular tokenizer	

	
#Either called printtoken
nextToken:
    	addi $t5, $t5, 8	# Move to the next token position
    
    	# Check if reached end of input
    	beq $t3, 10, exit   # If newline, we are finished
    	beq $t3, 0, exit    # If null terminator, we are finsihed
    	
    	# Advance to next character before tokenizing
    	add $t2, $t2, $t0          	# Move to next char
    	lb $t3, 0($t2)  		# Loads in the next value
    
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
	
	bne $t3, 45, charRangeLiteral
	
    
	# Load the second character 
	add $t2, $t2, $t0  # i++
	lb $t3, 0($t2)     # Load second char into $t3
	sb $t3, 5($t5)     # Store second char at byte 5
    
	li $t7, 2          # Length = 2 (two characters)
	sb $t7, 2($t5)     # Store length in byte 2
    
	li $t8, 2          # We've written 2 data bytes
	j charArrayIncrement

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
    
    j nextToken

exit:
	li $v0, 10
	syscall