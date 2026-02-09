import sys,hashlib,json

def h(x): 
 return hashlib.sha256(x.encode()).hexdigest()

leaf=sys.argv[1][2:]
proof=json.load(open(sys.argv[2]))
root=sys.argv[3][2:]

cur=leaf
for p in proof:
 cur=h(cur+p)

if cur==root:
 print("VALID")
else:
 print("INVALID")
