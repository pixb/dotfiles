/*
 * mechrevo-fan - Read/set fan duty on MECHREVO (Uniwill/Quanta) EC
 *
 * Fan duty comes from the Uniwill interface of the mechrevo-drivers'
 * /dev/tuxedo_io: R_UW_FANSPEED (fan1) and R_UW_FANSPEED2 (fan2), raw duty
 * 0-200 (200 = 100%, NB02_FAN_SPEED_MAX 0xc8). EC RAM offset 0x460 (FFAN)
 * always reads 0 on this platform, so the raw EC read used by earlier
 * versions is not usable here.
 *
 * mechrevo-fan             print "<fan1> <fan2>" raw duty, e.g. "180 180" (90%)
 * mechrevo-fan -v          same, plus fan temp and limits on stderr
 * mechrevo-fan w <d1> [d2] set fan duty manually (0-200, d2 defaults to d1)
 * mechrevo-fan a           hand fan control back to the EC (auto)
 *
 * Must run as root (needs write access to /dev/tuxedo_io)
 */

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define IOCTL_MAGIC       0xEC
#define MAGIC_READ_UW     IOCTL_MAGIC + 3
#define MAGIC_WRITE_UW    IOCTL_MAGIC + 4

#define R_MOD_VERSION     _IOR(IOCTL_MAGIC, 0x00, char *)
#define R_HWCHECK_UW      _IOR(IOCTL_MAGIC, 0x06, int32_t *)
#define R_UW_FANSPEED     _IOR(MAGIC_READ_UW, 0x10, int32_t *)
#define R_UW_FANSPEED2    _IOR(MAGIC_READ_UW, 0x11, int32_t *)
#define R_UW_FAN_TEMP     _IOR(MAGIC_READ_UW, 0x12, int32_t *)
#define R_UW_FANS_OFF_AV  _IOR(MAGIC_READ_UW, 0x16, int32_t *)
#define R_UW_FANS_MIN_SPD _IOR(MAGIC_READ_UW, 0x17, int32_t *)

#define W_UW_FANSPEED     _IOW(MAGIC_WRITE_UW, 0x10, int32_t *)
#define W_UW_FANSPEED2    _IOW(MAGIC_WRITE_UW, 0x11, int32_t *)
#define W_UW_FANAUTO      _IO(MAGIC_WRITE_UW, 0x14)

#define DUTY_MAX 200

static int uw_call(int fd, unsigned long req, const char *name, int32_t *arg)
{
	if (ioctl(fd, req, arg) != 0) {
		fprintf(stderr, "%s failed\n", name);
		return -1;
	}
	return 0;
}

static int read_fans(int fd, int32_t *fan1, int32_t *fan2)
{
	if (uw_call(fd, R_UW_FANSPEED, "R_UW_FANSPEED", fan1) != 0) return -1;
	if (uw_call(fd, R_UW_FANSPEED2, "R_UW_FANSPEED2", fan2) != 0) *fan2 = *fan1;
	return 0;
}

static int set_fans(int fd, int32_t d1, int32_t d2)
{
	if (d1 < 0 || d1 > DUTY_MAX || d2 < 0 || d2 > DUTY_MAX) {
		fprintf(stderr, "duty out of range 0-%d\n", DUTY_MAX);
		return -1;
	}
	if (uw_call(fd, W_UW_FANSPEED, "W_UW_FANSPEED", &d1) != 0) return -1;
	if (uw_call(fd, W_UW_FANSPEED2, "W_UW_FANSPEED2", &d2) != 0) return -1;
	return 0;
}

int main(int argc, char *argv[])
{
	int32_t fan1 = -1, fan2 = -1, temp = -1, off = -1, min = -1, hc = -1;
	char ver[64] = { 0 };
	int fd, verbose = 0, ret = 0;

	if (argc > 1 && strcmp(argv[1], "-v") == 0) verbose = 1;

	fd = open("/dev/tuxedo_io", O_RDWR);
	if (fd < 0) { perror("open /dev/tuxedo_io"); return 1; }

	if (ioctl(fd, R_MOD_VERSION, ver) == 0 && verbose)
		fprintf(stderr, "tuxedo_io %s\n", ver);

	if (uw_call(fd, R_HWCHECK_UW, "R_HWCHECK_UW", &hc) == 0 && hc != 1) {
		fprintf(stderr, "not a Uniwill EC (hwcheck=%d)\n", hc);
		close(fd);
		return 1;
	}

	if (argc > 1 && strcmp(argv[1], "a") == 0) {
		ret = uw_call(fd, W_UW_FANAUTO, "W_UW_FANSPEED_AUTO", NULL) != 0;
		close(fd);
		return ret;
	}

	if (argc > 1 && strcmp(argv[1], "w") == 0) {
		int32_t d1, d2;
		if (argc < 3) {
			fprintf(stderr, "usage: %s w <duty1> [duty2]\n", argv[0]);
			close(fd);
			return 1;
		}
		d1 = (int32_t) strtol(argv[2], NULL, 10);
		d2 = argc > 3 ? (int32_t) strtol(argv[3], NULL, 10) : d1;
		ret = set_fans(fd, d1, d2) != 0;
		if (!ret && read_fans(fd, &fan1, &fan2) == 0)
			printf("%d %d\n", fan1, fan2);
		close(fd);
		return ret;
	}

	if (read_fans(fd, &fan1, &fan2) != 0) { close(fd); return 1; }
	uw_call(fd, R_UW_FAN_TEMP, "R_UW_FAN_TEMP", &temp);
	uw_call(fd, R_UW_FANS_OFF_AV, "R_UW_FANS_OFF_AVAILABLE", &off);
	uw_call(fd, R_UW_FANS_MIN_SPD, "R_UW_FANS_MIN_SPEED", &min);
	close(fd);

	printf("%d %d\n", fan1, fan2);

	if (verbose) {
		fprintf(stderr, "fan1=%d/%d (%d%%) fan2=%d/%d (%d%%) fan_temp=%d fans_off=%d min=%d\n",
			fan1, DUTY_MAX, fan1 * 100 / DUTY_MAX,
			fan2, DUTY_MAX, fan2 * 100 / DUTY_MAX, temp, off, min);
	}
	return 0;
}
