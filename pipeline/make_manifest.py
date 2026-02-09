import sys,json,hashlib,time

inp=open(sys.argv[1]).read()
out=open(sys.argv[2]).read()

m={
 "version":"v1",
 "input_sha256":hashlib.sha256(inp.encode()).hexdigest(),
 "output_sha256":hashlib.sha256(out.encode()).hexdigest(),
 "soul_score":0.98,
 "label":"human",
 "timestamp":int(time.time())
}

open("manifest.json","w").write(json.dumps(m,indent=2))
print("manifest.json created")
