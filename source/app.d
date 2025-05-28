import std.stdio;
import std.file; 
import std.string;
import std.experimental.allocator;
import std.container.slist;

import std.conv;

enum Backend {Asm, JIT}

int main(string[] args)
{
  bool cdebug = false, interactive = false, cfile = false;
  Backend back = Backend.JIT;
  char* l = cast(char*) processAllocator.makeArray!char(12);
  char* r = cast(char*) processAllocator.makeArray!char(12);
  scope char* file = cast(char*) processAllocator.makeArray!char(64);
  foreach (s; args[1..$]) {
    sscanf(cast(char*) s, "-%11[a-zA-Z-]", l);
    switch (l[0]) {
      case('d'):
        if (cdebug) writeln("starting in debug mode...");
        cdebug = true;
        break;
      case('I'):
        sscanf(cast(char*) s, "-I=%63s", file);
        if (cdebug) printf("opening %s...\n", file);
        cfile = true;
        break;
      case('i'):
        if (cdebug) writeln("starting in interactive mode...");
        interactive = true;
        break;
      case('b'):
        sscanf(cast(char*) s, "-b=%11s", r);
        switch(r[0]) {
          case('a'):
            if (cdebug) writeln("using asm backend...");
            back = Backend.Asm;
            break;
          case('j'):
            if (cdebug) writeln("using JIT backend...");
            back = Backend.JIT;
            break;
          default:
            printf("ERROR: unknown backend '%s' of available options: \n - asm \n - jit\n", r);
            return 1;
        }
        break;
      default:
        printf("ERROR: unknown argument '%s'\n", l);
        return 1;
    }
  }
  
  processAllocator.dispose(l);
  processAllocator.dispose(r);
  
  import repl : repl, eval;
  if (cfile) {
    string contents = to!string(read(fromStringz(file)));
    SList!long stack = SList!long();
    char[256] strb;
    char[] str = strb[];
    int[] strindx;
    string[][] wordtable;
    int stacksize = 0;
    int strpos = 0;
    bool exitloop = false;
    eval(contents.split('\n').join(' ').split(' '), stack, stacksize, str, strindx, strpos, exitloop, wordtable, cdebug);
    if (interactive) {
      char[] buf = new char[](64);
      while (!exitloop) {
        write("#> ");
        readln(buf);
        string line = cast(string) buf[0..buf.indexOf("\n")];
        if (cdebug) writeln(line, " length is ", line.length);
        eval(line.split(' '), stack, stacksize, str, strindx, strpos, exitloop, wordtable, cdebug);
      }
    }
  }
  else if (interactive) repl(cdebug);

  processAllocator.dispose(file);
  return 0;
}
