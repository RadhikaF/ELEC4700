import numpy as np

def generateA(n):
	#Generate random test matrix
	maxNum32 = 2 ** 32 - 1
	maxMatrixCell = 10#int(math.sqrt(maxNum32 / n))
	#print('Maximum cell value: ' + str(maxMatrixCell))
	return np.random.randint(0, 8, size=(n,n), dtype=np.uint32)

no = 64
block_size = 4
loop_blocks = 16
amatrix = generateA(no)
amatrix = amatrix.flatten('F')
bmatrix = np.zeros((no, no), dtype=np.uint32)
bmatrix = bmatrix.flatten('F')
for a in range(0,no):
    for b in range(0,no):
        for c in range(0,no):
            bmatrix[a+no*b] = bmatrix[a+no*b] + amatrix[a+no*c] * amatrix[b+no*c]

print (amatrix.reshape((no, no)))
print (bmatrix.reshape((no, no)))



bmatrix2 = np.zeros((no, no), dtype=np.uint32).flatten('F')

memory = np.concatenate((amatrix, bmatrix2))
print('memory')
print(memory)


r0 = 0
r1 = 0
r2 = 0
r3 = 0
r4 = 4096
r5 = 0
r6 = 0
r7 = 4
r8 = 16
r9 = 0
r10 = 0
r11 = 0
r12 = 0
r13 = 0
r14 = 0
r15 = 0
r16 = 8

stop = False
i = 0

while not stop:
    while not stop:
        while not stop:
            while not stop:
                while not stop:
                    r6 = memory[r4]
                    while not stop:
                        r0 = memory[r2]
                        r9 += 1
                        r1 = memory[r3]
                        r5 = r0 * r1
                        r6 = r5 + r6
                        r2 += 64
                        r3 += 64                    
                        if r9 == r7:
                            break
                    
                    memory[r4] = r6
                    r10 += 1
                    r9 = r15
                    r4 += 1
                    r2 += -255
                    r3 += -256
                       
                    if r4 < 4096:
                        print ('r0 = ', r0)
                        print ('r1 = ', r1)
                        print ('r2 = ', r2)
                        print ('r3 = ', r3)
                        print ('r4 = ', r4)
                        print ('r5 = ', r5)
                        print ('r6 = ', r6)
                        print ('r7 = ', r7)
                        print ('r8 = ', r8)
                        print ('r9 = ', r9)
                        print ('r10 = ', r10)
                        print ('r11 = ', r11)
                        print ('r12 = ', r12)
                        print ('r13 = ', r13)
                        print ('r14 = ', r14)
                        print ('r15 = ', r15)
                        stop = True
                    
                    if r10 == r7:
                        break
                        
                r11 += 1
                r10 = r15
                r4 += 60
                r2 += -4
                r3 += 1
            
                if r11 == r7:
                    break
            
            r12 += 1
            r11 = r15
            r4 += -256
            r2 += 256
            r3 += 252
        
            if r12 == r8:
                break
        
        r13 += 1
        r12 = r15
        r4 += 256
        r2 += -4096
        r3 += -4092
        
        if r13 == r8:
            break
    #stop = True
    r14 += 1
    r13 = r15
    r4 += -4092
    r2 += 4
    r3 += -64
    
    i += 1
    #if i == 2:
    #   stop = True

    if r14 == r16:
        break

r0 = 0
r1 = 32
r2 = 0
r3 = 0
r4 = 4128
r5 = 0
r6 = 0
r7 = 4
r8 = 16
r9 = 0
r10 = 0
r11 = 0
r12 = 0
r13 = 0
r14 = 0
r15 = 0
r16 = 8

while not stop:
    while not stop:
        while not stop:
            while not stop:
                while not stop:
                    r6 = memory[r4]
                    '''try:
                        
                    except:
                        if r4 > 8191:
                                print ('r0 = ', r0)
                                print ('r1 = ', r1)
                                print ('r2 = ', r2)
                                print ('r3 = ', r3)
                                print ('r4 = ', r4)
                                print ('r5 = ', r5)
                                print ('r6 = ', r6)
                                print ('r7 = ', r7)
                                print ('r8 = ', r8)
                                print ('r9 = ', r9)
                                print ('r10 = ', r10)
                                print ('r11 = ', r11)
                                print ('r12 = ', r12)
                                print ('r13 = ', r13)
                                print ('r14 = ', r14)
                                print ('r15 = ', r15)
                                stop = True  ''' 
                    while not stop:
                        r0 = memory[r2]
                        r9 += 1
                        r1 = memory[r3]
                        r5 = r0 * r1
                        r6 = r5 + r6
                        r2 += 64
                        r3 += 64                    
                        if r9 == r7:
                            break
                   
                    memory[r4] = r6 
                    r10 += 1
                    r9 = r15
                    r4 += 1
                    r2 += -255
                    r3 += -256
                        
                    if r10 == r7:
                        break
                        
                r11 += 1
                r10 = r15
                r4 += 60
                r2 += -4
                r3 += 1
            
                if r11 == r7:
                    break
            
            r12 += 1
            r11 = r15
            r4 += -256
            r2 += 256
            r3 += 252
        
            if r12 == r8:
                break
        
        r13 += 1
        r12 = r15
        r4 += 256
        r2 += -4096
        r3 += -4092
        
        if r13 == r8:
            break
    #stop = True
    r14 += 1
    r13 = r15
    r4 += -4092
    r2 += 4
    r3 += -64
    
    i += 1
    #if i == 2:
    #   stop = True

    if r14 == r16:
        break



memory = memory.reshape((2*no, no))
bafter = memory[no:2*no][:].T #[:][no:2*no]
print (bafter)