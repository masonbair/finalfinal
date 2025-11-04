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

