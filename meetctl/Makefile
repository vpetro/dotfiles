BINARY := ../bin/meetctl
SRC    := $(wildcard *.go)

.PHONY: build install clean

build: $(BINARY)

$(BINARY): $(SRC) go.sum
	go build -trimpath -ldflags='-s -w' -o $@ .

go.sum: go.mod
	go mod download

install: build
	@ln -sf $$(realpath $(BINARY)) $$HOME/bin/meetctl
	@echo "  $$HOME/bin/meetctl -> $$(realpath $(BINARY))"

clean:
	rm -f $(BINARY)
