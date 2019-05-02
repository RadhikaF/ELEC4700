import numpy as np
import struct
import sys

n = 64
memoryFilePath = "D:\\ELEC4700\\Uni Computer Transfer\\outmatrix.bin"

def readMatrix(n, filePath, skip=0):
	a = np.zeros(n*n, dtype=np.uint32)
	with open(filePath, 'rb') as inFile:
		if skip > 0:
			inFile.read(4 * skip)
		
		for i in range(n*n):
			bytes = inFile.read(4)
			
			val = struct.unpack('<I', bytes)[0]
			
			a[i] = val;
	return a.reshape((n, n)).T

a = readMatrix(n, 'C:\\Users\\c3195884.UNCLE\\Downloads\\aMatrix')
aAfter = readMatrix(n, memoryFilePath)
bAfter = readMatrix(n, memoryFilePath, skip=n*n)
bTrue = np.dot(a, a.T)

print('a =\n', a)
print('bAfter =\n', bAfter)
print('bTrue =\n', bTrue)

print('\n')

if (bAfter == bTrue).all():
	print('Correct')
else:
	print('bAfter matrix is incorrect')