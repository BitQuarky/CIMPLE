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

bool compareWord(ref SList!long list, bool function(long, long) fun) {
  long x = list.front;
  list.removeFront();
  long y = list.front;
  list.removeFront();
  return fun(y, x);
}

int repl(bool cdebug) {
  auto stack = SList!long();
  int stacksize = 0;
  char[] buf = new char[](64);
  char[] str = new char[](128);
  string[][] wordtable;
  int strpos = 0;
  bool exitloop = false; 
  writeln("starting in interactive mode.\ntype 'exit' to exit the repl.\ntype '?' for general help.\ntype '?' followed by a\nword for documentation.");
  while (!exitloop) {
    write("#> ");
    readln(buf);
    string line = cast(string) buf[0..buf.indexOf("\n")];
    if (cdebug) writeln(line, " length is ", line.length);
    eval(line.split(' '), stack, stacksize, str, strpos, exitloop, wordtable, cdebug);
  }
  //printrocessAllocator.dispose(buf);
  //processAllocator.dispose(str);
  return 0;
}

void eval(string[] line, ref SList!long stack, ref int stacksize, ref char[] str, ref int strpos, ref bool exitloop, ref string[][] wordtable, bool cdebug) {
  bool stringmode = false, wordmode = false;
  int strstart = strpos;
  foreach (string s; line) {
    if (s[$-1] == ':') {
      if (s[0] == ':')  { //anonymous function
        //TODO:
        //implement anonymous words.
        //treat as string or callback word?
      } else {
        wordtable ~= [s.dup[0..$-1]];
        //wordtable ~= [[]];
        wordmode = true;
      }
    } else if(s[$-1] == ';' && wordmode) {
      wordtable[$-1] ~= s.dup[0..$-1];
      wordmode = false;
    } else if (wordmode) {
      if (cdebug) writeln("word");
      wordtable[$-1] ~= s.dup;
    } else if (s[0] == '"') {
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
    }  else if (s[$-1] == '"') {
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

    } else if (isNumeric(s)) {
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
      case("dupn"):
        if (stack.empty()) {
          writeln("stack underflow");
          break;
        }
        long n = stack.front();
        long[] vals = new long[](n);
        stack.removeFront();
        stacksize--;
        for (long i = 0; i < n; i++) {
          if (cdebug) writeln("i: ", i, "n: ", n);
          if (stack.empty()) {
            writeln("stack underflow");
            break;
          }
          vals[i] = stack.front();
          stack.removeFront();
        }
        for (int iter = 0; iter < 2; iter++) {
          for (long i = n-1; i >= 0; i--) {
            stack.insertFront(vals[i]);
          }
        }
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
      case("swapn"): //swap top with nth element down 
        if (stack.empty()) {
          writeln("stack underflow");
          break;
        }
        long n = stack.front();
        stack.removeFront();
        stacksize--;
        stack.insertAfter(std.range.take(stack[], n), stack.front());
        stack.removeFront();
        auto t = std.range.drop(stack[], n);
        long tmp = t.front();
        stack.linearRemove(std.range.take(t, 1));
        stack.insertFront(tmp);
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
      case("eval"):
        if (stack.empty()) {
          writeln("stack underflow");
          break;
        }
        char* tmp = cast(char*) stack.front();
        int len = 0;
        for (; tmp[len]!=0; len++) { }
        string strn = cast(string) tmp[0..len];
        stacksize--;
        stack.removeFront();
        eval(strn.split(' '), stack, stacksize, str, strpos, exitloop, wordtable, cdebug);
        break;
      case("times"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        long times = stack.front();
        stack.removeFront();
        long ptr = stack.front();
        stack.removeFront();
        stacksize -= 2;
        char* tmp = cast(char*) ptr;
        int len = 0;
        for (; tmp[len]!=0; len++) { }
        string strn = cast(string) tmp[0..len];
        for (; times > 0; times--) { 
          eval(strn.split(' '), stack, stacksize, str, strpos, exitloop, wordtable, cdebug);
        }
        break;
      case("height"):
        stack.insertFront(stacksize);
        stacksize++;
        break;
      case("clear"):
        while (!stack.empty()) {
          stack.removeFront();
        }
        stacksize = 0;
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
      case("<"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return x<y; }));
        break;
      case(">"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return x>y; }));
        break;
      case("=="):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return x==y; }));
        break;
      case("<="):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return x<=y; }));
        break;
      case(">="):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return x>=y; }));
        break;
      case("&&"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return cast(bool) x && cast(bool) y; }));
        break;
      case("||"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        stacksize--;
        stack.insertFront(compareWord(stack, (long x, long y) { return cast(bool) x || cast(bool) y; }));
        break;
      case("if"):
        if (stacksize < 2) {
          writeln("stack underflow");
          break;
        }
        long cond = stack.front();
        stack.removeFront();
        char* tmp = cast(char*) stack.front();
        int len = 0;
        for (; tmp[len]!=0; len++) { }
        string strn = cast(string) tmp[0..len];
        stacksize--;
        stack.removeFront();
        if (cond) eval(strn.split(' '), stack, stacksize, str, strpos, exitloop, wordtable, cdebug);
        break;
      default:
        int idx = 0;
        bool found = false;
        for (;idx<wordtable.length;idx++) {
          if (wordtable[idx][0] == s) {
            found = true;
            break;
          }
        }
        if (found) {
          eval(wordtable[idx][1..$], stack, stacksize, str, strpos, exitloop, wordtable, cdebug);
        } else {
          writeln("unknown word '", s, "'");
          if (cdebug) {
            foreach (arr; wordtable) {
              writeln(arr);
            }
          }
        }
    }
    if (exitloop) break;
  }
}
