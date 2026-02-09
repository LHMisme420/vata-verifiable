import hashlib,sys,json

def h(x): 
 return hashlib.sha256(x.encode()).hexdigest()

leaves=[l.strip() for l in open(sys.argv[1])]

tree=[l[2:] for l in leaves]

while len(tree)>1:
 nxt=[]
 for i in range(0,len(tree),2):
  a=tree[i]
  b=tree[i] if i+1==len(tree) else tree[i+1]
  nxt.append(h(a+b))
 tree=nxt

root="0x"+tree[0]
open("merkle_root.txt","w").write(root)
print(root)
