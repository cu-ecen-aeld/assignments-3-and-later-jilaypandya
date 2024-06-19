CC ?= gcc
CROSS_COMPILE ?=

ifeq ($(CROSS_COMPILE),)
	CC = gcc
else
	CC = aarch64-none-linux-gnu-gcc
endif

writer: writer.o
	$(CC) -o writer writer.o

writer.o: writer.c
	$(CC) -c -o writer.o writer.c $(CFLAGS)

clean:
	rm -f writer writer.o