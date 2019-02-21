#include "driver.hh"
#include "typecheck.hh"
#include "codegen_llvm.hh"

int main(int argc, char *argv[]) {
    argc -= 1;
    if (!(argc >= 1 && argc <= 3)) {
        std::cerr << "usage: " << argv[0] << " input.lang [output.o [output.ir]]" << std::endl;
        exit(EXIT_FAILURE);
    }

    driver driver;
    driver.parse(std::string(argv[1]));

    typecheck_context typecheck_context;
    typecheck(typecheck_context, driver.program_ast);

    codegen_context_llvm codegen_context_llvm;
    codegen_context_llvm.symbols = driver.symbols;
    if (argc == 2) {
        codegen_llvm(codegen_context_llvm, driver.program_ast, std::string(argv[1]), std::string(argv[2]));
    } else if (argc == 3) {
        codegen_llvm(codegen_context_llvm, driver.program_ast, std::string(argv[1]), std::string(argv[2]), std::string(argv[3]));
    }

    exit(EXIT_SUCCESS);
}
