#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/utsname.h>
#include <linux/string.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rulefucker");
MODULE_DESCRIPTION("Overwrites init_uts_ns to spoof uname permanently in kernel memory");
MODULE_VERSION("3.0");

static char *sysname = "RuleOS";
static char *nodename = "rulefucker-pc";
static char *release = "10.0.0-rule";
static char *version = "1.0";
static char *machine = "x86_64";

module_param(sysname, charp, 0000);
module_param(nodename, charp, 0000);
module_param(release, charp, 0000);
module_param(version, charp, 0000);
module_param(machine, charp, 0000);

static int __init rulefucker_init(void) {
    struct new_utsname *u = &init_uts_ns.name;
    
    down_write(&uts_sem);
    
    // Orijinal verileri değiştirmek
    strscpy(u->sysname, sysname, sizeof(u->sysname));
    strscpy(u->nodename, nodename, sizeof(u->nodename));
    strscpy(u->release, release, sizeof(u->release));
    strscpy(u->version, version, sizeof(u->version));
    strscpy(u->machine, machine, sizeof(u->machine));
    
    up_write(&uts_sem);
    
    printk(KERN_INFO "Rulefucker: Kernel identity has been permanently rewritten.\n");
    return 0;
}

static void __exit rulefucker_exit(void) {
    printk(KERN_INFO "Rulefucker: Module unloaded (Identity remains changed until reboot).\n");
}

module_init(rulefucker_init);
module_exit(rulefucker_exit);
