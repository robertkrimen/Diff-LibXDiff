#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>
#include "xdiff.h"

/* This value taken from libxdiff-0.23/test/xtestutils.c */
#define MMF_STD_BLKSIZE (1024 * 8)

static void *std_malloc(void *priv, unsigned int size) {
	return malloc(size);
}

static void std_free(void *priv, void *ptr) {
	free(ptr);
}

static void *std_realloc(void *priv, void *ptr, unsigned int size) {
	return realloc(ptr, size);
}

static int _file_outf(void *priv, mmbuffer_t *mb, int nbuf) {
	int i;
	for (i = 0; i < nbuf; i++)
		if (!fwrite(mb[i].ptr, mb[i].size, 1, (FILE *) priv))
			return -1;
	return 0;
}

static int _mmfile_outf(void *priv, mmbuffer_t *mb, int nbuf) {
	mmfile_t *mmf = priv;
	if (xdl_writem_mmfile(mmf, mb, nbuf) < 0) {
		return -1;
	}
	return 0;
}

memallocator_t memallocator = { malloc, 0 }; /* Paranoid... */

static void initialize_allocator(void) {
    if (! memallocator.malloc) {
        memallocator.priv = NULL;
        memallocator.malloc = std_malloc;
        memallocator.free = std_free;
        memallocator.realloc = std_realloc;
        xdl_set_allocator(&memallocator);
    }
}

#define RESULT_T_ERROR_SIZE 3
typedef struct {
    char* stringr;
    const char* error[RESULT_T_ERROR_SIZE];
    int errorp;
} result_t;
result_t result;

static void initialize_result( result_t* result ) {
    int ii;
    result->stringr = 0;
    for (ii = 0; ii < RESULT_T_ERROR_SIZE; ii++)
        result->error[ii] = 0;
    result->errorp = -1;
}

static const char* _string_into_mmfile( mmfile_t* mmf, const char* string ) {

    initialize_allocator();

	if ( xdl_init_mmfile( mmf, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0 ) {
		return "Unable to initialize mmfile";
	}

    int wrote = 0;
    int length = strlen(string);
    if ( (wrote = xdl_write_mmfile( mmf, string, length )) < length ) {
        return "Couldn't write entire string to mmfile";
    }

    return 0;
}

result_t* __xdiff(const char* string1, const char* string2) {
	mmfile_t mmf1, mmf2, mmfr;
    const char* error;
    char *stringr;

    initialize_allocator();
    initialize_result( &result );

    if ( error = _string_into_mmfile( &mmf1, string1 ) ) {
        result.error[++result.errorp] = error;
        result.error[++result.errorp] = "Couldn't load string1 into mmfile";
        return &result;
    }

    if ( error = _string_into_mmfile( &mmf2, string2 ) ) {
        xdl_free_mmfile( &mmf1 );
        result.error[++result.errorp] = error;
        result.error[++result.errorp] = "Couldn't load string2 into mmfile";
        return &result;
    }
    
    {
        int size, wrote;
        xpparam_t xpp;
        xdemitconf_t xecfg;
        xdemitcb_t ecb;

	    xpp.flags = 0;

	    xecfg.ctxlen = 3;

        ecb.priv = &mmfr;
        ecb.outf = _mmfile_outf;
        if (xdl_init_mmfile( &mmfr, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            result.error[++result.errorp] = "Couldn't initialize accumulating mmfile (xdl_init_atomic)";
			xdl_free_mmfile( &mmf2 );
			xdl_free_mmfile( &mmf1 );
            return &result;
        }

		if (xdl_diff( &mmf1, &mmf2, &xpp, &xecfg, &ecb ) < 0) {
			xdl_free_mmfile( &mmf2 );
			xdl_free_mmfile( &mmf1 );
            result.error[++result.errorp] = "Couldn't perform diff (xdl_diff)";
            return &result;
		}

        size = xdl_mmfile_size( &mmfr );

        stringr = malloc( sizeof(char) * (size + 1) );

        xdl_seek_mmfile( &mmfr, 0);
        if ( (wrote = xdl_read_mmfile( &mmfr, stringr, size )) < size ) {
            xdl_free_mmfile( &mmfr );
            result.error[++result.errorp] = "Wasn't able to read entire mmfile result (xdl_read_mmfile)";
            return &result;
        }
        stringr[size] = 0;
        xdl_free_mmfile( &mmfr );
    }

    result.stringr = stringr;
    return &result;
}

MODULE = Diff::LibXDiff PACKAGE = Diff::LibXDiff

PROTOTYPES: disable

SV*
_xdiff(string1, string2)
    SV* string1
    SV* string2
    INIT:
        result_t* result = NULL;
        RETVAL = &PL_sv_undef;
    CODE:
        result = __xdiff( SvPVX(string1), SvPVX(string2) );
        if (result != NULL && result->stringr) {
            /* Liberally taken from perlxs... hope nothing is leaking */
            HV* hashr = (HV*) sv_2mortal( (SV*) newHV() );
            AV* errorr = (AV*) sv_2mortal( (SV*) newAV() );
            int ii;
            for (ii = 0; ii <= result->errorp; ii++) {
                av_push( errorr, newSVpv( result->error[ii], 0 ) );
                result->error[ii];
            }
            hv_store(  hashr, "stringr", 7, newSVpv( result->stringr, 0 ), 0);
            hv_store(  hashr, "error", 5, newRV( (SV*) errorr ), 0);
            free( result->stringr );
            RETVAL = newRV( (SV*) hashr );
        }
    OUTPUT:
        RETVAL
