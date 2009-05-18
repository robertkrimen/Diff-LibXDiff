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

#define CONTEXT_string_result(AT) (context->string_result[AT])
#define CONTEXT_mmf(AT) (context->mmf[AT])
#define CONTEXT_mmf_result(AT) (context->mmf_result[AT])
#define CONTEXT_add_error(ERROR) context->error[++context->error_counter - 1] = ERROR;

#define CONTEXT_error_size 3
#define CONTEXT_string_result_size 2
#define CONTEXT_mmf_size 3
#define CONTEXT_mmf_result_size 2

typedef struct {
    char *string_result[CONTEXT_string_result_size];
	mmfile_t mmf[CONTEXT_mmf_size];
	mmfile_t mmf_result[2];
    const char *error[CONTEXT_error_size];
    int error_counter;
} context_t;
context_t result;

static int CONTEXT_mmf_result_2_string_result( context_t* context, int index ) {

    mmfile_t *mmf_r1 = &CONTEXT_mmf_result(index);
    int size = xdl_mmfile_size( mmf_r1 );
    int wrote = 0;
    char *string_result = CONTEXT_string_result(index) = malloc( sizeof(char) * (size + 1) );

    xdl_seek_mmfile( mmf_r1, 0);
    if ( (wrote = xdl_read_mmfile( mmf_r1, string_result, size )) < size ) {
        return size - wrote;
    }
    string_result[size] = 0;
    return 0;
}

static void CONTEXT_cleanup( context_t* context ) {
    int ii;

    for (ii = 0; ii < CONTEXT_string_result_size; ii++)
        free( context->string_result[ ii ] );

    for (ii = 0; ii < CONTEXT_mmf_size; ii++)
        xdl_free_mmfile( &( context->mmf[ ii ] ) );

    for (ii = 0; ii < CONTEXT_mmf_result_size; ii++)
        xdl_free_mmfile( &( context->mmf_result[ ii ] ) );
}

/*
static void initialize_result( context_t* result ) {
    int ii;
    result->stringr = 0;
    for (ii = 0; ii < CONTEXT_error_size; ii++)
        result->error[ii] = 0;
    result->error_counter = -1;
}
*/

static const char* _string_2_mmfile( mmfile_t* mmf, const char* string ) {

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

/*
	} else if (do_patch) {
		ecb.priv = stdout;
		ecb.outf = xdlt_outf;
		rjecb.priv = stderr;
		rjecb.outf = xdlt_outf;
		if (xdl_patch(&mf1, &mf2, XDL_PATCH_NORMAL, &ecb, &rjecb) < 0) {

			xdl_free_mmfile(&mf2);
			xdl_free_mmfile(&mf1);
			return 6;
		}
	}
*/

void __xpatch( context_t *context, const char *string1, const char *string2 ) {

	mmfile_t *mmf1, *mmf2, *mmf_r1, *mmf_r2;
    const char *error;

    mmf1 = &CONTEXT_mmf(0);
    mmf2 = &CONTEXT_mmf(1);
    mmf_r1 = &CONTEXT_mmf_result(0);
    mmf_r2 = &CONTEXT_mmf_result(1);

    initialize_allocator();

    if ( error = _string_2_mmfile( mmf1, string1 ) ) {
        CONTEXT_add_error( error );
        CONTEXT_add_error( "Couldn't load string1 into mmfile" );
        return;
    }

    if ( error = _string_2_mmfile( mmf2, string2 ) ) {
        CONTEXT_add_error( error );
        CONTEXT_add_error( "Couldn't load string2 into mmfile" );
        return;
    }
    
    {
        xdemitcb_t ecb1, ecb2;

        ecb1.priv = mmf_r1;
        ecb1.outf = _mmfile_outf;

        ecb2.priv = mmf_r2;
        ecb2.outf = _mmfile_outf;

        if (xdl_init_mmfile( mmf_r1, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            CONTEXT_add_error( "Couldn't initialize accumulating mmfile mmf_r1  (xdl_init_atomic)" );
            return;
        }

        if (xdl_init_mmfile( mmf_r2, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            CONTEXT_add_error( "Couldn't initialize accumulating mmfile mmf_r2  (xdl_init_atomic)" );
            return;
        }

		if (xdl_patch( mmf1, mmf2, XDL_PATCH_NORMAL, &ecb1, &ecb2) < 0) {
            CONTEXT_add_error( "Couldn't perform patch (xdl_patch)" );
            return;
		}

        if ( CONTEXT_mmf_result_2_string_result( context, 0 ) ) {
            CONTEXT_add_error( "Wasn't able to read entire mmfile result (mmf_r1) (xdl_read_mmfile)" );
        }

        if ( CONTEXT_mmf_result_2_string_result( context, 1 ) ) {
            CONTEXT_add_error( "Wasn't able to read entire mmfile result (mmf_r2) (xdl_read_mmfile)" );
        }
    }
}

/*
context_t* __xpatch( const char* string1, const char* string2 ) {

	mmfile_t mmf1, mmf2;

    initialize_allocator();
    initialize_result( &result );

    if ( error = _string_2_mmfile( &mmf1, string1 ) ) {
        result.error[++result.error_counter] = error;
        result.error[++result.error_counter] = "Couldn't load string1 into mmfile";
        return &result;
    }

    if ( error = _string_2_mmfile( &mmf2, string2 ) ) {
        xdl_free_mmfile( &mmf1 );
        result.error[++result.error_counter] = error;
        result.error[++result.error_counter] = "Couldn't load string2 into mmfile";
        return &result;
    }
    

    {
	    mmfile_t mmf_r1, mmf_r2;
        xdemitcb_t ecb1, ecb2;

        ecb1.priv = &mmf_r1;
        ecb1.outf = _mmfile_outf;

        ecb2.priv = &mmf_r2;
        ecb2.outf = _mmfile_outf;

        if (xdl_init_mmfile( &mmf_r1, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            result.error[++result.error_counter] = "Couldn't initialize first accumulating mmfile (xdl_init_atomic)";
			xdl_free_mmfile( &mmf2 );
			xdl_free_mmfile( &mmf1 );
            return &result;
        }

        if (xdl_init_mmfile( &mmf_r2, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            result.error[++result.error_counter] = "Couldn't initialize second accumulating mmfile (xdl_init_atomic)";
			xdl_free_mmfile( &mmf_r1 );
			xdl_free_mmfile( &mmf2 );
			xdl_free_mmfile( &mmf1 );
            return &result;
        }

		if (xdl_patch( &mmf1, &mmf2, XDL_PATCH_NORMAL, &ecb1, &ecb2 ) < 0) {
			xdl_free_mmfile( &mmf_r2 );
			xdl_free_mmfile( &mmf_r1 );
			xdl_free_mmfile( &mmf2 );
			xdl_free_mmfile( &mmf1 );
            result.error[++result.error_counter] = "Couldn't perform patch (xdl_patch)";
            return &result;
		}

        {
            int size = xdl_mmfile_size( &mmf_r1 );

            string_r1 = malloc( sizeof(char) * (size + 1) );

            xdl_seek_mmfile( &mmf_r1, 0);
            if ( (wrote = xdl_read_mmfile( &mmf_r1, string_r1, size )) < size ) {
                xdl_free_mmfile( &mmf_r1 );
                result.error[++result.error_counter] = "Wasn't able to read (first) entire mmfile result (xdl_read_mmfile)";
                return &result;
            }
            stringr[size] = 0;
            xdl_free_mmfile( &mmf_r1 );
        }

    }

}
*/

void __xdiff( context_t *context, const char *string1, const char *string2 ) {

	mmfile_t *mmf1, *mmf2, *mmf_r1;
    const char *error;

    mmf1 = &CONTEXT_mmf(0);
    mmf2 = &CONTEXT_mmf(1);
    mmf_r1 = &CONTEXT_mmf_result(0);

    initialize_allocator();

    if ( error = _string_2_mmfile( mmf1, string1 ) ) {
        CONTEXT_add_error( error );
        CONTEXT_add_error( "Couldn't load string1 into mmfile" );
        return;
    }

    if ( error = _string_2_mmfile( mmf2, string2 ) ) {
        CONTEXT_add_error( error );
        CONTEXT_add_error( "Couldn't load string2 into mmfile" );
        return;
    }
    
    {
        xpparam_t xpp;
	    xpp.flags = 0;

        xdemitconf_t xecfg;
	    xecfg.ctxlen = 3;

        xdemitcb_t ecb;
        ecb.priv = mmf_r1;
        ecb.outf = _mmfile_outf;

        if (xdl_init_mmfile( mmf_r1, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC ) < 0) {
            CONTEXT_add_error( "Couldn't initialize accumulating mmfile (xdl_init_atomic)" );
            return;
        }

		if (xdl_diff( mmf1, mmf2, &xpp, &xecfg, &ecb ) < 0) {
            CONTEXT_add_error( "Couldn't perform diff (xdl_diff)" );
            return;
		}

        if ( CONTEXT_mmf_result_2_string_result( context, 0 ) ) {
            CONTEXT_add_error( "Wasn't able to read entire mmfile result (xdl_read_mmfile)" );
        }
    }
}

MODULE = Diff::LibXDiff PACKAGE = Diff::LibXDiff

PROTOTYPES: disable

SV*
_xdiff(string1, string2)
    SV* string1
    SV* string2
    INIT:
        context_t context = { 0 };
        RETVAL = &PL_sv_undef;
    CODE:
        __xdiff( &context, SvPVX(string1), SvPVX(string2) );
        HV* hash_result = (HV*) sv_2mortal( (SV*) newHV() );
        AV* error_result = (AV*) sv_2mortal( (SV*) newAV() );
        int ii;
        for (ii = 0; ii < context.error_counter; ii++) {
            av_push( error_result, newSVpv( context.error[ii], 0 ) );
        }
        hv_store(  hash_result, "result", 6, newSVpv( context.string_result[0], 0 ), 0);
        hv_store(  hash_result, "error", 5, newRV( (SV*) error_result ), 0);
        CONTEXT_cleanup( &context );
        RETVAL = newRV( (SV*) hash_result );
    OUTPUT:
        RETVAL

SV*
_xpatch(string1, string2)
    SV* string1
    SV* string2
    INIT:
        context_t context = { 0 };
        RETVAL = &PL_sv_undef;
    CODE:
        __xpatch( &context, SvPVX(string1), SvPVX(string2) );
        HV* hash_result = (HV*) sv_2mortal( (SV*) newHV() );
        AV* error_result = (AV*) sv_2mortal( (SV*) newAV() );
        int ii;
        for (ii = 0; ii < context.error_counter; ii++) {
            av_push( error_result, newSVpv( context.error[ii], 0 ) );
        }
        hv_store(  hash_result, "result", 6, newSVpv( context.string_result[0], 0 ), 0);
        hv_store(  hash_result, "rejected_result", 15, newSVpv( context.string_result[1], 0 ), 0);
        hv_store(  hash_result, "error", 5, newRV( (SV*) error_result ), 0);
        CONTEXT_cleanup( &context );
        RETVAL = newRV( (SV*) hash_result );
    OUTPUT:
        RETVAL
