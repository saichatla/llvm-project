; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -passes=instcombine < %s | FileCheck %s

declare double @llvm.pow.f64(double, double)
declare void @use(double)

; negative test for:
; pow(a,b) * a --> pow(a, b+1) (requires reassoc)

define double @pow_ab_a(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_a(
; CHECK-NEXT:    [[P:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fmul double [[P]], [[A]]
; CHECK-NEXT:    ret double [[M]]
;
  %p = call double @llvm.pow.f64(double %a, double %b)
  %m = fmul double %p, %a
  ret double %m
}

; pow(a,b) * a --> pow(a, b+1)

define double @pow_ab_a_reassoc(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_a_reassoc(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[B:%.*]], 1.000000e+00
; CHECK-NEXT:    [[M:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[TMP1]])
; CHECK-NEXT:    ret double [[M]]
;
  %p = call double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %p, %a
  ret double %m
}

; a * pow(a,b) --> pow(a, b+1)

define double @pow_ab_a_reassoc_commute(double %pa, double %b)  {
; CHECK-LABEL: @pow_ab_a_reassoc_commute(
; CHECK-NEXT:    [[A:%.*]] = fadd double [[PA:%.*]], 4.200000e+01
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[B:%.*]], 1.000000e+00
; CHECK-NEXT:    [[M:%.*]] = call reassoc double @llvm.pow.f64(double [[A]], double [[TMP1]])
; CHECK-NEXT:    ret double [[M]]
;
  %a = fadd double %pa, 42.0 ; thwart complexity-based canonicalization
  %p = call double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %a, %p
  ret double %m
}

; negative test - extra uses not allowed

define double @pow_ab_a_reassoc_use(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_a_reassoc_use(
; CHECK-NEXT:    [[P:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fmul reassoc double [[P]], [[A]]
; CHECK-NEXT:    call void @use(double [[P]])
; CHECK-NEXT:    ret double [[M]]
;
  %p = call double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %p, %a
  call void @use(double %p)
  ret double %m
}

; negative test for:
; pow(a,b) * 1.0/a --> pow(a, b-1) (requires reassoc)

define double @pow_ab_recip_a(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a(
; CHECK-NEXT:    [[R:%.*]] = fdiv double 1.000000e+00, [[A:%.*]]
; CHECK-NEXT:    [[P:%.*]] = call double @llvm.pow.f64(double [[A]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fmul double [[R]], [[P]]
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv double 1.0, %a
  %p = call double @llvm.pow.f64(double %a, double %b)
  %m = fmul double %r, %p
  ret double %m
}

; pow(a,b) / a --> pow(a, b-1) (requires reassoc)

define double @pow_ab_recip_a_reassoc(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a_reassoc(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[B:%.*]], -1.000000e+00
; CHECK-NEXT:    [[M:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[TMP1]])
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv reassoc double 1.0, %a
  %p = call reassoc double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %r, %p
  ret double %m
}

; pow(a,b) / a --> pow(a, b-1) (requires reassoc)

define double @pow_ab_recip_a_reassoc_commute(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a_reassoc_commute(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[B:%.*]], -1.000000e+00
; CHECK-NEXT:    [[M:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[TMP1]])
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv reassoc double 1.0, %a
  %p = call reassoc double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %p, %r
  ret double %m
}

; TODO: extra use prevents conversion to fmul, so this needs a different pattern match.

define double @pow_ab_recip_a_reassoc_use1(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a_reassoc_use1(
; CHECK-NEXT:    [[R:%.*]] = fdiv reassoc double 1.000000e+00, [[A:%.*]]
; CHECK-NEXT:    [[P:%.*]] = call reassoc double @llvm.pow.f64(double [[A]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fmul reassoc double [[R]], [[P]]
; CHECK-NEXT:    call void @use(double [[R]])
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv reassoc double 1.0, %a
  %p = call reassoc double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %r, %p
  call void @use(double %r)
  ret double %m
}

; negative test - extra pow uses not allowed

define double @pow_ab_recip_a_reassoc_use2(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a_reassoc_use2(
; CHECK-NEXT:    [[P:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fdiv reassoc double [[P]], [[A]]
; CHECK-NEXT:    call void @use(double [[P]])
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv reassoc double 1.0, %a
  %p = call reassoc double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %r, %p
  call void @use(double %p)
  ret double %m
}

; negative test - extra pow uses not allowed

define double @pow_ab_recip_a_reassoc_use3(double %a, double %b)  {
; CHECK-LABEL: @pow_ab_recip_a_reassoc_use3(
; CHECK-NEXT:    [[R:%.*]] = fdiv reassoc double 1.000000e+00, [[A:%.*]]
; CHECK-NEXT:    [[P:%.*]] = call reassoc double @llvm.pow.f64(double [[A]], double [[B:%.*]])
; CHECK-NEXT:    [[M:%.*]] = fmul reassoc double [[R]], [[P]]
; CHECK-NEXT:    call void @use(double [[R]])
; CHECK-NEXT:    call void @use(double [[P]])
; CHECK-NEXT:    ret double [[M]]
;
  %r = fdiv reassoc double 1.0, %a
  %p = call reassoc double @llvm.pow.f64(double %a, double %b)
  %m = fmul reassoc double %r, %p
  call void @use(double %r)
  call void @use(double %p)
  ret double %m
}

; negative test for:
; (a**b) * (c**b) --> (a*c) ** b (if mul is reassoc)

define double @pow_ab_pow_cb(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_cb(
; CHECK-NEXT:    [[TMP1:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP2:%.*]] = call double @llvm.pow.f64(double [[C:%.*]], double [[B]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul double [[TMP2]], [[TMP1]]
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %c, double %b)
  %mul = fmul double %2, %1
  ret double %mul
}

; (a**b) * (c**b) --> (a*c) ** b

define double @pow_ab_pow_cb_reassoc(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_cb_reassoc(
; CHECK-NEXT:    [[TMP1:%.*]] = fmul reassoc double [[C:%.*]], [[A:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[TMP1]], double [[B:%.*]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %c, double %b)
  %mul = fmul reassoc double %2, %1
  ret double %mul
}

; (a**b) * (c**b) --> (a*c) ** b

define double @pow_ab_pow_cb_reassoc_use1(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_cb_reassoc_use1(
; CHECK-NEXT:    [[AB:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul reassoc double [[A]], [[C:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[TMP1]], double [[B]])
; CHECK-NEXT:    call void @use(double [[AB]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %ab = call double @llvm.pow.f64(double %a, double %b)
  %cb = call double @llvm.pow.f64(double %c, double %b)
  %mul = fmul reassoc double %ab, %cb
  call void @use(double %ab)
  ret double %mul
}

; (a**b) * (c**b) --> (a*c) ** b

define double @pow_ab_pow_cb_reassoc_use2(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_cb_reassoc_use2(
; CHECK-NEXT:    [[CB:%.*]] = call double @llvm.pow.f64(double [[C:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP1:%.*]] = fmul reassoc double [[A:%.*]], [[C]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[TMP1]], double [[B]])
; CHECK-NEXT:    call void @use(double [[CB]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %ab = call double @llvm.pow.f64(double %a, double %b)
  %cb = call double @llvm.pow.f64(double %c, double %b)
  %mul = fmul reassoc double %ab, %cb
  call void @use(double %cb)
  ret double %mul
}

; negative test - too many extra uses

define double @pow_ab_pow_cb_reassoc_use3(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_cb_reassoc_use3(
; CHECK-NEXT:    [[AB:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[CB:%.*]] = call double @llvm.pow.f64(double [[C:%.*]], double [[B]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul reassoc double [[AB]], [[CB]]
; CHECK-NEXT:    call void @use(double [[AB]])
; CHECK-NEXT:    call void @use(double [[CB]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %ab = call double @llvm.pow.f64(double %a, double %b)
  %cb = call double @llvm.pow.f64(double %c, double %b)
  %mul = fmul reassoc double %ab, %cb
  call void @use(double %ab)
  call void @use(double %cb)
  ret double %mul
}

define double @pow_ab_pow_ac(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_pow_ac(
; CHECK-NEXT:    [[TMP1:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP2:%.*]] = call double @llvm.pow.f64(double [[A]], double [[C:%.*]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul double [[TMP2]], [[TMP1]]
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %a, double %c)
  %mul = fmul double %2, %1
  ret double %mul
}

define double @pow_ab_x_pow_ac_reassoc(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_x_pow_ac_reassoc(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[C:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[TMP1]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %a, double %c)
  %mul = fmul reassoc double %2, %1
  ret double %mul
}

define double @pow_ab_reassoc(double %a, double %b) {
; CHECK-LABEL: @pow_ab_reassoc(
; CHECK-NEXT:    [[TMP1:%.*]] = fadd reassoc double [[B:%.*]], [[B]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[A:%.*]], double [[TMP1]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %mul = fmul reassoc double %1, %1
  ret double %mul
}

define double @pow_ab_reassoc_extra_use(double %a, double %b) {
; CHECK-LABEL: @pow_ab_reassoc_extra_use(
; CHECK-NEXT:    [[TMP1:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul reassoc double [[TMP1]], [[TMP1]]
; CHECK-NEXT:    call void @use(double [[TMP1]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %mul = fmul reassoc double %1, %1
  call void @use(double %1)
  ret double %mul
}

define double @pow_ab_x_pow_ac_reassoc_extra_use(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_x_pow_ac_reassoc_extra_use(
; CHECK-NEXT:    [[TMP1:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP2:%.*]] = fadd reassoc double [[B]], [[C:%.*]]
; CHECK-NEXT:    [[MUL:%.*]] = call reassoc double @llvm.pow.f64(double [[A]], double [[TMP2]])
; CHECK-NEXT:    call void @use(double [[TMP1]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %a, double %c)
  %mul = fmul reassoc double %1, %2
  call void @use(double %1)
  ret double %mul
}

define double @pow_ab_x_pow_ac_reassoc_multiple_uses(double %a, double %b, double %c) {
; CHECK-LABEL: @pow_ab_x_pow_ac_reassoc_multiple_uses(
; CHECK-NEXT:    [[TMP1:%.*]] = call double @llvm.pow.f64(double [[A:%.*]], double [[B:%.*]])
; CHECK-NEXT:    [[TMP2:%.*]] = call double @llvm.pow.f64(double [[A]], double [[C:%.*]])
; CHECK-NEXT:    [[MUL:%.*]] = fmul reassoc double [[TMP1]], [[TMP2]]
; CHECK-NEXT:    call void @use(double [[TMP1]])
; CHECK-NEXT:    call void @use(double [[TMP2]])
; CHECK-NEXT:    ret double [[MUL]]
;
  %1 = call double @llvm.pow.f64(double %a, double %b)
  %2 = call double @llvm.pow.f64(double %a, double %c)
  %mul = fmul reassoc double %1, %2
  call void @use(double %1)
  call void @use(double %2)
  ret double %mul
}
