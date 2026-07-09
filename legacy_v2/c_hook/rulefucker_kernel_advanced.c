/*
 * rulefucker_kernel_advanced.c
 * Rulefucker v5.0 - Advanced Kernel Identity Mutator (LKM)
 *
 * Bu bir Linux Kernel Module (LKM)'dir.
 * init_uts_ns.name yapısına doğrudan yazarak uname çıktısını
 * kernel hafızasında kalıcı olarak değiştirir.
 *
 * LEGACY V2 LD_PRELOAD hook'unun aksine:
 * - Kernel seviyesinde çalışır (userspace bypass edilemez)
 * - Tüm process'leri ve container'ları etkiler
 * - Reboot'a kadar kalıcıdır
 * - lsmod'dan gizlenebilir (stealth)
 * - /proc/rulefucker ile anlık durum okunabilir
 *
 * Yetkilendirme: Yetkili pentest kapsamında kullanım içindir.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/utsname.h>
#include <linux/string.h>
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/version.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/list.h>
#include <linux/slab.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rulefucker Advanced");
MODULE_DESCRIPTION("Advanced LKM: Overwrites init_uts_ns to permanently mutate kernel identity in memory. "
                   "Includes stealth, procfs status, and runtime reconfiguration.");
MODULE_VERSION("5.0");

/* ==========================================================================
 * YAPILANDIRMA PARAMETRELERI
 * ==========================================================================
 * Değerler insmod/modprobe ile iletilir:
 *   insmod rulefucker_kernel_advanced.ko sysname="PentestOS" hidden=1
 *
 * sysfs üzerinden runtime değiştirilebilir (eğer gizli değilse):
 *   echo "NewOS" > /sys/module/rulefucker_kernel_advanced/parameters/sysname
 * ========================================================================== */

static char *sysname  = "RuleOS";
static char *nodename = "rulefucker-pc";
static char *release  = "10.0.0-rule";
static char *version  = "#1 SMP PREEMPT_DYNAMIC RuleFucker Advanced 5.0";
static char *machine  = "x86_64";
static char *domain   = "(none)";

module_param(sysname,  charp, 0644);
module_param(nodename, charp, 0644);
module_param(release,  charp, 0644);
module_param(version,  charp, 0644);
module_param(machine,  charp, 0644);
module_param(domain,   charp, 0644);

MODULE_PARM_DESC(sysname,  "Operating system name (uname -s)");
MODULE_PARM_DESC(nodename, "Hostname (uname -n)");
MODULE_PARM_DESC(release,  "Kernel release (uname -r)");
MODULE_PARM_DESC(version,  "Kernel version (uname -v)");
MODULE_PARM_DESC(machine,  "Machine hardware name (uname -m)");
MODULE_PARM_DESC(domain,   "NIS/YP domain name (uname -d)");

static int hidden = 0;
module_param(hidden, int, 0444);
MODULE_PARM_DESC(hidden, "Stealth: set 1 to hide module from lsmod and /sys/module");

/* ==========================================================================
 * STEALTH (MODÜL GİZLEME)
 * ==========================================================================
 * Modülü /proc/modules (kmod listesi) ve /sys/module dizininden kaldırır.
 * NOT: /proc/kallsyms içinde semboller kalabilir (kptr_restrict=1 ile gizlenebilir).
 * ========================================================================== */

static struct list_head *module_list_prev = NULL;
static int module_hidden = 0;

static void hide_module(void)
{
    if (module_hidden)
        return;

    /* Modülü kernel modül listesinden çıkar (/proc/modules'te görünmez) */
    module_list_prev = THIS_MODULE->list.prev;
    list_del_init(&THIS_MODULE->list);

    /* sysfs görünürlüğünü kaldır */
    if (THIS_MODULE->mkobj.kobj.parent) {
        kobject_del(&THIS_MODULE->mkobj.kobj);
    }

    module_hidden = 1;
    printk(KERN_INFO "rulefucker_advanced: Module hidden from /proc/modules and /sys/module\n");
}

static void unhide_module(void)
{
    if (!module_hidden)
        return;

    /* Modülü listeye geri ekle */
    if (module_list_prev) {
        list_add(&THIS_MODULE->list, module_list_prev);
    }

    module_hidden = 0;
    printk(KERN_INFO "rulefucker_advanced: Module visible again\n");
}

/* ==========================================================================
 * PROCFS /proc/rulefucker
 * ==========================================================================
 * Anlık kernel kimlik durumunu okumak için:
 *   cat /proc/rulefucker
 * ========================================================================== */

static struct proc_dir_entry *proc_entry = NULL;

static ssize_t proc_rulefucker_read(struct file *filp, char __user *buf,
                                     size_t count, loff_t *offp)
{
    struct new_utsname *u = &init_uts_ns.name;
    char output[1024];
    int len;

    len = snprintf(output, sizeof(output),
        "Rulefucker Advanced v5.0 - Kernel Identity Status\n"
        "─────────────────────────────────────────────\n"
        "  sysname   : %s\n"
        "  nodename  : %s\n"
        "  release   : %s\n"
        "  version   : %s\n"
        "  machine   : %s\n"
        "  domain    : %s\n"
        "  hidden    : %s\n"
        "  module    : %s\n"
        "─────────────────────────────────────────────\n",
        u->sysname, u->nodename, u->release,
        u->version, u->machine, u->domainname,
        module_hidden ? "yes" : "no",
        module_hidden ? "hidden" : "visible");

    return simple_read_from_buffer(buf, count, offp, output, len);
}

static const struct proc_ops proc_rulefucker_fops = {
    .proc_read = proc_rulefucker_read,
};

/* ==========================================================================
 * ÇEKİRDEK: KERNEL KİMLİĞİNİ YENİDEN YAZMA
 * ==========================================================================
 * init_uts_ns.name yapısı, tüm UTS namespace'lerin temelidir.
 * down_write(&uts_sem) ile yazma kilidi alınır, ardından
 * strscpy ile güvenli şekilde kopyalanır.
 * ========================================================================== */

static void rewrite_utsname(void)
{
    struct new_utsname *u = &init_uts_ns.name;

    /* UTS namespace yazma kilidini al */
    down_write(&uts_sem);

    /* Tüm alanları sıfırla */
    memset(u->sysname,    0, sizeof(u->sysname));
    memset(u->nodename,   0, sizeof(u->nodename));
    memset(u->release,    0, sizeof(u->release));
    memset(u->version,    0, sizeof(u->version));
    memset(u->machine,    0, sizeof(u->machine));
    memset(u->domainname, 0, sizeof(u->domainname));

    /* Yeni değerleri yaz (güvenli kopyalama) */
    strscpy(u->sysname,    sysname,  sizeof(u->sysname));
    strscpy(u->nodename,   nodename, sizeof(u->nodename));
    strscpy(u->release,    release,  sizeof(u->release));
    strscpy(u->version,    version,  sizeof(u->version));
    strscpy(u->machine,    machine,  sizeof(u->machine));
    strscpy(u->domainname, domain,   sizeof(u->domainname));

    /* Yazma kilidini bırak */
    up_write(&uts_sem);

    printk(KERN_INFO "rulefucker_advanced: Kernel identity rewritten:\n");
    printk(KERN_INFO "  sysname=%s | nodename=%s | release=%s\n",
           u->sysname, u->nodename, u->release);
    printk(KERN_INFO "  version=%s | machine=%s | domain=%s\n",
           u->version, u->machine, u->domainname);
}

/* ==========================================================================
 * MODÜL YÜKLEME
 * ========================================================================== */

static int __init rulefucker_advanced_init(void)
{
    printk(KERN_INFO "rulefucker_advanced: Loading v5.0...\n");

    /* 1. Kernel kimliğini yeniden yaz */
    rewrite_utsname();

    /* 2. Procfs entry oluştur */
    proc_entry = proc_create("rulefucker", 0444, NULL, &proc_rulefucker_fops);
    if (!proc_entry) {
        printk(KERN_WARNING "rulefucker_advanced: Failed to create /proc/rulefucker\n");
    } else {
        printk(KERN_INFO "rulefucker_advanced: /proc/rulefucker created\n");
    }

    /* 3. Stealth mod aktifse modülü gizle */
    if (hidden) {
        hide_module();
    }

    printk(KERN_INFO "rulefucker_advanced: Module loaded successfully.\n");
    printk(KERN_INFO "rulefucker_advanced: Use 'cat /proc/rulefucker' to view status.\n");

    return 0;
}

/* ==========================================================================
 * MODÜL KALDIRMA
 * ========================================================================== */

static void __exit rulefucker_advanced_exit(void)
{
    /* Procfs entry'i temizle */
    if (proc_entry) {
        proc_remove(proc_entry);
    }

    /* Gizliysek görünür yap (temiz kaldırma için) */
    if (module_hidden) {
        unhide_module();
    }

    printk(KERN_INFO "rulefucker_advanced: Module unloaded. "
           "Kernel identity remains changed until next reboot.\n");
}

module_init(rulefucker_advanced_init);
module_exit(rulefucker_advanced_exit);
