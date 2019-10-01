target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5"
target triple = "amdgcn-amd-amdhsa"

; Function Attrs: convergent nounwind
declare void @llvm.amdgcn.s.barrier() #0

; Function Attrs: alwaysinline nounwind
define void @llvm_amdgcn_s_barrier() local_unnamed_addr #1 {
  tail call void @llvm.amdgcn.s.barrier() #0
  ret void
}

; Function Attrs: nounwind readnone
declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #2

; Function Attrs: nounwind readnone
declare i32 @llvm.amdgcn.mbcnt.hi(i32, i32) #2

; Function Attrs: convergent nounwind readnone
declare i32 @llvm.amdgcn.ds.bpermute(i32, i32) #3

; Function Attrs: alwaysinline convergent nounwind readnone
define i32 @nvvm_shfl_down_i32(i32, i32, i32) local_unnamed_addr #4 {
  %4 = tail call i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0) #2
  %5 = tail call i32 @llvm.amdgcn.mbcnt.hi(i32 -1, i32 %4) #2
  %6 = srem i32 %5, 64
  %7 = add nsw i32 %2, -1
  %8 = and i32 %6, %7
  %9 = add i32 %8, %1
  %10 = icmp ult i32 %9, %2
  %11 = select i1 %10, i32 %1, i32 0
  %12 = add i32 %11, %6
  %13 = shl i32 %12, 2
  %14 = tail call i32 @llvm.amdgcn.ds.bpermute(i32 %13, i32 %0) #4
  ret i32 %14
}

attributes #0 = { convergent nounwind }
attributes #1 = { alwaysinline nounwind }
attributes #2 = { nounwind readnone }
attributes #3 = { convergent nounwind readnone }
attributes #4 = { alwaysinline convergent nounwind readnone }
