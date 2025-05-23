#ifndef _TESTTIMER_H_
#define _TESTTIMER_H_


struct testtimer_dev {
	char *p_data;              /* pointer to the memory allocated */
	struct cdev cdev;	         /* Char device structure		*/
};



#endif /* _TESTTIMER_H_ */
