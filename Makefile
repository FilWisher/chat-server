CC=gcc
CFLAGS=-g -Wextra -Wall -pedantic -std=c99

server: server.c
	$(CC) $(CFLAGS) -levent server.c -o server

test: server
	perl test/server.pl

clean:
	@ rm -rf server

.PHONY: clean test
