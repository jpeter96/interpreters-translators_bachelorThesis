.PHONY: build clean test install run help

# Default target
all: build

# Build the project
build:
	dune build

# Clean build artifacts
clean:
	dune clean

# Run tests
test:
	dune runtest

# Install dependencies (requires opam)
install:
	opam install . --deps-only --with-test

# Run the main executable
run:
	dune exec interpreters_translators

# Show help
help:
	@echo "Available targets:"
	@echo "  make build   - Build the project"
	@echo "  make clean   - Clean build artifacts"
	@echo "  make test    - Run tests"
	@echo "  make install - Install dependencies via opam"
	@echo "  make run     - Run the main executable"
	@echo ""
	@echo "Usage examples:"
	@echo "  dune exec interpreters_translators -- loop examples/loop/factorial.loop"
	@echo "  dune exec interpreters_translators -- while examples/while/fibonacci.while"
	@echo "  dune exec interpreters_translators -- translate loop-to-while examples/loop/factorial.loop"

