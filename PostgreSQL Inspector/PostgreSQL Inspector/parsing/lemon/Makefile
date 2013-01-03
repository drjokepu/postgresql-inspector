LEMON_OPTIONS=-s
LEMON_OUTPUT=lemon.c lemon.h lemon.out
OUTPUT=$(LEMON_OUTPUT)

$(LEMON_OUTPUT):
	lemon $(LEMON_OPTIONS) sql.y

all: $(OUTPUT)
clean:
	rm -rf $(OUTPUT)
