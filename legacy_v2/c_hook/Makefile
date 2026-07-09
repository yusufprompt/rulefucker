CC = gcc
CFLAGS = -Wall -fPIC -shared
LDFLAGS = -ldl
TARGET = rulefucker.so
TARGET_ADVANCED = rulefucker_kernel_advanced.ko
CUSTOMIZER = customizer.so

all: $(TARGET) $(CUSTOMIZER) $(TARGET_ADVANCED)

# LD_PRELOAD hook (userspace - legacy)
$(TARGET): rulefucker.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# LD_PRELOAD hook alternatif (customizer)
$(CUSTOMIZER): customizer.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS) || echo "customizer.c mevcut değil, atlanıyor."

# Kernel module (LKM - advanced)
$(TARGET_ADVANCED): rulefucker_kernel_advanced.c
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	rm -f $(TARGET) $(CUSTOMIZER) *.o *.ko *.mod* Module.symvers modules.order
