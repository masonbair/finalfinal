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


