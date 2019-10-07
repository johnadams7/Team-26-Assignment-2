


axa.out : axa.v
	iverilog -o axa.out axa.v

clean:
	rm -f axa.out
