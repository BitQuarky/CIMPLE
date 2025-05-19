module repl;

import std.container.slist;
import std.functional;
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
long binaryWord(ref SList!long list, long function(long, long) fun) {
  long x = list.front;
  list.removeFront();
  long y = list.front;
  list.removeFront();
  return fun(y, x);
}

int repl(bool cdebug) {
  auto stack = SList!long();
  int stacksize = 0;
  char[] buf = processAllocator.makeArray!char(64);
  char[] str = processAllocator.makeArray!char(128);
  int strpos = 0;
  bool exitloop = false; 
  writeln("starting in interactive mode.\ntype 'exit' to exit the repl.\ntype '?' for general help.\ntype '?' followed by a\nword for documentation.");
  while (!exitloop) {
    write("#> ");
    readln(buf);
    string line = cast(string) buf[0..buf.indexOf("\n")];
    if (cdebug) writeln(line, " length is ", line.length);
    eval(line.split(' '), stack, stacksize, str, strpos, exitloop, cdebug);
  }
  processAllocator.dispose(buf);
  processAllocator.dispose(str);
  return 0;
}

void eval(string[] line, ref SList!long stack, ref int stacksize, ref char[] str, ref int strpos, ref bool exitloop, bool cdebug) {
  bool stringmode = false;
  int strstart = strpos;
  foreach (string s; line) {
    if (s[0] == '"') {
      stringmode = true;
      stacksize++;
      strstart = strpos;
      int delta = strpos;
      for (; strpos-delta < s.length-1; strpos++) {
        str[strpos] = s[strpos-delta+1];
      }
      if (s[$-1] == '"') {
        str[strpos-1] = 0;
        stringmode = false;
        stack.insertFront(cast(long) str[strstart..$].ptr);
      }
    } else if (isNumeric(s)) {
      stack.insertFront(to!long(s));
      if (cdebug) writeln("number");
      stacksize++;
    } else if (s[$-1] == '"') {
      str[strpos++] = ' ';
      int delta = strpos;
      writeln("here");
      for (; strpos-delta < s.length-1; strpos++) {
        str[strpos] = s[strpos-delta];
      }
      str[strpos] = 0;
      strpos++;
      stack.insertFront(cast(long) str[strstart..$].ptr);
      stringmode = false;

    } else if (stringmode) {
      writeln("here3");
      str[strpos++] = ' ';
      int delta = strpos;
      for (; strpos-delta < s.length; strpos++) {
        str[strpos] = s[strpos-delta];
      }

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
      case("print"):
        if (stack.empty()) {
          writeln("stack underflow");
          break;
        }
        char* tmp = cast(char*) stack.front();
        int len = 0;
        for (; tmp[len]!=0; len++) { }
        char[] strn = tmp[0..len];
        writeln(strn);
        stacksize--;
        stack.removeFront();
        break;
      case("dup"):
        if (stack.empty()) {
          writeln("stack underflow");
          break;
        }
        stack.insertFront(stack.front());
        stacksize++;
        break;
      case("swap"):
          if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        long x = stack.front();
        stack.removeFront();
        long y = stack.front();
        stack.insertFront(x);
        stack.insertFront(y);
        break;
      case("rot"):
        if (stacksize < 3) {
          writeln("stack underflow");
          break;
        }
        long f = stack.front();
        stack.removeFront();
        stack.insertAfter(std.range.take(stack[], 2), f);
        break;
      case("drop"):
        if (stacksize < 1) {
          writeln("stack underflow");
          break;
        }
        stack.removeFront();
        stacksize--;
        break;
      case("+"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(binaryWord(stack, (long x, long y) { return x+y; }));
        break;
      case("-"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(binaryWord(stack, (long x, long y) { return x-y; }));
        break;
      case("*"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        } 
        stacksize--;
        stack.insertFront(binaryWord(stack, (long x, long y) { return x*y; }));
        break;
      case("/"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        } 
        stacksize--;
        stack.insertFront(binaryWord(stack, (long x, long y) { return x/y; }));
        break;
      case("%"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        } 
        stacksize--;
        stack.insertFront(binaryWord(stack, (long x, long y) { return x%y; }));
        break;
      default:
        writeln("unknown word '", s, "'");
    }
    if (exitloop) break;
  }
}
