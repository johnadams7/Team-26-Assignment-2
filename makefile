


axa.out : axa.v
	sed 's/readmemh0(/readmemh(\"vmem0.txt\",/g' axa.v > axaTemp.v
	sed -i 's/readmemh1(/readmemh(\"vmem1.txt\",/g' axaTemp.v
	sed -i 's/readmemh2(/readmemh(\"vmem2.txt\",/g' axaTemp.v
	sed -i 's/dumpfile/dumpfile(\"test.out\")/g'    axaTemp.v
	iverilog -o axa.out axa.v
	rm -f axaTemp.v
clean:
	rm -f axa.out
