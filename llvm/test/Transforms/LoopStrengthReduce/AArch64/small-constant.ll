; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py

; RUN: llc < %s -mtriple=aarch64-unknown-unknown | FileCheck %s

; Test LSR for giving small constants, which get re-associated as unfolded
; offset, a chance to get combined with loop-invariant registers (same as
; large constants which do not fit as add immediate operands). LSR
; favors here to bump the base pointer outside the loop.

; float test(float *arr, long long start, float threshold) {
;   for (long long i = start; i != 0; ++i) {
;     float x = arr[i + 7];
;     if (x > threshold)
;       return x;
;   }
;   return -7;
; }
define float @test1(float* nocapture readonly %arr, i64 %start, float %threshold) {
; CHECK-LABEL: test1:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    fmov s2, #-7.00000000
; CHECK-NEXT:    cbz x1, .LBB0_4
; CHECK-NEXT:  // %bb.1: // %for.body.preheader
; CHECK-NEXT:    add x8, x0, #28 // =28
; CHECK-NEXT:  .LBB0_2: // %for.body
; CHECK-NEXT:    // =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    ldr s1, [x8, x1, lsl #2]
; CHECK-NEXT:    fcmp s1, s0
; CHECK-NEXT:    b.gt .LBB0_5
; CHECK-NEXT:  // %bb.3: // %for.cond
; CHECK-NEXT:    // in Loop: Header=BB0_2 Depth=1
; CHECK-NEXT:    add x1, x1, #1 // =1
; CHECK-NEXT:    cbnz x1, .LBB0_2
; CHECK-NEXT:  .LBB0_4:
; CHECK-NEXT:    mov v0.16b, v2.16b
; CHECK-NEXT:    ret
; CHECK-NEXT:  .LBB0_5: // %cleanup2
; CHECK-NEXT:    mov v0.16b, v1.16b
; CHECK-NEXT:    ret
entry:
  %cmp11 = icmp eq i64 %start, 0
  br i1 %cmp11, label %cleanup2, label %for.body

for.cond:                                         ; preds = %for.body
  %cmp = icmp eq i64 %inc, 0
  br i1 %cmp, label %cleanup2, label %for.body

for.body:                                         ; preds = %entry, %for.cond
  %i.012 = phi i64 [ %inc, %for.cond ], [ %start, %entry ]
  %add = add nsw i64 %i.012, 7
  %arrayidx = getelementptr inbounds float, float* %arr, i64 %add
  %0 = load float, float* %arrayidx, align 4
  %cmp1 = fcmp ogt float %0, %threshold
  %inc = add nsw i64 %i.012, 1
  br i1 %cmp1, label %cleanup2, label %for.cond

cleanup2:                                         ; preds = %for.cond, %for.body, %entry
  %1 = phi float [ -7.000000e+00, %entry ], [ %0, %for.body ], [ -7.000000e+00, %for.cond ]
  ret float %1
}

; Same as test1, except i has another use:
;     if (x > threshold) ---> if (x > threshold + i)
define float @test2(float* nocapture readonly %arr, i64 %start, float %threshold) {
; CHECK-LABEL: test2:
; CHECK:       // %bb.0: // %entry
; CHECK-NEXT:    fmov s2, #-7.00000000
; CHECK-NEXT:    cbz x1, .LBB1_4
; CHECK-NEXT:  // %bb.1: // %for.body.preheader
; CHECK-NEXT:    add x8, x0, #28 // =28
; CHECK-NEXT:  .LBB1_2: // %for.body
; CHECK-NEXT:    // =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    ldr s1, [x8, x1, lsl #2]
; CHECK-NEXT:    scvtf s3, x1
; CHECK-NEXT:    fadd s3, s3, s0
; CHECK-NEXT:    fcmp s1, s3
; CHECK-NEXT:    b.gt .LBB1_5
; CHECK-NEXT:  // %bb.3: // %for.cond
; CHECK-NEXT:    // in Loop: Header=BB1_2 Depth=1
; CHECK-NEXT:    add x1, x1, #1 // =1
; CHECK-NEXT:    cbnz x1, .LBB1_2
; CHECK-NEXT:  .LBB1_4:
; CHECK-NEXT:    mov v0.16b, v2.16b
; CHECK-NEXT:    ret
; CHECK-NEXT:  .LBB1_5: // %cleanup4
; CHECK-NEXT:    mov v0.16b, v1.16b
; CHECK-NEXT:    ret
entry:
  %cmp14 = icmp eq i64 %start, 0
  br i1 %cmp14, label %cleanup4, label %for.body

for.cond:                                         ; preds = %for.body
  %cmp = icmp eq i64 %inc, 0
  br i1 %cmp, label %cleanup4, label %for.body

for.body:                                         ; preds = %entry, %for.cond
  %i.015 = phi i64 [ %inc, %for.cond ], [ %start, %entry ]
  %add = add nsw i64 %i.015, 7
  %arrayidx = getelementptr inbounds float, float* %arr, i64 %add
  %0 = load float, float* %arrayidx, align 4
  %conv = sitofp i64 %i.015 to float
  %add1 = fadd float %conv, %threshold
  %cmp2 = fcmp ogt float %0, %add1
  %inc = add nsw i64 %i.015, 1
  br i1 %cmp2, label %cleanup4, label %for.cond

cleanup4:                                         ; preds = %for.cond, %for.body, %entry
  %1 = phi float [ -7.000000e+00, %entry ], [ %0, %for.body ], [ -7.000000e+00, %for.cond ]
  ret float %1
}
