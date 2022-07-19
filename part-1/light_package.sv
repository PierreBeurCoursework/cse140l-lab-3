// packages are very useful for global variable declarations
package light_package;
// width declaration is optional w/ typedef enum
// used here to avoid 32-bit defaults w/ top 30 bits tied to 0
// first in list automatically maps to 2'b00
// next = 2'b01, etc. 
// can also specify, e.g. to skip over a particular value
  typedef enum logic[1:0] {red, yellow, green} colors;

endpackage