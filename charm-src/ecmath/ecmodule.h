#ifndef ECMODULE_H
#define ECMODULE_H

#include <Python.h>
#include <structmember.h>
#include <longintrepr.h>
#include <math.h>
#include <gmp.h>
#include "sha1.h"
#include "benchmarkmodule.h"
#include "base64.h"

/* Openssl header files */
#include "openssl/ec.h"
#include "openssl/err.h"
#include "openssl/obj_mac.h"
#include "openssl/objects.h"
#include "openssl/rand.h"
#include "openssl/bn.h"
#ifdef PROFILER
#include <google/profiler.h>
#define PROFILE_START(name) ProfilerStart(name".prof")
#define PROFILE_STOP  ProfilerStop()
#else
#define PROFILE_START
#define PROFILE_STOP
#endif

//#define DEBUG
#define TRUE	1
#define FALSE	0
#define BYTE	8
#define MAX_BUF  256
#define RAND_MAX_BYTES	2048
/* Index numbers for different hash functions.  These are all implemented as SHA1(index || message).	*/
#define HASH_FUNCTION_STR_TO_G_CRH		0
#define HASH_FUNCTION_STR_TO_ZR_CRH		1
#define HASH_FUNCTION_KEM_DERIVE		2
#define HASH_LEN	20

#ifdef DEBUG
#define debug(...)	printf("DEBUG: "__VA_ARGS__)
#else
#define debug(...)
#endif

PyTypeObject ECType;
static PyObject *PyECErrorObject;
static Benchmark *dBench;
#define PyEC_Check(obj) PyObject_TypeCheck(obj, &ECType)
enum Group {G = 0, ZR, NONE_G};
typedef enum Group GroupType;

PyMethodDef ECElement_methods[];
PyNumberMethods ecc_number;

// TODO: consider adding ref_cnt for keeping track of group ptr references.
typedef struct {
	PyObject_HEAD
	GroupType type;
	EC_GROUP *group;
	EC_POINT *P;
	BIGNUM *elemZ;
	BN_CTX *ctx; // not sure how this is used in Openssl lib.
	int point_init, group_init, nid;
} ECElement;

#define Check_Types2(o1, o2, lhs, rhs, foundLHS, foundRHS)  \
	if(PyEC_Check(o1)) { \
		lhs = (ECElement *) o1; \
		debug("found a lhs object.\n"); \
    } \
	else if(PyLong_Check(o1)) { \
		foundLHS = TRUE;  } \
							\
	if(PyEC_Check(o2)) {  \
		rhs = (ECElement *) o2; \
		debug("found a rhs object.\n"); \
    } \
	else if(PyLong_Check(o2)) {  \
		foundRHS = TRUE; }

#define ErrorMsg(msg) \
	PyErr_SetString(PyECErrorObject, msg); \
	return NULL;

#define Group_NULL(obj) if(obj->group == NULL) {  \
	PyErr_SetString(PyECErrorObject, "group object not allocated."); \
	return NULL;    }

#define Group_Init(obj) if(!obj->group_init || obj->group == NULL) { \
	PyErr_SetString(PyECErrorObject, "group object not initialized.");   \
	return NULL;	}

#define Point_Init(obj) if(!obj->point_init) {  	\
	printf("ERROR: element not initialized.\n");		\
	return NULL;  }

#define ElementG(a, b) a->type == G && b->type == G
#define ElementZR(a, b) a->type == ZR && b->type == ZR

void longObjToMPZ (mpz_t m, PyLongObject * p);
void setBigNum(PyLongObject *obj, BIGNUM **value);
PyObject *ECElement_new(PyTypeObject *type, PyObject *args, PyObject *kwds);
int ECElement_init(ECElement *self, PyObject *args, PyObject *kwds);
PyObject *ECElement_call(ECElement *intObject, PyObject *args, PyObject *kwds);
PyObject *ECElement_print(ECElement *self);
void	ECElement_dealloc(ECElement* self);

ECElement *negatePoint(ECElement *self);
ECElement *invertECElement(ECElement *self);
int hash_to_bytes(uint8_t *input_buf, int input_len, int hash_size, uint8_t *output_buf, uint32_t hash_num);
EC_POINT *element_from_hash(EC_GROUP *group, uint8_t *input, int input_len);

#endif
