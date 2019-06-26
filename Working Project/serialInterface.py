import math
import numpy as np
import serial
import struct
import sys
import time
import argparse

commandWriteSRAM = bytes([0, 0, 0, 1])
commandReadSRAM = bytes([0, 0, 0, 2])
commandRunCPU = bytes([0, 0, 0, 3])
commandReadTimer = bytes([0, 0, 0, 4])
commandReadMemoryOperationsCounter = bytes([0, 0, 0, 5])
commandCheckConnection = bytes([0, 0, 0, 6])

lengthSRAM = 10000 #Must match value used in verilog SRAM module
# SRAM contains (indices are 32 bit words, NOT BYTES!)
# 0 - 4095 = A matrix
# 4096 - 8191 = B matrix
# 8192 - 10000 = Program code (if storing program in SRAM)

def panic(bytes):
	print('PANIC: only received', len(bytes), 'bytes out of 4')
	print('Have you programmed the FPGA with your project?')
	print('Check the USB/serial cable is connected and the serial port is correct (--port argument)')
	print('This can also occur if you have tried to test/run your CPU and it hasn\'t set the cpuDoneFlag')
	exit()

def magicPanic(magicNumber):
	print('PANIC: magic number is incorrect (received invalid response from serial port)')
	print('Check you have connected the SRAM module to the UART pins correctly')
	exit()

def generateA(n):
	#Generate random test matrix
	maxNum32 = 2 ** 32 - 1
	maxMatrixCell = int(math.sqrt(maxNum32 / (4*n)))
	#print('Maximum cell value: ' + str(maxMatrixCell))
	return np.random.randint(0, maxMatrixCell, size=(n,n), dtype=np.uint32)

def writeMatrixToFile(m, path):
	#Write out matrix to binary file
	with open(path, 'wb') as outFile:
		for elem in m.flatten('F'):
			val = struct.pack('<I', int(elem))
			bytes = bytearray(val)
			outFile.write(bytes)

def readSRAM():
	print('Reading... ', end='', flush=True)
	content = lengthSRAM * [0]
	port.write(commandReadSRAM)
	
	#Ignore the first value because it's from the end of SRAM
	bytes = port.read(4)
	if len(bytes) != 4:
		panic(bytes)
		
	for i in range(lengthSRAM):
		bytes = port.read(4)
		if len(bytes) != 4:
			panic(bytes)
		
		value = int.from_bytes(bytes, byteorder='big')
		content[i] = value
		#if i < 20:
		#	print(i, bytes.hex(), value)
	print('Done')
	return content

def writeSRAM(content, asm=None):
	print('Writing... ', end='', flush=True)
	port.write(commandWriteSRAM)
	for i in range(lengthSRAM + 1):
		if i < len(content):
			value = int(content[i])
		elif asm is not None and i >= asm[0] and i < asm[0] + len(asm[1]):
			value = asm[1][i - asm[0]]
		else:
			value = i #Passed the end of the provided content, just write the index
		
		bytes = value.to_bytes(4, byteorder='big')
		#if i < 20:
		#	print(i, bytes.hex(), value)
		port.write(bytes)
	time.sleep(0.1) #Wait a moment between commands
	print('Done')

def actionRunCPU():
	print('Running... ', end='', flush=True)
	port.write(commandRunCPU)
	time.sleep(1) #Give it a second to run (this assumes your CPU takes less than 1 second to calculate...)
	print('Done')

def readTimer(printResult=True):
	#Read number of cycles
	port.write(commandReadTimer)
	cyclesBytes = port.read(4)
	if len(cyclesBytes) != 4:
		panic(cyclesBytes)
	cycles = int.from_bytes(cyclesBytes, byteorder='big')
	
	port.write(commandReadMemoryOperationsCounter)
	memopsBytes = port.read(4)
	if len(memopsBytes) != 4:
		panic(memopsBytes)
	memops = int.from_bytes(memopsBytes, byteorder='big')
	
	if(printResult):
		print('CPU timer:', '0x' + cyclesBytes.hex(), '=', cycles, 'cycles =', str(cycles / 50000.0) + ' ms @ 50MHz')
		print('CPU memops:', '0x' + memopsBytes.hex(), '=', memops, 'cycles =', str(memops / 50000.0) + ' ms @ 50MHz')
		print('Memory was in use', str((float(memops) / float(cycles)) * 100.0), '% of the total time')

def loadProgram(path):
	#ONLY USED IF YOU ARE STORING YOUR PROGRAM ON THE SRAM
	#-----------------------------------------------------
	program = []
	with open(path, 'r') as inFile:
		program = inFile.readlines()
	#print(program)
	program = [int(x.strip(), 2) for x in program]
	#print(program)
	
	for i in range(len(program)):
		x = program[i]
		dec = x
		hex = x.to_bytes(4, byteorder='big').hex()
		b = bin(dec)
		ihex = (i + 8192).to_bytes(4, byteorder='big').hex()
		#print(ihex, hex, dec, b)
	return (8192, program)

def actionWrite(executable):
	aTrue = generateA(n)
	bTrue = np.dot(aTrue, aTrue.T)
	print('A true =\n', aTrue)
	print('B true =\n', bTrue)
	
	writeSRAM(aTrue.flatten('F'), asm=executable)
	return aTrue, bTrue

def actionRead():
	sramContent = readSRAM()
	aAfter = np.array(sramContent[0:n*n]).reshape((n, n)).T
	bAfter = np.array(sramContent[n*n:2*n*n]).reshape((n, n)).T
	print('A after =\n', aAfter)
	print('B after =\n', bAfter)
	print('\n')
	return aAfter, bAfter

def testConnection():
	port.write(commandCheckConnection)
	bytes = port.read(4)
	if len(bytes) != 4:
		panic(bytes)
	magicNumber = int.from_bytes(bytes, byteorder='big')
	if(magicNumber != 123456789):
		magicPanic(magicNumber)

def printDifferences(a, b):
	#Print differences between two lists
	print('Differences:')
	for i in range(len(a)):
		x = int(a[i])
		y = int(b[i])
		if x == y:
			continue
		print(i, x.to_bytes(4, byteorder='big').hex(), x, y.to_bytes(4, byteorder='big').hex(), y)

if __name__ == '__main__':
	#Parse arguments
	parser = argparse.ArgumentParser(description='Interface with SRAM module over Serial port')
	parser.add_argument('action', help='''One of [test, memtest, write, run, read, time].
		test:		full CPU test, write A matrix, run CPU, read B matrix and verify.
		memtest:	confirm that the memory reads and writes correctly.
		
		write:		write a random A matrix to the top of the SRAM.
		run:		unstall your cpu and allow it to run to completion.
		read:		read the content of the SRAM.
		time:		read the timer that measures how many cycles your cpu has taken.''')
	parser.add_argument('-n', help='Size of the matrix to generate (n * n), default=64', default=64, dest='n')
	parser.add_argument('-p', '--port', help='The serial port to connect to the board over, default=COM6', default='COM6', dest='port')
	parser.add_argument('-e', '--executable', help='''Only used if you are loading your program from the SRAM (instead of a ROM inside the FPGA), this is the path to text file containing 
		the binary words (each line should be 32 bits) to be written to SRAM after the two matrices''', default=None, dest='executable')
	args = parser.parse_args()

	action = args.action
	n = int(args.n)
	port = serial.Serial(args.port, 256000, timeout=1)

	#Do an initial read to check we have a connection to the board before anything else
	#This also confirms the SRAM module is functioning as expected
	testConnection()

	#Load executable if provided
	executable = None
	if args.executable != None:
		executable = loadProgram(args.executable)

	#Perform the requested action
	if action == 'run':
		actionRunCPU()
	elif action == 'time':
		readTimer()
	elif action == 'read':
		actionRead()
	elif action == 'write':
		actionWrite(executable)
	elif action == 'memtest':
		for i in range(10):
			print('Start test', i)
			#Generate random content
			before = np.random.randint(2**32, size=(lengthSRAM), dtype=np.uint32)
			#print('Before content =', before)
			writeSRAM(before)
			after = np.array(readSRAM())
			#print('After content =', after)
			if (before == after).all():
				print('Test passed, data is identical')
			else:
				print('Failed, data changed!!')
				printDifferences(before, after)

			print('')
	elif action == 'test':
		aTrue, bTrue = actionWrite(executable)
		actionRunCPU()
		aAfter, bAfter = actionRead()
		
		if (aTrue == aAfter).all():
			print('A matrix is same')
		else:
			print('A matrix has changed !!!')

		if (bTrue == bAfter).all():
			print('B matrix is correct')
		else:
			print('B matrix is incorrect')
			#printDifferences(bTrue.flatten('F'), bAfter.flatten('F'))

		readTimer()
		
		writeMatrixToFile(aTrue, 'aMatrix')
		writeMatrixToFile(bAfter, 'bMatrix')
	else:
		print('Unknown action')
