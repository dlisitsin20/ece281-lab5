# Lab 5: Basic CPU

VHDL for ECE 281 [Lab 5](https://usafa-ece.github.io/ece281-book/lab/lab5.html)

Targeted toward Digilent Basys3 with Viavdo 2024.2 on Windows 11.

---

## Build the project

You can simply open the `.xpr` and Vivado will do the rest!

## GitHub Actions Testbench

Will run **ALU_tb**

## Documentation Statement:

C3C Dexter James helped me with the logic for the Overflow Flag in the ALU because I couldn't figure out why a xnor b xnor c wasn't working.
I used ChatGPT to help me troubleshoot my issue with the weird bit deletion from the register. Chat GPT told me that it was a timing issue 
tied to the fact I was using a cycle bit as a clock. It wasn't that. I used Google to validate my calculations about overflow and carry.
I borrowed components sevenseg_decoder from Lab 2 and Ripple Carry Adder for the ALU from ICE 3. I used Stack Overflow and ChatGPT to 
research why my design wouldn't synthesyze with a [Place 30-99] error.