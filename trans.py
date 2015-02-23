#! /usr/bin/env python

#Pyparsing Module Copyright Notice:
#Copyright (c) <year> <copyright holders>

#Permission is hereby granted, free of charge, to any person obtaining a copy of this 
#software and associated documentation files (the "Software"), to deal in the Software 
#without restriction, including without limitation the rights to use, copy, modify, 
#merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
#permit persons to whom the Software is furnished to do so, subject to the following 
#conditions:

#The above copyright notice and this permission notice shall be included in all copies 
#or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
#INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
#PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
#LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
#TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
#OR OTHER DEALINGS IN THE SOFTWARE.

# initialization

import sys
from pyparsing import *
sys.setrecursionlimit(99)

#************************************************************************************
#
#                    Data Section
#
#************************************************************************************
#------------------------------------------------------------------------------------
# constants - MAX_FORMATS is the number of instruction formats
#           - equal to the number of columns in the inst_table
#------------------------------------------------------------------------------------
MAX_FORMATS=12


#------------------------------------------------------------------------------------
# symbol table - dictionary used to translate labels to offsets
#              - built during first pass over input file.
#              - symbols resolved during 2nd pass over inter_array
#------------------------------------------------------------------------------------
d_symbols={}


#------------------------------------------------------------------------------------
# intermediate array - holds parsed code values after first pass of input file
#                    - still contains symbol references
#------------------------------------------------------------------------------------
inter_array=[]


#------------------------------------------------------------------------------------
# location counter - incremented after each instruction is 
#                    processed in the first pass
#                  - used to build the symbol table dictionary entries
#------------------------------------------------------------------------------------
loc_offset=0


#------------------------------------------------------------------------------------
# Function definitions start here.
#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
# '.space' assembler directive
#------------------------------------------------------------------------------------

def do_space(operands):
    if operands!="":
        return [True,int(operands)]
    else:
        return [False,0]


#------------------------------------------------------------------------------------
# '.byte' assembler directive
#------------------------------------------------------------------------------------
def do_byte(operands):
    if operands!="":
        return [True,number_of_items(operands)]
    else:
        return [False,0]
 

#------------------------------------------------------------------------------------
# '.word' assembler directive
#------------------------------------------------------------------------------------
def do_word(operands):
    if operands!="":
        return [True,2*number_of_items(operands)]
    else:
        return [False,0]


#------------------------------------------------------------------------------------
# '.long' assembler directive
#------------------------------------------------------------------------------------
def do_long(operands):

    if operands!="":
        return [True,4*number_of_items(operands)]
    else:
        return [False,0]


#------------------------------------------------------------------------------------
# helper function for do_storage
# 
#    (#commas + 1) tells how many items in list.
#------------------------------------------------------------------------------------
def number_of_items(list):

    return list.count(',') + 1


#------------------------------------------------------------------------------------
# '.ascii' assembler directive
#          -  must subtract number of '\' escape characters from the length 
#             of the field.  
#------------------------------------------------------------------------------------
def do_ascii(operands):
    if operands!="":
        return [True,operands.__len__() - 2 - operands.count('\\')]
    else:
        return [False,0]


#------------------------------------------------------------------------------------
# '.string' assembler directive
#          -  must subtract number of '\' escape characters from the length
#             of the field.  
#          -  must add one byte to the field length for the null that is
#             added by the assembler.
#------------------------------------------------------------------------------------
def do_string(operands):
    if operands!="":
        return [True,operands.__len__() - 2 - operands.count('\\') + 1]
    else:
        return [False,0]


#------------------------------------------------------------------------------------
# Substitute the location offset in any place where a '.' notation
# is used in the operands.
#------------------------------------------------------------------------------------
def do_dot(operands):

    # Change offset to character to write into instruction
    dot_addr='%i' %loc_offset

    # Allow current location to be specified by a '.'  
    operands=operands.replace('.',dot_addr)
    return operands


#------------------------------------------------------------------------------------
# Dictionary containing the valid instruction formats for each instruction. 
# The operation code for the instruction is listed in the column for each valid
# format. The 'length' entry gives the instruction format length to calculate 
# the location offset. 
#------------------------------------------------------------------------------------
#             0  = no operands
#             1  = Rd
#             2  = *Rd
#             3  = memaddr
#             4  = Rd,Rs
#             5  = Rd,*Rs
#             6  = Rd,$immed
#             7  = Rd,memaddr[Rs]
#             8  = Rd,memaddr
#             9  = $immed,$immed
#             10 = Rd,Rs,memaddr
#             11 = Rd,$immed,memaddr
#------------------------------------------------------------------------------------
# instruction format #(' 0',' 1',' 2',' 3',' 4',' 5',' 6',' 7',' 8',' 9','10','11',)

inst_table={'rinit':  ('00',   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,),\
            'rsens':  ('01',   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,),\
            'rspeed': (   0,   0,   0,   0,'02',   0,   0,   0,   0,'03',   0,   0,),\
            'ld':     (   0,   0,   0,   0,'04','08','05','07','06',   0,   0,   0,),\
            'st':     (   0,   0,   0,   0,   0,'0B',   0,'0A','09',   0,   0,   0,),\
            'and':    (   0,   0,   0,   0,'0C','10','0D','0F','0E',   0,   0,   0,),\
            'or':     (   0,   0,   0,   0,'11','15','12','14','13',   0,   0,   0,),\
            'eor':    (   0,   0,   0,   0,'16','1A','17','19','18',   0,   0,   0,),\
            'not':    (   0,'1B',   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,),\
            'jmp':    (   0,   0,'25','1C',   0,   0,   0,   0,   0,   0,   0,   0,),\
            'jgt':    (   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,'1D','21',),\
            'jlt':    (   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,'1E','22',),\
            'jeq':    (   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,'1F','23',),\
            'jez':    (   0,   0,   0,   0,   0,   0,   0,   0,'20',   0,   0,   0,),\
            'jal':    (   0,   0,   0,   0,   0,   0,   0,   0,'24',   0,   0,   0,),\
            'add':    (   0,   0,   0,   0,'26','2A','27','29','28',   0,   0,   0,),\
            'length': (   2,   2,   2,   4,   2,   2,   6,   4,   4,  10,   4,   8,)}
 
#------------------------------------------------------------------------------------
# Table to determine which asembler directive routine to call based on operation.
#------------------------------------------------------------------------------------ 
dir_table={ '.equ':   '',\
            '.space': do_space,\
            '.byte':  do_byte,\
            '.word':  do_word,\
            '.long':  do_long,\
            '.ascii': do_ascii,\
            '.string':do_string}


#************************************************************************************
# Grammar rules for pyparsing
#************************************************************************************
# Literals:
#----------
literal_R=Literal("R").suppress()
literal_colon=Literal(":").suppress()
literal_dollar=Literal("$").suppress()

# instruction building blocks:
#-----------------------------
hex_value=Word(hexnums,exact=1)
arith_ops=Word("+-*/().")
identifier=Word(alphas+"_",alphanums+"_")

memaddr=Word(alphanums+"_+-*/().")
register=Combine(literal_R+hex_value)
immediate=Combine(literal_dollar+memaddr)

# Make string of valid operations so that new operations
# will automatically be added to list from tables above. 
#-------------------------------------------------------
valid_operations=""
for key in inst_table:
    valid_operations+=key+" "
for key in dir_table:
    valid_operations+=key+" "


# top level tokens:
#------------------
label=Combine(identifier+literal_colon)
operation=oneOf(valid_operations)
operands=Word(alphanums+"_+-*/()[],.$")
string_operand=dblQuotedString

# parsing rule for lines in file:
#--------------------------------
instruction=Optional(label).setResultsName("label")+\
            Optional(Optional((operation).setResultsName("operation"))+\
                     Optional((operands).setResultsName("operands"))+\
                     Optional((string_operand).setResultsName("operands")))

# parsing expressions for each instruction format
#------------------------------------------------
format1=register.setResultsName("Rd")+\
        Optional((restOfLine).setResultsName("rest"))

format2="*"+register.setResultsName("Rd")+\
        Optional((restOfLine).setResultsName("rest"))

format3=memaddr.setResultsName("memaddr")+\
        Optional((restOfLine).setResultsName("rest"))

format4=register.setResultsName("Rd")+","+register.setResultsName("Rs")+\
        Optional((restOfLine).setResultsName("rest"))

format5=register.setResultsName("Rd")+",*"+register.setResultsName("Rs")+\
        Optional((restOfLine).setResultsName("rest"))

format6=register.setResultsName("Rd")+","+immediate.setResultsName("immed1")+\
        Optional((restOfLine).setResultsName("rest"))

format7=register.setResultsName("Rd")+","+memaddr.setResultsName("memaddr")+\
        "["+register.setResultsName("Rs")+"]"+\
        Optional((restOfLine).setResultsName("rest"))

format8=register.setResultsName("Rd")+","+memaddr.setResultsName("memaddr")+\
        Optional((restOfLine).setResultsName("rest"))

format9=immediate.setResultsName("immed1")+","+immediate.setResultsName("immed2")+\
        Optional((restOfLine).setResultsName("rest"))

format10=register.setResultsName("Rd")+","+register.setResultsName("Rs")+","+\
         memaddr.setResultsName("memaddr")+\
        Optional((restOfLine).setResultsName("rest"))

format11=register.setResultsName("Rd")+","+immediate.setResultsName("immed1")+","+\
         memaddr.setResultsName("memaddr")+\
        Optional((restOfLine).setResultsName("rest"))


#------------------------------------------------------------------------------------
# Parse the instruction operands based on the valid formats as defined for an
# instruction in the instruction table and the parsing rules,
# format1 through format11. 
#------------------------------------------------------------------------------------
def do_instruction(operation,operands):
    result=[True,[],0]
    operands=do_dot(operands)
    count=0
    for format in inst_table[operation]:

        #-------------------------------------------------
        # If the instruction table indicates a possible
        # valid "op code", check the operands against the
        # parsing rule.
        #-------------------------------------------------
        if format:
            char_count='%i'%count
            result[0]=True

            #---------------------------------------------
            # format 0 is a special case because these
            # instructions do not have operands, therefore
            # there is no parse rule to try.
            #---------------------------------------------
            if count==0:
                if operands=="":
                    result[1]=[format,'0','0','','','']
                    result[2]=inst_table['length'][count]
                else:
                    result[0]=False

            else:
                try:
                    parse_operand=eval("format"+char_count).parseString\
                                      (tokens.operands)
                    if parse_operand.rest=='':
                        # set defaults if no registers specified 
                        if parse_operand.Rd=='':
                            Rd='0'
                        else:
                            Rd=parse_operand.Rd 
                        if parse_operand.Rs=='':
                            Rs='0'
                        else:
                            Rs=parse_operand.Rs 
                        result[1]=[format,Rd,Rs,\
                                   do_dot(parse_operand.memaddr),\
                                   do_dot(parse_operand.immed1),\
                                   do_dot(parse_operand.immed2)]
                        result[2]=inst_table['length'][count]
                    else:
                        result[0]=False
                except ParseException, err:
                    result[0]=False
         
            if result[0]:
                break
        
        count+=1
          
    return result


#------------------------------------------------------------------------------------
# Evaluate an expression to return a value.  Translate an expression by using the
# symbol table to substitute values for labels as needed.
#------------------------------------------------------------------------------------
def do_translate(value):
    count_iter=0
    need_trans=True
    while need_trans==True:
        try:
            int_value=eval(value)
            return ('%i' %int_value)

        except:
            count_iter+=1
            if count_iter>6: 
                print "invalid substitution in ",value
                return '0'
            translate=Word(alphas+"_",alphanums+"_")
            substitutions=translate.searchString(value)

            for matched_token in substitutions:
                try:
                    value=value.replace(matched_token[0],\
                          ('('+d_symbols[matched_token[0]]+')'))
               
                except: 
                    print "value: ", value
                    print "label not found in symbol table: ",\
                          matched_token[0]
                    return '0'


#------------------------------------------------------------------------------------
# Call the translation routine for each item in a list of values that
# is separated by commas - valid for assembly directives.
#------------------------------------------------------------------------------------
def do_translate_list(comma_separated_list):

    separated_list=comma_separated_list.split(',')
    new_string=""

    for item in separated_list:
        item=do_translate(item)
        if new_string=="":
            new_string+=item
        else:
            new_string+=","+item

    return new_string


#************************************************************************************
#
#                    Get file names and open input file
#
# Get input and output file names from the argument list.
# The first argument is the input file name.
# The second argument is the output file name.
# If names are not specified: input file is set to 'input.s'.
#                             output file is set to 'output.s'.
#
#************************************************************************************
if len(sys.argv) == 3:
    outfile=sys.argv[2]
    infile=sys.argv[1]
elif len(sys.argv) == 2:
    outfile='output.s'
    infile=sys.argv[1]
else:
    outfile='output.s'
    infile='input.s'

fi=open(infile,'r')


#************************************************************************************
#
#                    Process each input file line
#
#************************************************************************************

for line in fi:

#------------------------------------------------------------------------------------
# Pyparsing is used to separates each line into tokens. It discards comments
# (from # to end of line). There can be one to three tokens in a line of input:
#                       label:  operation  operands
#------------------------------------------------------------------------------------

    tokens=instruction.parseString(line)


#------------------------------------------------------------------------------------
# Process labels and '.equ' statements to build the symbol table.
#------------------------------------------------------------------------------------
    #-----------------------------------------------------
    # Labels are written to the symbol dictionary with the
    # value equal to the current location.  They are not
    # written to the intermediate array.
    #-----------------------------------------------------
    if tokens.label:
        key=tokens.label
        # Change offset to character to write to dictionary.
        d_symbols[key]='%i' %loc_offset 


    #-----------------------------------------------------
    # The '.equ' assembler directive is unique in that it
    # is used to set a symbol in the dictionary (similiar 
    # to the label processing).  It is not written to the
    # intermediate array. 
    #-----------------------------------------------------
    if (tokens.operation=='.equ' and tokens.operands!=""):         
        # The label that was just written to 
        # the symbol table is updated to 
        # reflect the '.equ' value instead of
        # the current location offset.
        d_symbols[key]=do_dot(tokens.operands)
        continue


#------------------------------------------------------------------------------------
# Call routine based on the instruction specified. This first pass determiness the
# length of the instruction which is added to the location offset.
#------------------------------------------------------------------------------------

    if (not tokens.operation) and tokens.operands:
        print "line= ", tokens.operation, tokens.operands
        print "invalid operation"        

    if tokens.operation:

        if inst_table.has_key(tokens.operation):
            result=do_instruction(tokens.operation,tokens.operand)
         
            if result[0]:
                loc_offset+=result[2]
                inter_array.append(result[1])
                    
            else:
                print "line= ", tokens.operation, tokens.operands
                print 'invalid format' 

        else:
            if dir_table.has_key(tokens.operation):
                result=dir_table[tokens.operation](tokens.operands)
         
                if result[0]:
                    inter_array.append([tokens.operation,do_dot(tokens.operands)])
                    loc_offset+=result[1]
                    
                else:
                    print "line= ", tokens.operation, tokens.operands
                    print 'invalid format' 


#------------------------------------------------------------------------------------
# All of the instructions have been through one pass at this point. 
# The parsed fields are in the list called inter_array. 
#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
# The symbol table may contain expressions from '.equ' statements that should be 
# translated to offsets to be used in writing the final translated code.
#------------------------------------------------------------------------------------

for key,value in d_symbols.iteritems():
    d_symbols[key]=do_translate(value)


#------------------------------------------------------------------------------------
# Process the token lists in the inter_array to format the final code.
# The instructions will be in the format:
#             ['op code','Rd','Rs','memaddr','immed1','immed2']
# Assembler directives will be:
#             ['operation','operands']
#------------------------------------------------------------------------------------

fo=open(outfile,'w')

for line in inter_array:

    if dir_table.has_key(line[0]):
        #-------------------------------------------------------------
        # Directives are passed to the output file in the same format
        # as they were written. '.string' and '.ascii' statements need
        # be quoted.
        #-------------------------------------------------------------
                    
        if line[0] in ('.string','.ascii'):
            fo.write('        '+line[0]+'  '\
                               +line[1]+'\n')
        else:
            fo.write('        '+line[0]+'  '\
                                           +do_translate_list(line[1])+'\n')

    else:
        #-------------------------------------------------------------
        # All instructions have the opcode and register line
        # written.  The other lines are written based on the 
        # instruction type.
        #-------------------------------------------------------------

        fo.write("        .byte  0x"+line[0]+\
                 ",0x"+line[1]+line[2]+'\n')

        if line[3]!="":
            fo.write('        .word  '+do_translate(line[3])+'\n')

        if line[4]!="":
            fo.write('        .long  '+do_translate(line[4])+'\n')
 
        if line[5]!="":
            fo.write('        .long  '+do_translate(line[5])+'\n')


#**************************************************************************
# Final processing - Write rest of virtual memory with 0xFF
#**************************************************************************

mem_fill=65536-loc_offset
mem_char='%i' %mem_fill
fo.write('        .rept  '+mem_char+'\n')
fo.write('        .byte  0xFF'+'\n')
fo.write('        .endr'+'\n')

                        
