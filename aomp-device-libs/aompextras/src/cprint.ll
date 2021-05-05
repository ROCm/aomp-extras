; ModuleID = 'cprint-openmp-amdgcn-amd-amdhsa-gfx906.tmp.bc'
source_filename = "cprint.c"
target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7"
target triple = "amdgcn-amd-amdhsa"

@.str.1 = private unnamed_addr addrspace(4) constant [7 x i8] c"%s %d\0A\00", align 1
@.str.3 = private unnamed_addr addrspace(4) constant [7 x i8] c"%s %f\0A\00", align 1
@.str.4 = private unnamed_addr addrspace(4) constant [7 x i8] c"%s %g\0A\00", align 1

; Function Attrs: alwaysinline norecurse nounwind
define void @f90print_(i8* %s) local_unnamed_addr #0 {
entry:
  %0 = tail call i32 @__strlen_max(i8* %s, i32 1024) #2
  %total_buffer_size = add i32 %0, 28
  %1 = tail call i8* @printf_allocate(i32 %total_buffer_size) #2
  %2 = bitcast i8* %1 to i32*
  %3 = addrspacecast i32* %2 to i32 addrspace(1)*
  store i32 24, i32 addrspace(1)* %3, align 4
  %4 = getelementptr inbounds i8, i8* %1, i64 4
  %5 = bitcast i8* %4 to i32*
  %6 = addrspacecast i32* %5 to i32 addrspace(1)*
  store i32 2, i32 addrspace(1)* %6, align 4
  %7 = getelementptr inbounds i8, i8* %1, i64 8
  %8 = bitcast i8* %7 to i32*
  %9 = addrspacecast i32* %8 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %9, align 4
  %10 = getelementptr inbounds i8, i8* %1, i64 12
  %11 = bitcast i8* %10 to i32*
  %12 = addrspacecast i32* %11 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %12, align 4
  %13 = getelementptr inbounds i8, i8* %1, i64 16
  %14 = bitcast i8* %13 to i32*
  %15 = addrspacecast i32* %14 to i32 addrspace(1)*
  store i32 4, i32 addrspace(1)* %15, align 4
  %16 = getelementptr inbounds i8, i8* %1, i64 20
  %17 = bitcast i8* %16 to i32*
  %18 = addrspacecast i32* %17 to i32 addrspace(1)*
  store i32 %0, i32 addrspace(1)* %18, align 4
  %19 = getelementptr inbounds i8, i8* %1, i64 24
  %20 = bitcast i8* %19 to i32*
  %21 = addrspacecast i32* %20 to i32 addrspace(1)*
  store i32 684837, i32 addrspace(1)* %21, align 1
  %22 = getelementptr inbounds i8, i8* %1, i64 28
  %23 = addrspacecast i8* %22 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* align 1 %23, i8* align 1 %s, i32 %0, i1 false)
  %24 = tail call i32 @printf_execute(i8* %1, i32 %total_buffer_size) #2
  ret void
}

declare i32 @__strlen_max(i8*, i32) local_unnamed_addr

declare i8* @printf_allocate(i32) local_unnamed_addr

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* noalias nocapture writeonly, i8* noalias nocapture readonly, i32, i1 immarg) #1

declare i32 @printf_execute(i8*, i32) local_unnamed_addr

; Function Attrs: alwaysinline norecurse nounwind
define void @f90printi_(i8* %s, i32* nocapture readonly %i) local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* %i, align 4, !tbaa !4
  %1 = tail call i32 @__strlen_max(i8* %s, i32 1024) #2
  %total_buffer_size = add i32 %1, 39
  %2 = tail call i8* @printf_allocate(i32 %total_buffer_size) #2
  %3 = bitcast i8* %2 to i32*
  %4 = addrspacecast i32* %3 to i32 addrspace(1)*
  store i32 32, i32 addrspace(1)* %4, align 4
  %5 = getelementptr inbounds i8, i8* %2, i64 4
  %6 = bitcast i8* %5 to i32*
  %7 = addrspacecast i32* %6 to i32 addrspace(1)*
  store i32 3, i32 addrspace(1)* %7, align 4
  %8 = getelementptr inbounds i8, i8* %2, i64 8
  %9 = bitcast i8* %8 to i32*
  %10 = addrspacecast i32* %9 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %10, align 4
  %11 = getelementptr inbounds i8, i8* %2, i64 12
  %12 = bitcast i8* %11 to i32*
  %13 = addrspacecast i32* %12 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %13, align 4
  %14 = getelementptr inbounds i8, i8* %2, i64 16
  %15 = bitcast i8* %14 to i32*
  %16 = addrspacecast i32* %15 to i32 addrspace(1)*
  store i32 852000, i32 addrspace(1)* %16, align 4
  %17 = getelementptr inbounds i8, i8* %2, i64 20
  %18 = bitcast i8* %17 to i32*
  %19 = addrspacecast i32* %18 to i32 addrspace(1)*
  store i32 7, i32 addrspace(1)* %19, align 4
  %20 = getelementptr inbounds i8, i8* %2, i64 24
  %21 = bitcast i8* %20 to i32*
  %22 = addrspacecast i32* %21 to i32 addrspace(1)*
  store i32 %1, i32 addrspace(1)* %22, align 4
  %23 = getelementptr inbounds i8, i8* %2, i64 28
  %24 = bitcast i8* %23 to i32*
  %25 = addrspacecast i32* %24 to i32 addrspace(1)*
  store i32 %0, i32 addrspace(1)* %25, align 4
  %26 = getelementptr inbounds i8, i8* %2, i64 32
  %27 = addrspacecast i8* %26 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p4i8.i64(i8 addrspace(1)* noundef align 1 dereferenceable(7) %27, i8 addrspace(4)* noundef align 1 dereferenceable(7) getelementptr inbounds ([7 x i8], [7 x i8] addrspace(4)* @.str.1, i64 0, i64 0), i64 7, i1 false)
  %28 = getelementptr inbounds i8, i8* %2, i64 39
  %29 = addrspacecast i8* %28 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* align 1 %29, i8* align 1 %s, i32 %1, i1 false)
  %30 = tail call i32 @printf_execute(i8* %2, i32 %total_buffer_size) #2
  ret void
}

; Function Attrs: alwaysinline norecurse nounwind
define void @f90printl_(i8* %s, i64* nocapture readonly %i) local_unnamed_addr #0 {
entry:
  %0 = load i64, i64* %i, align 8, !tbaa !8
  %1 = tail call i32 @__strlen_max(i8* %s, i32 1024) #2
  %total_buffer_size = add i32 %1, 48
  %2 = tail call i8* @printf_allocate(i32 %total_buffer_size) #2
  %3 = bitcast i8* %2 to i32*
  %4 = addrspacecast i32* %3 to i32 addrspace(1)*
  store i32 40, i32 addrspace(1)* %4, align 4
  %5 = getelementptr inbounds i8, i8* %2, i64 4
  %6 = bitcast i8* %5 to i32*
  %7 = addrspacecast i32* %6 to i32 addrspace(1)*
  store i32 3, i32 addrspace(1)* %7, align 4
  %8 = getelementptr inbounds i8, i8* %2, i64 8
  %9 = bitcast i8* %8 to i32*
  %10 = addrspacecast i32* %9 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %10, align 4
  %11 = getelementptr inbounds i8, i8* %2, i64 12
  %12 = bitcast i8* %11 to i32*
  %13 = addrspacecast i32* %12 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %13, align 4
  %14 = getelementptr inbounds i8, i8* %2, i64 16
  %15 = bitcast i8* %14 to i32*
  %16 = addrspacecast i32* %15 to i32 addrspace(1)*
  store i32 852032, i32 addrspace(1)* %16, align 4
  %17 = getelementptr inbounds i8, i8* %2, i64 20
  %18 = bitcast i8* %17 to i32*
  %19 = addrspacecast i32* %18 to i32 addrspace(1)*
  store i32 8, i32 addrspace(1)* %19, align 4
  %20 = getelementptr inbounds i8, i8* %2, i64 24
  %21 = bitcast i8* %20 to i32*
  %22 = addrspacecast i32* %21 to i32 addrspace(1)*
  store i32 %1, i32 addrspace(1)* %22, align 4
  %23 = getelementptr inbounds i8, i8* %2, i64 32
  %24 = bitcast i8* %23 to i64*
  %25 = addrspacecast i64* %24 to i64 addrspace(1)*
  store i64 %0, i64 addrspace(1)* %25, align 8
  %26 = getelementptr inbounds i8, i8* %2, i64 40
  %27 = bitcast i8* %26 to i64*
  %28 = addrspacecast i64* %27 to i64 addrspace(1)*
  store i64 2925165409235749, i64 addrspace(1)* %28, align 1
  %29 = getelementptr inbounds i8, i8* %2, i64 48
  %30 = addrspacecast i8* %29 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* align 1 %30, i8* align 1 %s, i32 %1, i1 false)
  %31 = tail call i32 @printf_execute(i8* %2, i32 %total_buffer_size) #2
  ret void
}

; Function Attrs: alwaysinline norecurse nounwind
define void @f90printf_(i8* %s, float* nocapture readonly %f) local_unnamed_addr #0 {
entry:
  %0 = load float, float* %f, align 4, !tbaa !10
  %conv = fpext float %0 to double
  %1 = tail call i32 @__strlen_max(i8* %s, i32 1024) #2
  %total_buffer_size = add i32 %1, 47
  %2 = tail call i8* @printf_allocate(i32 %total_buffer_size) #2
  %3 = bitcast i8* %2 to i32*
  %4 = addrspacecast i32* %3 to i32 addrspace(1)*
  store i32 40, i32 addrspace(1)* %4, align 4
  %5 = getelementptr inbounds i8, i8* %2, i64 4
  %6 = bitcast i8* %5 to i32*
  %7 = addrspacecast i32* %6 to i32 addrspace(1)*
  store i32 3, i32 addrspace(1)* %7, align 4
  %8 = getelementptr inbounds i8, i8* %2, i64 8
  %9 = bitcast i8* %8 to i32*
  %10 = addrspacecast i32* %9 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %10, align 4
  %11 = getelementptr inbounds i8, i8* %2, i64 12
  %12 = bitcast i8* %11 to i32*
  %13 = addrspacecast i32* %12 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %13, align 4
  %14 = getelementptr inbounds i8, i8* %2, i64 16
  %15 = bitcast i8* %14 to i32*
  %16 = addrspacecast i32* %15 to i32 addrspace(1)*
  store i32 196672, i32 addrspace(1)* %16, align 4
  %17 = getelementptr inbounds i8, i8* %2, i64 20
  %18 = bitcast i8* %17 to i32*
  %19 = addrspacecast i32* %18 to i32 addrspace(1)*
  store i32 7, i32 addrspace(1)* %19, align 4
  %20 = getelementptr inbounds i8, i8* %2, i64 24
  %21 = bitcast i8* %20 to i32*
  %22 = addrspacecast i32* %21 to i32 addrspace(1)*
  store i32 %1, i32 addrspace(1)* %22, align 4
  %23 = getelementptr inbounds i8, i8* %2, i64 32
  %24 = bitcast i8* %23 to double*
  %25 = addrspacecast double* %24 to double addrspace(1)*
  store double %conv, double addrspace(1)* %25, align 8
  %26 = getelementptr inbounds i8, i8* %2, i64 40
  %27 = addrspacecast i8* %26 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p4i8.i64(i8 addrspace(1)* noundef align 1 dereferenceable(7) %27, i8 addrspace(4)* noundef align 1 dereferenceable(7) getelementptr inbounds ([7 x i8], [7 x i8] addrspace(4)* @.str.3, i64 0, i64 0), i64 7, i1 false)
  %28 = getelementptr inbounds i8, i8* %2, i64 47
  %29 = addrspacecast i8* %28 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* align 1 %29, i8* align 1 %s, i32 %1, i1 false)
  %30 = tail call i32 @printf_execute(i8* %2, i32 %total_buffer_size) #2
  ret void
}

; Function Attrs: alwaysinline norecurse nounwind
define void @f90printd_(i8* %s, double* nocapture readonly %d) local_unnamed_addr #0 {
entry:
  %0 = load double, double* %d, align 8, !tbaa !12
  %1 = tail call i32 @__strlen_max(i8* %s, i32 1024) #2
  %total_buffer_size = add i32 %1, 47
  %2 = tail call i8* @printf_allocate(i32 %total_buffer_size) #2
  %3 = bitcast i8* %2 to i32*
  %4 = addrspacecast i32* %3 to i32 addrspace(1)*
  store i32 40, i32 addrspace(1)* %4, align 4
  %5 = getelementptr inbounds i8, i8* %2, i64 4
  %6 = bitcast i8* %5 to i32*
  %7 = addrspacecast i32* %6 to i32 addrspace(1)*
  store i32 3, i32 addrspace(1)* %7, align 4
  %8 = getelementptr inbounds i8, i8* %2, i64 8
  %9 = bitcast i8* %8 to i32*
  %10 = addrspacecast i32* %9 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %10, align 4
  %11 = getelementptr inbounds i8, i8* %2, i64 12
  %12 = bitcast i8* %11 to i32*
  %13 = addrspacecast i32* %12 to i32 addrspace(1)*
  store i32 983041, i32 addrspace(1)* %13, align 4
  %14 = getelementptr inbounds i8, i8* %2, i64 16
  %15 = bitcast i8* %14 to i32*
  %16 = addrspacecast i32* %15 to i32 addrspace(1)*
  store i32 196672, i32 addrspace(1)* %16, align 4
  %17 = getelementptr inbounds i8, i8* %2, i64 20
  %18 = bitcast i8* %17 to i32*
  %19 = addrspacecast i32* %18 to i32 addrspace(1)*
  store i32 7, i32 addrspace(1)* %19, align 4
  %20 = getelementptr inbounds i8, i8* %2, i64 24
  %21 = bitcast i8* %20 to i32*
  %22 = addrspacecast i32* %21 to i32 addrspace(1)*
  store i32 %1, i32 addrspace(1)* %22, align 4
  %23 = getelementptr inbounds i8, i8* %2, i64 32
  %24 = bitcast i8* %23 to double*
  %25 = addrspacecast double* %24 to double addrspace(1)*
  store double %0, double addrspace(1)* %25, align 8
  %26 = getelementptr inbounds i8, i8* %2, i64 40
  %27 = addrspacecast i8* %26 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p4i8.i64(i8 addrspace(1)* noundef align 1 dereferenceable(7) %27, i8 addrspace(4)* noundef align 1 dereferenceable(7) getelementptr inbounds ([7 x i8], [7 x i8] addrspace(4)* @.str.4, i64 0, i64 0), i64 7, i1 false)
  %28 = getelementptr inbounds i8, i8* %2, i64 47
  %29 = addrspacecast i8* %28 to i8 addrspace(1)*
  tail call void @llvm.memcpy.p1i8.p0i8.i32(i8 addrspace(1)* align 1 %29, i8* align 1 %s, i32 %1, i1 false)
  %30 = tail call i32 @printf_execute(i8* %2, i32 %total_buffer_size) #2
  ret void
}

; Function Attrs: argmemonly nofree nosync nounwind willreturn
declare void @llvm.memcpy.p1i8.p4i8.i64(i8 addrspace(1)* noalias nocapture writeonly, i8 addrspace(4)* noalias nocapture readonly, i64, i1 immarg) #1

attributes #0 = { alwaysinline norecurse nounwind "frame-pointer"="none" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx906" "target-features"="+16-bit-insts,+ci-insts,+dl-insts,+dot1-insts,+dot2-insts,+dot7-insts,+dpp,+flat-address-space,+gfx8-insts,+gfx9-insts,+s-memrealtime,+s-memtime-inst" }
attributes #1 = { argmemonly nofree nosync nounwind willreturn }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1}
!opencl.ocl.version = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 2, i32 0}
!3 = !{!"AOMP_STANDALONE_12.0-0 clang version 13.0.0 (ssh://rlieberm@gerrit-git.amd.com:29418/lightning/ec/llvm-project 25f685d3c7ea9fccd2872f39d7603736a103575e)"}
!4 = !{!5, !5, i64 0}
!5 = !{!"int", !6, i64 0}
!6 = !{!"omnipotent char", !7, i64 0}
!7 = !{!"Simple C/C++ TBAA"}
!8 = !{!9, !9, i64 0}
!9 = !{!"long", !6, i64 0}
!10 = !{!11, !11, i64 0}
!11 = !{!"float", !6, i64 0}
!12 = !{!13, !13, i64 0}
!13 = !{!"double", !6, i64 0}
