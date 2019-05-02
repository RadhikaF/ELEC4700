import numpy as np
import struct
import sys
import math

n = 64

maxNum32 = 2 ** 32 - 1
maxMatrixCell = int(math.sqrt(maxNum32 / n))
print('Maximum cell value: ' + str(maxMatrixCell))

#Generate random matrix
a = np.random.randint(0, maxMatrixCell, size=(n,n), dtype=np.uint32)

# 4x4 test matrix
#a = np.array([[1,2,3,4], [5,6,7,8], [9,10,11,12], [13,14,15,16]])

b = np.dot(a, a.T)

#Print matrix
print('flat a =', a.flatten('F'))
print('a =\n', a)
print('a.T =\n', a.T)
print('b =\n', b)

#Write out matrix to binary file
with open('D:\\ELEC4700\\Uni Computer TransferaMatrix', 'wb') as outFile:
	for elem in a.flatten('F'):
		val = struct.pack('<I', int(elem))
		bytes = bytearray(val)
		outFile.write(bytes)