/*
 * mechrevo-fan - Read fan duty cycle from MECHREVO/Tongfang EC
 *
 * EC register: FFAN at offset 0x460, 4-bit field (0-15)
 * Must run as root (needs iopl(3) for EC I/O port access)
 */

#include <stdio.h>
#include <sys/io.h>
#include <unistd.h>

#define EC_DATA   0x62
#define EC_CMD    0x66
#define FFAN_OFF  0x460

static unsigned char ec_read(unsigned short addr)
{
    int n;
    for (n = 0; n < 100 && (inb(EC_CMD) & 0x80); n++) usleep(1000);
    outb(0x80, EC_CMD);
    usleep(1000);
    for (n = 0; n < 100 && (inb(EC_CMD) & 0x80); n++) usleep(1000);
    outb(addr, EC_DATA);
    usleep(1000);
    for (n = 0; n < 100 && (inb(EC_CMD) & 0x80); n++) usleep(1000);
    return inb(EC_DATA);
}

int main(void)
{
    if (iopl(3) != 0) { fprintf(stderr, "iopl failed\n"); return 1; }
    printf("%d\n", ec_read(FFAN_OFF) & 0x0F);
    return 0;
}
