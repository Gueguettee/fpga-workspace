/*** Author  :   William Simon <william.simon@epfl.ch>
 ***             Miguel Peon <miguel.peon@epfl.ch>
 *** Date    :   March 2021
 ***/

#include <linux/init.h>          /* needed for module_init and exit */
#include <linux/module.h>
#include <linux/moduleparam.h>   /* needed for module_param */
#include <linux/kernel.h>        /* needed for printk */
#include <linux/types.h>         /* needed for dev_t type */
#include <linux/kdev_t.h>        /* needed for macros MAJOR, MINOR, MKDEV... */
#include <linux/fs.h>            /* needed for register_chrdev_region, file_operations */
#include <linux/interrupt.h>
#include <linux/cdev.h>          /* cdev definition */
#include <linux/slab.h>		       /* kmalloc(),kfree() */
#include <asm/uaccess.h>         /* copy_to copy_from _user */
#include <linux/uaccess.h>
#include <linux/io.h>

#define DRIVER_NAME "testtimer_driver"
#define TESTTIMER_IRQ 48  // Hard-coded value of IRQ vector (GIC: 61).
#define REG_COUNTER 0x00
#define REG_ENABLE 0x04
#define REG_ENABLE_INTERRUPT 0x08
#define REG_CLEAR_INTERRUPT 0x0C

int testtimer_major = 0;
int testtimer_minor = 0;
module_param(testtimer_major,int,S_IRUGO);
module_param(testtimer_minor,int,S_IRUGO);

// Count of times that the interrupt has been fired.
int testtimerIRQCount = 0;

// This structure contains the device information.
struct testtimer_info {
  int irq;
  unsigned long memStart;
  unsigned long memEnd;
  void __iomem  *baseAddr;
  struct cdev   cdev;            /* Char device structure               */
};
static struct testtimer_info testtimer_mem = {TESTTIMER_IRQ, 0x43C00000, 0x43C0FFFF};

// Declare here the user-accessible functions that the driver implements.
int testtimer_open(struct inode *inode, struct file *filp);
int testtimer_release(struct inode *inode, struct file *filed_mem);
ssize_t testtimer_read(struct file *filed_mem, char __user *buf, size_t count, loff_t *f_pos);

// IRQ handler function.
static irq_handler_t  testtimerIRQHandler(unsigned int irq, void *dev_id, struct pt_regs *regs);

// This structure declares the operations that our driver exports for the users.
struct file_operations testtimer_fops = {
  .owner =    THIS_MODULE,
  .read =     testtimer_read,
  .open =     testtimer_open,
  .release =  testtimer_release,
};


// Function that implements system call open() for our driver.
// Initialize the device and enable the interrups here.
int testtimer_open(struct inode *inode, struct file *filp)
{
  pr_info("TESTTIMER_DRIVER: Performing 'open' operation\n");

  iowrite32(1, testtimer_mem.baseAddr + REG_ENABLE_INTERRUPT);
  iowrite32(1, testtimer_mem.baseAddr + REG_ENABLE);
  testtimerIRQCount = 0;
  // Memory barrier, to ensure that the HW receives the writes before anything else happens.
  mb();

  return 0;         
}

// Function that implements system call release() for our driver.
// Used with close() or when the OS closes the descriptors held by
// the process when it is closed (e.g., Ctrl-C).
// Stop the interrupts and disable the device.
int testtimer_release(struct inode *inode, struct file *filed_mem)
{
  pr_info("TESTTIMER_DRIVER: Performing 'release' operation\n");

  iowrite32(0, testtimer_mem.baseAddr + REG_ENABLE_INTERRUPT);
  iowrite32(0, testtimer_mem.baseAddr + REG_ENABLE);
  // Memory barrier, to ensure that the HW receives the writes before anything else happens.
  mb();
  return 0;
}

// The cleanup function is used to handle initialization failures as well.
// Thefore, it must be careful to work correctly even if some of the items
// have not been initialized

void testtimer_cleanup_module(void)
{
  dev_t devno = MKDEV(testtimer_major, testtimer_minor);
  disable_irq(testtimer_mem.irq);
  free_irq(testtimer_mem.irq,&testtimer_mem);
  iounmap(testtimer_mem.baseAddr);
  release_mem_region(testtimer_mem.memStart, testtimer_mem.memEnd - testtimer_mem.memStart + 1);
  cdev_del(&testtimer_mem.cdev);
  unregister_chrdev_region(devno, 1);        /* unregistering device */
  pr_info("TESTTIMER_DRIVER: Cdev deleted, testtimer device unmapped, chdev unregistered\n");
}

// Function that implements system call read() for our driver.
// Returns 1 uint32_t with the number of times the interrupt has been detected.
ssize_t testtimer_read(struct file *filed_mem, char __user *buf, size_t count, loff_t *f_pos)
{
  if (count < sizeof(testtimerIRQCount)) {
    pr_err("LED_DRIVER: USer buffer too small (> %d bytes).\n", sizeof(testtimerIRQCount));
    return -1;
  }

  // Copy the output information from kernel-space to the user-space buffer.
  if(raw_copy_to_user(buf, &testtimerIRQCount, sizeof(testtimerIRQCount)))
  {
    pr_err("LED_DRIVER: Raw copy to user buffer failed.\n");
    return -1;
  }

  pr_info("LED_DRIVER: Performed READ operation successfully\n");
  return sizeof(testtimerIRQCount);
}

// Set up the char_dev structure for this device.
static void testtimer_setup_cdev(struct testtimer_info *_testtimer_mem)
{
	int err, devno = MKDEV(testtimer_major, testtimer_minor);

	cdev_init(&_testtimer_mem->cdev, &testtimer_fops);
	_testtimer_mem->cdev.owner = THIS_MODULE;
	_testtimer_mem->cdev.ops = &testtimer_fops;
	err = cdev_add(&_testtimer_mem->cdev, devno, 1);
	/* Fail gracefully if need be */
	if (err)
		pr_err("TESTTIMER_DRIVER: Error %d adding testtimer cdev_add", err);

  pr_info("TESTTIMER_DRIVER: Cdev initialized\n");
}


// The init function registers the chdev.
// It allocates dynamically a new major number.
// The major number corresponds to a different function driver.
static int testtimer_init(void)
{
  int result = 0;
  dev_t dev = 0;

  // Allocate a function number for our driver (major number).
  // The minor number is the instance of the driver.
  pr_info("TESTTIMER_DRIVER: Allocating a new major number.\n");
  result = alloc_chrdev_region(&dev, testtimer_minor, 1, "testtimer");
  testtimer_major = MAJOR(dev);
  if (result < 0) {
    pr_err("TESTTIMER_DRIVER: Can't get major %d\n", testtimer_major);
    return result;
  }

  // Request (exclusive) access to the memory address range of the peripheral.
  if (!request_mem_region(testtimer_mem.memStart, testtimer_mem.memEnd - testtimer_mem.memStart + 1, DRIVER_NAME)) {
    pr_err("TESTTIMER_DRIVER: Couldn't lock memory region at %p\n", (void *)testtimer_mem.memStart);
    unregister_chrdev_region(dev, 1);
    return -1;
  }

  // Obtain a "kernel virtual address" for the physical address of the peripheral.
  testtimer_mem.baseAddr = ioremap(testtimer_mem.memStart, testtimer_mem.memEnd - testtimer_mem.memStart + 1);
  if (!testtimer_mem.baseAddr) {
    pr_err("TESTTIMER_DRIVER: Could not obtain virtual kernel address for iomem space.\n");
    release_mem_region(testtimer_mem.memStart, testtimer_mem.memEnd - testtimer_mem.memStart + 1);
    unregister_chrdev_region(dev, 1);
    return -1;
  }

  // Request registering our interrupt handler for the IRQ of the peripheral.
  // We configure the interrupt to be detected on the rising edge of the signal.
  result = request_irq(testtimer_mem.irq, (irq_handler_t)testtimerIRQHandler, IRQF_TRIGGER_RISING, DRIVER_NAME, &testtimer_mem);
  if(result) {
    printk(KERN_ALERT "TESTTIMER_DRIVER: Failed to register interrupt handler (error=%d)\n", result);     
    iounmap(testtimer_mem.baseAddr);
    release_mem_region(testtimer_mem.memStart, testtimer_mem.memEnd - testtimer_mem.memStart + 1);
    cdev_del(&testtimer_mem.cdev);
    unregister_chrdev_region(dev, 1);
    return result;
  }

  // Enable the IRQ. From this moment on, we can receive the IRQ asynchronously at any time.
  enable_irq(testtimer_mem.irq);
  pr_info("TESTTIMER_DRIVER: Interrupt %d registered\n", testtimer_mem.irq);

  pr_info("TESTTIMER_DRIVER: driver at 0x%08X mapped to 0x%08X\n",
    (uint32_t)testtimer_mem.memStart, (uint32_t)testtimer_mem.baseAddr); 
  testtimer_setup_cdev(&testtimer_mem);

  return 0;
}


// The exit function calls the cleanup
static void testtimer_exit(void)
{
	  pr_info("TESTTIMER_DRIVER: calling cleanup function.\n");
	  testtimer_cleanup_module();
}

// Declare init and exit handlers.
// They are invoked when the driver is loaded or unloaded.
module_init(testtimer_init);
module_exit(testtimer_exit);


// The interrupt handler is called on the (rising edge of the) accelerator interrupt.
// The interrupt handler is executed in an interrupt context, not a process context!!!
// It must be quick, it cannot sleep. It cannot use functions that can sleep
// (e.g., don't allocate memory if that may wait for swapping).
// The handler cannot communicate directly with the user-space. The user-space does not
// interact with the interrupt handler.
static irq_handler_t testtimerIRQHandler(unsigned int irq, void *dev_id, struct pt_regs *regs)
{
  testtimerIRQCount++;

  // Clean the interrupt in the peripheral, so that we can detect new rising transition.
  iowrite32(1, testtimer_mem.baseAddr + REG_CLEAR_INTERRUPT);

  // Create a memory barrier to ensure that the peripheral sees the writes before we exit the handler.
  mb();
	return (irq_handler_t) IRQ_HANDLED;      // Announce that the IRQ has been handled correctly
  // In case of error, or if it was not our device which generated the IRQ, return IRQ_NONE.
}


MODULE_LICENSE("GPL");
MODULE_AUTHOR("William Simon <william.simon@epfl.ch>");
MODULE_DESCRIPTION("Example device driver for controlling PYNQ-Z2 TESTTIMER");
MODULE_VERSION("1.0");



