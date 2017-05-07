#include <sys/socket.h>
#include <sys/queue.h>
#include <sys/time.h>

#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <arpa/inet.h>
#include <netinet/in.h>

#include <event.h>

#define PORT (8080)
#define IPADDR ("127.0.0.1")
#define NCLIENTS (5)

TAILQ_HEAD(, client) clients = TAILQ_HEAD_INITIALIZER(clients);

struct client {
  char               name[80];
  int                fd;
  struct sockaddr_in addr;
  struct bufferevent *bev;

  TAILQ_ENTRY(client) entry;
};

void
broadcast_message(struct client *cli, char *buf, ssize_t n)
{
  struct client *client;
  char message[128];

  snprintf(message, sizeof(message), "%s: %.*s", cli->name, (int)n, buf);

  TAILQ_FOREACH(client, &clients, entry)
    if (client != cli)
      bufferevent_write(client->bev, message, strlen(message));
}

void
client_read(struct bufferevent *bev, void *arg)
{
  struct client *cli = arg;
  char buf[8192];
  ssize_t n;

  while (1) {
    n = bufferevent_read(bev, buf, sizeof(buf));
    if (n <= 0)
      break;

    broadcast_message(cli, buf, n);
  }
}

void
client_error(struct bufferevent *bev, short what, void *arg)
{
  struct client *cli = (struct client *)arg;

  if (what & EVBUFFER_EOF) {
    printf("Client disconnected: %s\n", cli->name);
  } else {
    printf("Client socket error: %s\n", cli->name);
  }

  TAILQ_REMOVE(&clients, cli, entry);

  bufferevent_free(cli->bev);
  close(cli->fd);
  free(cli);
}

void
server_accept(int fd, short event, void *arg)
{
  struct client *cli;
  socklen_t len = sizeof(struct sockaddr_in);

  if ((cli = malloc(sizeof(struct client))) == NULL)
    return;

  if ((cli->fd = accept4(fd, (struct sockaddr *)&cli->addr, &len, SOCK_NONBLOCK)) == -1)
    goto error;

  if ((cli->bev = bufferevent_new(cli->fd, client_read, NULL, client_error, cli)) == NULL)
    goto error;

  if (bufferevent_enable(cli->bev, EV_READ|EV_WRITE) == -1)
    goto error;

  TAILQ_INSERT_TAIL(&clients, cli, entry);

  snprintf(cli->name, sizeof(cli->name), "%s:%d",
	   inet_ntoa(cli->addr.sin_addr),
	   cli->addr.sin_port);

  return;

 error:
  if (cli->fd)
    close(cli->fd);
  free(cli);
}

int
main()
{
  int fd;

  struct sockaddr_in saddr;
  socklen_t len = sizeof(saddr);

  saddr.sin_family = AF_INET;
  saddr.sin_port = htons(PORT);
  inet_pton(AF_INET, IPADDR, &saddr.sin_addr);

  // server event
  struct event sev;

  if ((fd = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0)) == -1)
    perror("socket");

  if (bind(fd, (struct sockaddr *)&saddr, len) == -1)
    perror("bind");

  event_init();

  if (listen(fd, NCLIENTS) == -1)
    perror("listen");

  event_set(&sev, fd, EV_READ|EV_PERSIST, server_accept, NULL);
  event_add(&sev, NULL);

  event_dispatch();

  return 0;
}
