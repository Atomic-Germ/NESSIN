## Top-level convenience Makefile
# Only implement a safe `clean` target that removes generated temporary files

.PHONY: clean test
clean:
	@echo "Cleaning repo-local temporary files and example outputs..."
	-rm -rf *.chr *.nes artifacts/ logs/ tmp/ **/tmp/* **/artifacts/* **/logs/* nes-ide/examples/*/hello.nes nes-ide/examples/*/hello.chr nes-ide/examples/*/hello.tmp.nes
	@echo "Done. (Note: this Makefile only removes repo-local generated files; it does not modify source.)"
test:
	@echo "Building and testing example ROM..."
	./test_build.sh
	@echo "Test build complete. Check test.nes and test.chr files."