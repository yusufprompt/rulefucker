CC = gcc
CFLAGS = -Wall -fPIC -shared
LDFLAGS = -ldl
TARGET = rulefucker.so

all: $(TARGET)

$(TARGET): rulefucker.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)
