# chat-server

a prototype chat server built on libevent

```
$ make
gcc -g -Wextra -Wall -pedantic -std=c99 -levent server.c -o server
Compilation finished at Sun May  7 15:44:56
$ ./server
```

And in another terminal/on another machine on the same network:
```
$ nc localhost 8080
```