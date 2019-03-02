LEX = flex
LFLAGS =
YACC = bison -y
YFLAGS = -d -Werror=all
CXX = g++
CPPFLAGS = -Isrc -Iout
CXXFLAGS = -g -std=c++17 -MMD -MP \
	-Werror -Wall -Wextra -Wpedantic \
	-Wno-unused-function -Wno-unused-parameter
LDFLAGS =
LDLIBS = -lLLVM-7

ifdef debug
DEBUG = gdb -nx -q -ex run -ex quit --args
endif

ifdef quiet
Q := @
endif

all: out/compiler

objects := out/lexer.o out/parser.o out/main.o out/codegen_llvm.o out/typecheck.o
depends := $(objects:.o=.d)

out/lexer.cc out/lexer.hh: src/lexer.ll | dirs
	$(Q) $(LEX) $(LFLAGS) --header-file=out/lexer.hh -o out/lexer.cc src/lexer.ll
out/parser.cc out/parser.hh: src/parser.yy | dirs
	$(Q) $(YACC) $(YFLAGS) -o out/parser.cc src/parser.yy
out/%.o: out/%.cc out/lexer.hh out/parser.hh | dirs
	$(Q) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
out/%.o: src/%.cc out/lexer.hh out/parser.hh | dirs
	$(Q) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
out/compiler: $(objects) | dirs
	$(Q) $(CXX) $(LDFLAGS) -o $@ $^ $(LDLIBS)

clean:
	$(Q) rm -rf out

type-1-tests := parse codegen
type-2-tests := link fib gcd
test: $(type-1-tests) $(type-2-tests)

$(type-1-tests): %: out/compiler
	$(Q) $(DEBUG) out/compiler tests/$@.lang out/$@.ir
	$(Q) llc -filetype=obj out/$@.ir -o out/$@.o

$(type-2-tests): %: out/compiler
	$(Q) $(DEBUG) out/compiler tests/$@.lang out/$@.ir
	$(Q) llc -filetype=obj out/$@.ir -o out/$@.o
	$(Q) g++ tests/$@.cc out/$@.o -o out/$@
	$(Q) $(DEBUG) out/$@

.PHONY: all dirs clean test $(type-1-tests) $(type-2-tests)
dirs:
	@mkdir -p out

-include $(depends)
