#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "xs_object_magic.h"

STATIC MGVTBL null_mg_vtbl = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
    NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
    NULL, /* local */
#endif /* MGf_LOCAL */
};

void xs_object_magic_attach_struct (pTHX_ SV *sv, void *ptr) {
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0 );
}

SV *xs_object_magic_create (pTHX_ void *ptr, HV *stash) {
	HV *hv = newHV();
	SV *obj = newRV_noinc((SV *)hv);

	sv_bless(obj, stash);

	xs_object_magic_attach_struct(aTHX_ (SV *)hv, ptr);

	return obj;
}

STATIC MAGIC *xs_object_magic_get_mg (pTHX_ SV *sv) {
    MAGIC *mg;

    if (SvTYPE(sv) >= SVt_PVMG) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
			if (
				(mg->mg_type == PERL_MAGIC_ext)
					&&
				(mg->mg_virtual == &null_mg_vtbl)
			) {
				return mg;
			}
        }
    }

    return NULL;
}

void *xs_object_magic_get_struct (pTHX_ SV *sv) {
	MAGIC *mg = xs_object_magic_get_mg(aTHX_ sv);

	if ( mg )
		return mg->mg_ptr;
	else
		return NULL;
}

void *xs_object_magic_get_struct_rv_pretty (pTHX_ SV *sv, const char *name) {
	if ( sv && SvROK(sv) ) {
		MAGIC *mg = xs_object_magic_get_mg(aTHX_ SvRV(sv));

		if ( mg )
			return mg->mg_ptr;
		else
			croak("%s does not have a struct associated with it", name);
	} else {
		croak("%s is not a reference", name);
	}
}

void *xs_object_magic_get_struct_rv (pTHX_ SV *sv) {
	return xs_object_magic_get_struct_rv_pretty(aTHX_ sv, "argument");
}





typedef struct {
	I32 i;
} _xs_magic_object_test_t;

static I32 destroyed = 0;

static _xs_magic_object_test_t *test_new () {
	_xs_magic_object_test_t *t;
	Newx(t, 1, _xs_magic_object_test_t);
	t->i = 0;
	return t;
}

static int test_count (_xs_magic_object_test_t *t) {
	return ++t->i;
}

static int test_DESTROY (_xs_magic_object_test_t *t) {
	Safefree(t);
	destroyed++;
}


MODULE = XS::Object::Magic	PACKAGE = XS::Object::Magic::Test	PREFIX = test_
PROTOTYPES: DISABLE

SV *
new(char *class)
	CODE:
		RETVAL = xs_object_magic_create((void *)test_new(), gv_stashpv(class, 0));
	OUTPUT: RETVAL

I32
test_count (self)
	_xs_magic_object_test_t *self;

void
test_DESTROY (self)
	_xs_magic_object_test_t *self;

I32
destroyed ()
	CODE:
		RETVAL = destroyed;
	OUTPUT: RETVAL
