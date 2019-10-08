


axa.out : axa.v
	sed -i 's/readmemh0(/readmemh(\"vmem0.txt\",/g' axa.v
	sed -i 's/readmemh1(/readmemh(\"vmem1.txt\",/g' axa.v
	sed -i 's/readmemh2(/readmemh(\"vmem2.txt\",/g' axa.v
	sed -i 's/dumpfile/dumpfile(\"test.out\")/g'    axa.v
	iverilog -o axa.out axa.v
	sed -i 's/readmemh(\"vmem0.txt\",/readmemh0(/g' axa.v
	sed -i 's/readmemh(\"vmem1.txt\",/readmemh1(/g' axa.v
	sed -i 's/readmemh(\"vmem2.txt\",/readmemh2(/g' axa.v
	sed -i 's/dumpfile(\"test.out\")/dumpfile/g'    axa.v
clean:
	rm -f axa.out
