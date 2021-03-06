''' Operators in Batch language:

* EXP - '^' for exponent
* EQ - ':=' for assignment
* EQ_TST - '==' for equality testing
* PAIR - 'e(' arg1, arg2 ')'
* CONST - 'constant' declarator?
* VARIABLE - 'variable' declarator?
* PROD - 'prod{i:=1,N} on' applied to 
* ARR - 'a_1' for an array, a, with index = 1
* LIST - '[ x, y, z,...]' 

e.g., prod{i:=1,N} on pk_i ^ del_i 

AST simple rules

* check constraints assignment node exists.
* check verify assignment node exists.
* check variables have appropriate assignment types.
* support batch for different messages/signers/public keys.
'''

from enum import *
import string

types = Enum('G1', 'G2', 'GT', 'ZR', 'str')
declarator = Enum('constants', 'verify')
ops = Enum('BEGIN', 'TYPE', 'ADD', 'MUL', 'EXP', 'EQ', 'EQ_TST', 'PAIR', 'ATTR', 'HASH', 'PROD', 'ON', 'CONCAT','LIST','END', 'NONE')
levels = Enum('none', 'some', 'all')
debug = levels.none

class BinaryNode:
	def __init__(self, value, left=None, right=None):		
		if(isinstance(value, str)):
			if value in ['G1', 'G2', 'GT', 'ZR', 'str']:
				self.type = ops.TYPE
				self.attr = types[value]
				self.attr_index = None
			else:
				self.type = ops.ATTR
				arr = value.split('_')
				self.attr = arr[0]
				if len(arr) > 1: # True means a_b form
					self.attr_index = [arr[1]]
				else: # False means a and no '_' present
					self.attr_index = None
		elif value > ops.BEGIN and value < ops.END:
			self.type = value
			self.attr = None
			self.attr_index = None
		else:
			self.type = ops.NONE
			self.attr = None
			self.attr_index = None
		self.left = left
		self.right = right

	def __str__(self):
		if(self.type == ops.ATTR):
			msg = self.attr
			if self.attr_index != None and type(self.attr_index) == list:
				token = ""
				for t in self.attr_index:
					token += t + ","
				l = len(token) 
				token = token[:l-1]
				msg += '_' + token
			return msg
		elif(self.type == ops.TYPE):
			return str(self.attr)
		else:			
			left = str(self.left)
			right = str(self.right)
			
			if debug >= levels.some:
			   print("Operation: ", self.type)
			   print("Left operand: ", left, "type: ", self.left.type)
			   print("Right operand: ", right, "type: ", self.right.type)
			if(self.type == ops.EXP):
				return (left + '^' + right)
			elif(self.type == ops.MUL):
				return ('(' + left + ' * ' + right + ')')
			elif(self.type == ops.ADD):
				return ('(' + left + ' + ' + right + ')')
			elif(self.type == ops.EQ):
				return (left + ' := ' + right)
			elif(self.type == ops.EQ_TST):
				return (left + ' == ' + right)
			elif(self.type == ops.PAIR):
				return ('e(' + left + ',' + right + ')')
			elif(self.type == ops.HASH):
				return ('H(' + left + ',' + right + ')')
			elif(self.type == ops.PROD):
				return ('prod{' + left + ',' + right + '}')
			elif(self.type == ops.ON):
				 return ('(' + left + ' on ' + right + ')')
			elif(self.type == ops.LIST):
				 return ('[' + left + ']' )
			elif(self.type == ops.CONCAT):
				 return (left + ' | ' + right)
				# return ( left + ' on ' + right )				
		return None
	
	def setAttrIndex(self, value):
		if(self.type in [ops.ATTR, ops.HASH]):
			if self.attr_index == None: # could be a list of indices
				self.attr_index = [value]
			else:
				self.attr_index.append(value)
			return True
		return False
	
	def getAttribute(self):
		if (self.type == ops.ATTR):
			return self.attr
		else:
			return None
	
	def getLeft(self):
		return self.left
	
	def getRight(self):
		return self.right

	def addSubNode(self, left, right):
		# set subNodes appropriately
		self.left = self.createSubNode(left) if left != None else None
		self.right = self.createSubNode(right) if left != None else None
		if debug == levels.all:
			print("addSubNode: ");
			print("left type =>", type(self.left), ' =>', self.left)
			print("right type =>", type(self.right), ' =>', self.right)

	def createSubNode(self, value):
		if isinstance(value, str):
			node = BinaryNode(value)		   
			return node
		return value

	@classmethod
	def copy(self, this):
		if this == None: return None
		new_node = BinaryNode(this.type)
		new_node.attr = this.attr
		new_node.attr_index = this.attr_index
		
		# recursively call copy on left 
		new_node.left = self.copy(this.left)
		new_node.right = self.copy(this.right)		
		return new_node	

	# only applies function on leaf nodes
	def traverse(self, function):
		# visit node then traverse left and right
		function(self.type, self)
		if(self.left == None):
			return None
		self.left.traverse(function)
		if(self.right == None):
			return None
		self.right.traverse(function)
		return None	
	
	
	
