package main

/*
#include <stdlib.h>
*/
import "C"

import "unsafe"

// GoSum adds two integers. Proves argument/return round-trip through FFI.
//
//export GoSum
func GoSum(a, b C.int) C.int {
	return a + b
}

// GoGreeting returns a C string allocated by the Go runtime's malloc.
// The caller must release it with GoFree.
//
//export GoGreeting
func GoGreeting() *C.char {
	return C.CString("Hello from Go on OpenHarmony!")
}

// GoFree releases memory returned by GoGreeting.
//
//export GoFree
func GoFree(p unsafe.Pointer) {
	C.free(p)
}

func main() {}
