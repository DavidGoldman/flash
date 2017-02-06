#define kPrefsBundlePath @"/Library/PreferenceBundles/Flash.bundle"

#if CGFLOAT_IS_DOUBLE
#define CG_FLOAT_ROUND(a) round(a)
#else
#define CG_FLOAT_ROUND(a) roundf(a)
#endif
