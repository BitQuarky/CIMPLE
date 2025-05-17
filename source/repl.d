module repl;

import std.container.slist;
import std.functional;
long binaryWord(ref SList!long list, long function(long, long) fun) {
  long x = list.front;
  list.removeFront();
  long y = list.front;
  list.removeFront();
  return fun(y, x);
}

int repl(bool cdebug) {
  import std.stdio;
  import std.experimental.allocator;
  import std.algorithm.iteration;
  import std.container.slist;
  import std.string;
  import std.format.read;
  import std.format.spec;
  import std.range;
  import std.range.primitives;
  import std.conv;

  auto stack = SList!long();
  int stacksize = 0;
  char[] buf = processAllocator.makeArray!char(64);
  bool exitloop = false;
  writeln("starting in interactive mode.\ntype 'exit' to exit the repl.\ntype '?' for general help.\ntype '?' followed by a\nword for documentation.");
  while (!exitloop) {
    write("#> ");
    readln(buf);
    string line = cast(string) buf[0..buf.indexOf("\n")];
    if (cdebug) writeln(line, " length is ", line.length);
    foreach (string s; line.splitter(' ')) {
      if (isNumeric(s)) {
        stack.insertFront(to!long(s));
        if (cdebug) writeln("number");
        stacksize++;
      } else switch(s) {
        case("exit"):
          exitloop = true;
          break;
        case("show"):
          if (stack.empty()) {
            writeln("stack underflow");
            break;
          }
          writeln(stack.front());
          stack.removeFront();
          stacksize--;
          break;
        case("+"):
          if (stacksize < 2) {
            writeln("stack underflow");
            break;
          }
          stack.insertFront(binaryWord(stack, (long x, long y) { return x+y; }));
          break;
        case("-"):
          if (stacksize < 2) {
            writeln("stack underflow");
            break;
          }
          stack.insertFront(binaryWord(stack, (long x, long y) { return x-y; }));
          break;
        case("*"):
          if (stacksize < 2) {
            writeln("stack underflow");
            break;
          } 
          stack.insertFront(binaryWord(stack, (long x, long y) { return x*y; }));
          break;
        case("/"):
          if (stacksize < 2) {
            writeln("stack underflow");
            break;
          } 
          stack.insertFront(binaryWord(stack, (long x, long y) { return x/y; }));
          break;
        case("%"):
          if (stacksize < 2) {
            writeln("stack underflow");
            break;
          } 
          stack.insertFront(binaryWord(stack, (long x, long y) { return x%y; }));
          break;
        default:
          writeln("unknown word '", s, "'");
      }
      if (exitloop) break;
    }
  }
  return 0;
}
