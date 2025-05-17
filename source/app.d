import std.stdio;
import std.file; 
import std.string;
import std.experimental.allocator;

enum Backend {Asm, JIT}

int main(string[] args)
{
  bool cdebug = false, interactive = false, cfile = false;
  Backend back = Backend.JIT;
  char* l = cast(char*) processAllocator.makeArray!char(12);
  char* r = cast(char*) processAllocator.makeArray!char(12);
  char* file = cast(char*) processAllocator.makeArray!char(64);
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
  
  import repl : repl;
  if (interactive) repl(cdebug);

  processAllocator.dispose(file);
  return 0;
}
