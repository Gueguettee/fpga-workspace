/*** Author  :   William Simon <william.simon@epfl.ch>
 ***             Miguel Peon <miguel.peon@epfl.ch>
 ***             Modification for fft: Gaëtan Jenni <gaetan.jenni@epfl.ch>
 *** Date    :   March 2021
 ***             Modification for fft: May 2025
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

#define DRIVER_NAME "fft_driver"
#define FFT_IRQ 48  // Hard-coded value of IRQ vector (GIC: 61).

// Structure that mimics the layout of the peripheral registers.
// Vitis HLS skips some addresses in the register file. We introduce
// padding fields to create the right mapping to registers with our structure,
struct TRegs {
  uint32_t control; // 0x00
  uint32_t gier, ier, isr; // 0x04, 0x08, 0x0C
  uint32_t In_real; // 0x10
  uint32_t In_real_h; // 0x14
  uint32_t padding0; // 0x18
  uint32_t In_imag; // 0x1C
  uint32_t In_imag_h; // 0x20
  uint32_t padding1; // 0x24
  uint32_t log2nfft; // 0x28
  uint32_t padding2; // 0x2C
  uint32_t Out_real; // 0x30
  uint32_t Out_real_h; // 0x34
  uint32_t padding3; //0x38
  uint32_t Out_imag; //0x3C
  uint32_t Out_imag_h; // 0x40
  uint32_t padding4; // 0x44
  uint32_t numHW; // 0x48
  uint32_t padding6; // 0x4C
  uint32_t padding7; // 0x50
  uint32_t padding8; // 0x54
  uint32_t padding9; // 0x58
  uint32_t padding10; // 0x5C
  uint32_t padding11; // 0x60
  uint32_t padding12; // 0x64
  uint32_t padding13; // 0x68
};

// Structure used to pass commands between user-space and kernel-space.
struct user_message {
  uint32_t phyIn_real;
  uint32_t phyIn_imag;
  uint32_t log2_nfft;
  uint32_t phyOut_real;
  uint32_t phyOut_imag;
  uint32_t workers;
};

int fft_major = 0;
int fft_minor = 0;
module_param(fft_major,int,S_IRUGO);
module_param(fft_minor,int,S_IRUGO);

// We declare a wait queue that will allow us to wait on a condition.
wait_queue_head_t wq;
int flag = 0;

// This structure contains the device information.
struct fft_info {
  int irq;
  unsigned long memStart;
  unsigned long memEnd;
  void __iomem  *baseAddr;
  struct cdev   cdev;            /* Char device structure               */
};

static struct fft_info fft_mem = {FFT_IRQ, 0x40000000, 0x4000FFFF};

// Declare here the user-accessible functions that the driver implements.
int fft_open(struct inode *inode, struct file *filp);
int fft_release(struct inode *inode, struct file *filed_mem);
ssize_t fft_read(struct file *filed_mem, char __user *buf, size_t count, loff_t *f_pos);

// IRQ handler function.
static irq_handler_t  fftIRQHandler(unsigned int irq, void *dev_id, struct pt_regs *regs);

// This structure declares the operations that our driver exports for the users.
struct file_operations fft_fops = {
  .owner =    THIS_MODULE,
  .read =     fft_read,
  .open =     fft_open,
  .release =  fft_release,
};


// Function that implements system call open() for our driver.
// Initialize the device and enable the interrups here.
int fft_open(struct inode *inode, struct file *filp)
{
  pr_info("fft_DRIVER: Performing 'open' operation\n");
  return 0;         
}

// Function that implements system call release() for our driver.
// Used with close() or when the OS closes the descriptors held by
// the process when it is closed (e.g., Ctrl-C).
// Stop the interrupts and disable the device.
int fft_release(struct inode *inode, struct file *filed_mem)
{
  pr_info("fft_DRIVER: Performing 'release' operation\n");
  return 0;
}

// The cleanup function is used to handle initialization failures as well.
// Thefore, it must be careful to work correctly even if some of the items
// have not been initialized

void fft_cleanup_module(void)
{
  dev_t devno = MKDEV(fft_major, fft_minor);
  disable_irq(fft_mem.irq);
  free_irq(fft_mem.irq,&fft_mem);
  iounmap(fft_mem.baseAddr);
  release_mem_region(fft_mem.memStart, fft_mem.memEnd - fft_mem.memStart + 1);
  cdev_del(&fft_mem.cdev);
  unregister_chrdev_region(devno, 1);        /* unregistering device */
  pr_info("fft_DRIVER: Cdev deleted, fft device unmapped, chdev unregistered\n");
}

// Function that implements system call read() for our driver.
// Returns 1 uint32_t with the number of times the interrupt has been detected.
ssize_t fft_read(struct file *filed_mem, char __user *buf, size_t count, loff_t *f_pos)
{
  volatile struct TRegs * slave_regs = (struct TRegs*)fft_mem.baseAddr;
  struct user_message message;
  uint32_t status;

  if (count < sizeof(struct user_message)) {
    pr_err("fft_DRIVER: USer buffer too small (> %d bytes).\n", sizeof(struct user_message));
    return -1;
  }

  // Copy the information from user-space to the kernel-space buffer.
  if(raw_copy_from_user(&message, buf, sizeof(struct user_message)))
  {
    pr_err("fft_DRIVER: Raw copy from user buffer failed.\n");
    return -1;
  }

  // Program the peripheral registers.
  iowrite32(message.phyIn_real, (volatile void*)(&slave_regs->In_real));
  iowrite32(message.phyIn_imag, (volatile void*)(&slave_regs->In_imag));
  iowrite32(message.log2_nfft, (volatile void*)(&slave_regs->log2nfft));
  iowrite32(message.phyOut_real, (volatile void*)(&slave_regs->Out_real));
  iowrite32(message.phyOut_imag, (volatile void*)(&slave_regs->Out_imag));
  iowrite32(message.workers, (volatile void*)(&slave_regs->numHW));
  
  // Enable interrupts (global and spacific to done).
  iowrite32(1, (volatile void*)(&slave_regs->gier));
  iowrite32(1, (volatile void*)(&slave_regs->ier));
  mb();
  pr_info("fft_DRIVER: Starting accel...\n");
  
  // Tell the peripheral to start (start bit = 1)
  status = ioread32((volatile void*)(&slave_regs->control));
  status |= 1; 
  iowrite32(status, (volatile void*)(&slave_regs->control));
  mb();

  // blocking read (PS user application goes to sleep)
  // Sleep the thread until the peripheral generates an interrupt
  // wait_event_interruptible may exit when a signal is received, so
  // we check our flag to ensure that it was our own interrupt handler
  // waking up us after the interrupt is received, and not an 
  // spurious signal.
  // When we go to sleep, the processor is free for other tasks.
  flag = 0;
  while(wait_event_interruptible(wq, flag !=0)) {
    printk(KERN_ALERT "fft_DRIVER: AWOKEN BY ANOTHER SIGNAL\n");
  }
  pr_info("fft_DRIVER: AWOKEN FROM INTERRUPT\n");

  // Disable interrupts.
  iowrite32(0, (volatile void*)&slave_regs->gier);
  iowrite32(0, (volatile void*)&slave_regs->ier);
  mb();

  pr_info("fft_DRIVER: Performed READ operation successfully\n");
  return 0;
}

// Set up the char_dev structure for this device.
static void fft_setup_cdev(struct fft_info *_fft_mem)
{
	int err, devno = MKDEV(fft_major, fft_minor);

	cdev_init(&_fft_mem->cdev, &fft_fops);
	_fft_mem->cdev.owner = THIS_MODULE;
	_fft_mem->cdev.ops = &fft_fops;
	err = cdev_add(&_fft_mem->cdev, devno, 1);
	/* Fail gracefully if need be */
	if (err)
		pr_err("fft_DRIVER: Error %d adding fft cdev_add", err);

  pr_info("fft_DRIVER: Cdev initialized\n");
}


// The init function registers the chdev.
// It allocates dynamically a new major number.
// The major number corresponds to a different function driver.
static int fft_init(void)
{
  int result = 0;
  dev_t dev = 0;

  // Allocate a function number for our driver (major number).
  // The minor number is the instance of the driver.
  pr_info("fft_DRIVER: Allocating a new major number.\n");
  result = alloc_chrdev_region(&dev, fft_minor, 1, "fft");
  fft_major = MAJOR(dev);
  if (result < 0) {
    pr_err("fft_DRIVER: Can't get major %d\n", fft_major);
    return result;
  }

  // Request (exclusive) access to the memory address range of the peripheral.
  if (!request_mem_region(fft_mem.memStart, fft_mem.memEnd - fft_mem.memStart + 1, DRIVER_NAME)) {
    pr_err("fft_DRIVER: Couldn't lock memory region at %p\n", (void *)fft_mem.memStart);
    unregister_chrdev_region(dev, 1);
    return -1;
  }

  // Obtain a "kernel virtual address" for the physical address of the peripheral.
  fft_mem.baseAddr = ioremap(fft_mem.memStart, fft_mem.memEnd - fft_mem.memStart + 1);
  if (!fft_mem.baseAddr) {
    pr_err("fft_DRIVER: Could not obtain virtual kernel address for iomem space.\n");
    release_mem_region(fft_mem.memStart, fft_mem.memEnd - fft_mem.memStart + 1);
    unregister_chrdev_region(dev, 1);
    return -1;
  }

  init_waitqueue_head(&wq);

  // Request registering our interrupt handler for the IRQ of the peripheral.
  // We configure the interrupt to be detected on the rising edge of the signal.
  result = request_irq(fft_mem.irq, (irq_handler_t)fftIRQHandler, IRQF_TRIGGER_RISING, DRIVER_NAME, &fft_mem);
  if(result) {
    printk(KERN_ALERT "fft_DRIVER: Failed to register interrupt handler (error=%d)\n", result);     
    iounmap(fft_mem.baseAddr);
    release_mem_region(fft_mem.memStart, fft_mem.memEnd - fft_mem.memStart + 1);
    cdev_del(&fft_mem.cdev);
    unregister_chrdev_region(dev, 1);
    return result;
  }

  // Enable the IRQ. From this moment on, we can receive the IRQ asynchronously at any time.
  enable_irq(fft_mem.irq);
  pr_info("fft_DRIVER: Interrupt %d registered\n", fft_mem.irq);

  pr_info("fft_DRIVER: driver at 0x%08X mapped to 0x%08X\n",
    (uint32_t)fft_mem.memStart, (uint32_t)fft_mem.baseAddr); 
  fft_setup_cdev(&fft_mem);

  return 0;
}


// The exit function calls the cleanup
static void fft_exit(void)
{
	  pr_info("fft_DRIVER: calling cleanup function.\n");
	  fft_cleanup_module();
}

// Declare init and exit handlers.
// They are invoked when the driver is loaded or unloaded.
module_init(fft_init);
module_exit(fft_exit);


// The interrupt handler is called on the (rising edge of the) accelerator interrupt.
// The interrupt handler is executed in an interrupt context, not a process context!!!
// It must be quick, it cannot sleep. It cannot use functions that can sleep
// (e.g., don't allocate memory if that may wait for swapping).
// The handler cannot communicate directly with the user-space. The user-space does not
// interact with the interrupt handler.
static irq_handler_t fftIRQHandler(unsigned int irq, void *dev_id, struct pt_regs *regs)
{
  volatile struct TRegs * slave_regs = (struct TRegs*)fft_mem.baseAddr;
  // Clean the interrupt in the peripheral, so that we can detect new rising transition.
  // The ISR is toggle-on-write (TOW), which means that its bits toggle when they are
  // written, whatever it was their previous value. Therefore, we write (1) to the 
  // 'done' bit to toggle it, so that it becomes 0 and the interrupt is disarmed.
  iowrite32(1, (volatile void*)&slave_regs->isr);
  mb();

  // Signal that it is us waking the main thread.
	flag = 1;
  // Wake the main thread.
	wake_up_interruptible(&wq);
	return (irq_handler_t) IRQ_HANDLED;      // Announce that the IRQ has been handled correctly
  // In case of error, or if it was not our device which generated the IRQ, return IRQ_NONE.
}

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ruben Rodriguez Alvarez <ruben.rodriguezalvarez@epfl.ch>");
MODULE_DESCRIPTION("Example device driver for controlling PYNQ-Z2 SimpleVectorfft");
MODULE_VERSION("1.1");
