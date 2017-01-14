Code update fixed addresses
===========================

Below are the opcodes which if copied to ram should have their params (nn) added to the dest-source memory location.

| Instr   | Params   | Opcode |
| ------- | -------- | ------ |
| JP      | nn       | C3     |
| JP      | NZ, nn   | C2     |
| JP      | Z, nn    | CA     |
| JP      | NC, nn   | D2     |
| JP      | C, nn    | DA     |
| CALL    | nn       | CD     |
| CALL    | NZ, nn   | C4     |
| CALL    | Z, nn    | CC     |
| CALL    | NC, nn   | D4     |
| CALL    | C, nn    | DC     |

All the instructions above are 3 bytes long, one for the opcode and two for the address in need of updating. The addresses are stored with the least significant byte first.

Opcode length LUT
=================

```
 |0 1 2 3 4 5 6 7 8 9 A B C D E F
-+-------------------------------
0|1,3,1,1,1,1,2,1,3,1,1,1,1,1,2,1
1|2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1
2|2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1
3|2,3,1,1,1,1,2,1,2,1,1,1,1,1,2,1
4|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
5|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
6|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
7|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
8|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
9|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
A|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
B|1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
C|1,1,3,3,3,1,2,1,1,1,3,2,3,3,2,1
D|1,1,3,-,3,1,2,1,1,1,3,-,3,-,2,1
E|2,1,2,-,-,1,2,1,2,1,3,-,-,-,2,1
F|2,1,2,1,-,1,2,1,2,1,3,1,-,-,2,1
```

*CB Prefixed all = 2 (0xCB and 0x??)*


Lookup Table Encoding
---------------------

Encoding in full = 255 byte lookup table, with a simple and fast lookup routine

Alternatively, only need 2 bits per entry as none >3:
```
  00 = invalid opcode (If encountered in a lookup, likely a bug in the LUT routine)
  01 = 1 byte
  10 = 2 byte
  11 = 3 byte
```

This results in a 64 byte table but a more complex lookup routine (slower to run)
