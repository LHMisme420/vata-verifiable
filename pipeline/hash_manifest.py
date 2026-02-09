import sys,json,hashlib
m=json.load(open(sys.argv[1]))
h=hashlib.sha256(json.dumps(m,sort_keys=True).encode()).hexdigest()
open("manifest_hash.txt","w").write("0x"+h)
print("0x"+h)
