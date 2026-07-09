#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/utsname.h>
#include <linux/string.h>
#include <linux/list.h>
#include <linux/slab.h>
#include <linux/kallsyms.h>
#include <linux/version.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rulefucker Advanced");
MODULE_DESCRIPTION("Advanced kernel identity mutator with stealth, persistence, and runtime reconfiguration");
MODULE_VERSION("5.0");

/* --- Parametreler (modprobe veya sysfs ile değiştirilebilir) --- */
static char *sysname  = "RuleOS";
static char *nodename = "rulefucker-pc";
static char *release  = "10.0.0-rule";
static char *version  = "#1 SMP PREEMPT_DYNAMIC RuleFucker 5.0";
static char *machine  = "x86_64";
static char *domain   = "(none)";

module_param(sysname,  charp, 0644);
module_param(nodename, charp, 0644);
module_param(release,  charp, 0644);
module_param(version,  charp, 0644);
module_param(machine,  charp, 0644);
module_param(domain,   charp, 0644);

MODULE_PARM_DESC(sysname,  "Operating system name (e.g. RuleOS)");
MODULE_PARM_DESC(nodename, "Hostname within the UTS namespace");
MODULE_PARM_DESC(release,  "Kernel release string");
MODULE_PARM_DESC(version,  "Kernel version string");
MODULE_PARM_DESC(machine,  "Machine hardware name (e.g. x86_64)");
MODULE_PARM_DESC(domain,   "NIS/YP domain name");

/* --- Stealth: modülü /proc/modules ve /sys/module'dan gizle --- */
static int hidden = 0;
module_param(hidden, int, 0444);
MODULE_PARM_DESC(hidden, "Set 1 to hide module from lsmod and /sys/module");

static struct list_head *module_list = NULL;
static struct list_head *module_prev = NULL;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(2,6,0)
static int module_hidden = 0;
#endif

static void hide_module(void) {
    if (module_hidden)
        return;

    /* /proc/modules listesinden çıkar */
    module_list = &THIS_MODULE->list;
    module_prev = module_list->prev;
    list_del_init(module_list);

    /* sysfs görünürlüğünü kaldır */
    if (THIS_MODULE->mkobj.kobj.parent) {
        kobject_del(&THIS_MODULE->mkobj.kobj);
    }

    module_hidden = 1;
    printk(KERN_INFO "Rulefucker: Module hidden from /proc/modules and /sys/module\n");
}

/* --- /proc/rulefucker için procfs handler --- */
static struct proc_dir_entry *proc_entry = NULL;

static ssize_t proc_read(struct file *filp, char __user *buf,
                         size_t count, loff_t *offp) {
    char output[512];
    int len;

    struct new_utsname *u = &init_uts_ns.name;

    len = snprintf(output, sizeof(output),
        "sysname : %s\n"
        "nodename: %s\n"
        "release : %s\n"
        "version : %s\n"
        "machine : %s\n"
        "domain  : %s\n"
        "hidden  : %d\n",
        u->sysname, u->nodename, u->release,
        u->version, u->machine, u->domainname,
        hidden);

    return simple_read_from_buffer(buf, count, offp, output, len);
}

static const struct proc_ops proc_fops = {
    .proc_read = proc_read,
};

/* --- Kernel hafızasına yazma (ana fonksiyon) --- */
static void rewrite_utsname(void) {
    struct new_utsname *u = &init_uts_ns.name;

    down_write(&uts_sem);

    memset(u->sysname,    0, sizeof(u->sysname));
    memset(u->nodename,   0, sizeof(u->nodename));
    memset(u->release,    0, sizeof(u->release));
    memset(u->version,    0, sizeof(u->version));
    memset(u->machine,    0, sizeof(u->machine));
    memset(u->domainname, 0, sizeof(u->domainname));

    strscpy(u->sysname,    sysname,  sizeof(u->sysname));
    strscpy(u->nodename,   nodename, sizeof(u->nodename));
    strscpy(u->release,    release,  sizeof(u->release));
    strscpy(u->version,    version,  sizeof(u->version));
    strscpy(u->machine,    machine,  sizeof(u->machine));
    strscpy(u->domainname, domain,   sizeof(u->domainname));

    up_write(&uts_sem);

    printk(KERN_INFO "Rulefucker: Kernel identity rewritten:\n");
    printk(KERN_INFO "  sysname=%s | nodename=%s | release=%s\n",
           u->sysname, u->nodename, u->release);
    printk(KERN_INFO "  version=%s | machine=%s | domain=%s\n",
           u->version, u->machine, u->domainname);
}

/* --- Init --- */
static int __init rulefucker_init(void) {
    printk(KERN_INFO "Rulefucker Advanced v5.0 loading...\n");

    /* UTS ismini yeniden yaz */
    rewrite_utsname();

    /* /proc/rulefucker oluştur */
    proc_entry = proc_create("rulefucker", 0444, NULL, &proc_fops);
    if (!proc_entry)
        printk(KERN_WARNING "Rulefucker: Failed to create /proc/rulefucker\n");

    /* Stealth mod aktifse modülü gizle */
    if (hidden)
        hide_module();

    printk(KERN_INFO "Rulefucker: Module loaded successfully.\n");
    return 0;
}

/* --- Exit --- */
static void __exit rulefucker_exit(void) {
    if (proc_entry)
        proc_remove(proc_entry);

    printk(KERN_INFO "Rulefucker: Module unloaded. "
           "Kernel identity remains changed until next reboot.\n");
}

module_init(rulefucker_init);
module_exit(rulefucker_exit);
