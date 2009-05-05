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

memallocator_t memallocator;
static void initialize_allocator(void) {
    if (! memallocator.malloc) {
        memallocator.priv = NULL;
        memallocator.malloc = std_malloc;
        memallocator.free = std_free;
        memallocator.realloc = std_realloc;
        xdl_set_allocator(&memallocator);
    }
}

char* __xdiff(const char* string1, const char* string2) {
	int i = 1, ctxlen = 3, bsize = 16, do_diff, do_patch, do_bdiff, do_bpatch, do_rabdiff;
	mmfile_t mf1, mf2;
	xpparam_t xpp;
	xdemitconf_t xecfg;
	bdiffparam_t bdp;
	xdemitcb_t ecb, rjecb;

    initialize_allocator();
/*
	memallocator_t malt;
	malt.priv = NULL;
	malt.malloc = std_malloc;
	malt.free = std_free;
	malt.realloc = std_realloc;
	xdl_set_allocator(&malt);
*/

	xpp.flags = 0;
	xecfg.ctxlen = ctxlen;
	bdp.bsize = bsize;

	if (xdl_init_mmfile(&mf1, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC) < 0) {
		return "";
	}

    int got = 0;

    if ((got = xdl_write_mmfile(&mf1, string1, strlen(string1))) < strlen(string1)) {
        return "";
    }

	if (xdl_init_mmfile(&mf2, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC) < 0) {
		return "";
	}

    if ((got = xdl_write_mmfile(&mf2, string2, strlen(string2))) < strlen(string2)) {
        return "";
    }
    
    mmfile_t mfp;
    char *result;

    {
        if (xdl_init_mmfile(&mfp, MMF_STD_BLKSIZE, XDL_MMF_ATOMIC) < 0) {

            return "";
        }
        ecb.priv = &mfp;
        ecb.outf = _mmfile_outf;
/*
		ecb.priv = stderr;
		ecb.outf = _file_outf;
*/

		if (xdl_diff(&mf1, &mf2, &xpp, &xecfg, &ecb) < 0) {
			xdl_free_mmfile(&mf2);
			xdl_free_mmfile(&mf1);
		}

        got = xdl_mmfile_size(&mfp);
//    fprintf(stderr, "\t%d\n", got);

        result = malloc( sizeof(char) * (xdl_mmfile_size(&mfp))+1 );
//        got = xdl_read_mmfile( &mfp, result, xdl_mmfile_size(&mfp));

        xdl_seek_mmfile( &mfp, 0);
        got = xdl_read_mmfile( &mfp, result, got);
        result[got + 1] = 0;
        xdl_free_mmfile(&mfp);
    }

 //   fprintf(stderr, "\n\tHello, World.\n");
  //  fprintf(stderr, "\t%d\n", got);

    return result;
}

MODULE = Diff::LibXDiff PACKAGE = Diff::LibXDiff

PROTOTYPES: disable

SV*
_xdiff(string1, string2)
    SV* string1
    SV* string2
    INIT:
        char* result = NULL;
        RETVAL = &PL_sv_undef;
    CODE:
        result = __xdiff( SvPVX(string1), SvPVX(string2) );
        if (result != NULL) {
            RETVAL = newSVpv(result, 0);
            free( result );
        }
    OUTPUT:
        RETVAL
