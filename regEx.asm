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
	
	tokenArray: .space 40
	
	
	
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
	lb $t6, 0($t4)			# Loads byte value
	
	
reset:		# Called when a token is finished building and the values need to be reset
	li $t7, 0		# t7 represents what ever value we are adding to the token array

tokenize:	
	beq $t3, 10, exit		# Exits the program when it finds the new line char, which is the end of the input
	j printChar			# Calls a jump to printchar
	
	beq $t3, 91, frontBracket	# Represents the token is a Char class
	
	j increment
	


# Still need to deal with the range of values in the chararray
# Plus the *
# Also need to make a way to print out the tokens so I can make sure everything is working correctly
charArrayTokenize:
	beq $t3, 94, negate
	beq $t3, 93, backBracket



frontBracket:	# Means we are dealing with a char array
	li $t7, 2		# 2 should be going into the first spot of the token, which means when we evaluate it that we are dealing with a char class
	sb $t7, 0($t5)		# Store the value of $t7 into the token array at location $t5
	j charArrayIncrement		# Continues to read through the other pieces until we reach the end bracket

backBracket:
	j increment	# Breaks out of char array increment loop and goes back to regular tokenizer

negate:
	li $t7, 1 		# One means negate for the second byte
	sb $t7, 0($t5)
	j charArrayIncrement

charArrayIncrement:
	add $t2, $t2, $t0		#Finds new index memory location. 
					# t0 is always 1 and since we ar ein a buffer, each byte is only 1 over
					# This means that to move to the next spot for a character we can just add t2 with t0 and store it back in t2
					# This is essentially t2++
	add $t5, $t5, $t0
					
	lb $t3, 0($t2)			# This loads the next byte of the buffer into t3
	j charArrayTokenize


increment:
	add $t2, $t2, $t0		#Finds new index memory location. 
					# t0 is always 1 and since we ar ein a buffer, each byte is only 1 over
					# This means that to move to the next spot for a character we can just add t2 with t0 and store it back in t2
					# This is essentially t2++
					
	lb $t3, 0($t2)			# This loads the next byte of the buffer into t3
	j tokenize


printChar:
	move $a0, $t3		# Loads char value in t3 into a0
	li $v0, 11		#11 means print character, $a0 is the char to print
	syscall
	
	j increment


	
# basic: Matches an exact string literally (e.g., "abc").
basic:

# brackets: Matches any one character inside the brackets (e.g., [abc]).
brackets:

# asterixs: Matches zero or more of the preceding pattern (e.g., [abc]*).
asterixs:

# period: Matches any single character (wildcard for one).
period:

# negate: Matches anything NOT inside the brackets (e.g., [^A-Z]).
# requirement: Must be inside brackets [ ]; caret (^) must come immediately after '['.
negate:

# forwardslash: Escapes special characters like '.' so they are treated literally. (e.g., \.edu looks for .edu)
forwardslash:


exit:
	li $v0, 10
	syscall