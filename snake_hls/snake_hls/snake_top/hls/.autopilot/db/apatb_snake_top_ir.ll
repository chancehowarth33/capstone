; ModuleID = 'C:/Users/aniko/OneDrive/Desktop/ECE554/capstone/snake_hls/snake_hls/snake_top/hls/.autopilot/db/a.g.ld.5.gdce.bc'
source_filename = "llvm-link"
target datalayout = "e-m:e-i64:64-i128:128-i256:256-i512:512-i1024:1024-i2048:2048-i4096:4096-n8:16:32:64-S128-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "fpga64-xilinx-none"

%"struct.ap_uint<10>" = type { %"struct.ap_int_base<10, false>" }
%"struct.ap_int_base<10, false>" = type { %"struct.ssdm_int<10, false>" }
%"struct.ssdm_int<10, false>" = type { i10 }

; Function Attrs: noinline willreturn
define void @apatb_snake_top_ir(%"struct.ap_uint<10>"* nocapture readonly %hand_x, %"struct.ap_uint<10>"* nocapture readonly %hand_y, i1 zeroext %detected, %"struct.ap_uint<10>"* nocapture readonly %vga_x, %"struct.ap_uint<10>"* nocapture readonly %vga_y, i1 zeroext %vsync, i1 zeroext %rst_n, %"struct.ap_uint<10>"* noalias nocapture nonnull align 2 dereferenceable(2) %R_out, %"struct.ap_uint<10>"* noalias nocapture nonnull align 2 dereferenceable(2) %G_out, %"struct.ap_uint<10>"* noalias nocapture nonnull align 2 dereferenceable(2) %B_out) local_unnamed_addr #0 {
entry:
  %R_out_copy = alloca i10, align 512
  %G_out_copy = alloca i10, align 512
  %B_out_copy = alloca i10, align 512
  call fastcc void @copy_in(%"struct.ap_uint<10>"* nonnull %R_out, i10* nonnull align 512 %R_out_copy, %"struct.ap_uint<10>"* nonnull %G_out, i10* nonnull align 512 %G_out_copy, %"struct.ap_uint<10>"* nonnull %B_out, i10* nonnull align 512 %B_out_copy)
  call void @apatb_snake_top_hw(%"struct.ap_uint<10>"* %hand_x, %"struct.ap_uint<10>"* %hand_y, i1 %detected, %"struct.ap_uint<10>"* %vga_x, %"struct.ap_uint<10>"* %vga_y, i1 %vsync, i1 %rst_n, i10* %R_out_copy, i10* %G_out_copy, i10* %B_out_copy)
  call void @copy_back(%"struct.ap_uint<10>"* %R_out, i10* %R_out_copy, %"struct.ap_uint<10>"* %G_out, i10* %G_out_copy, %"struct.ap_uint<10>"* %B_out, i10* %B_out_copy)
  ret void
}

; Function Attrs: argmemonly noinline norecurse willreturn
define internal fastcc void @copy_in(%"struct.ap_uint<10>"* noalias readonly "unpacked"="0", i10* noalias nocapture align 512 "unpacked"="1.0", %"struct.ap_uint<10>"* noalias readonly "unpacked"="2", i10* noalias nocapture align 512 "unpacked"="3.0", %"struct.ap_uint<10>"* noalias readonly "unpacked"="4", i10* noalias nocapture align 512 "unpacked"="5.0") unnamed_addr #1 {
entry:
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>"(i10* align 512 %1, %"struct.ap_uint<10>"* %0)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>"(i10* align 512 %3, %"struct.ap_uint<10>"* %2)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>"(i10* align 512 %5, %"struct.ap_uint<10>"* %4)
  ret void
}

; Function Attrs: argmemonly noinline norecurse willreturn
define internal fastcc void @copy_out(%"struct.ap_uint<10>"* noalias "unpacked"="0", i10* noalias nocapture readonly align 512 "unpacked"="1.0", %"struct.ap_uint<10>"* noalias "unpacked"="2", i10* noalias nocapture readonly align 512 "unpacked"="3.0", %"struct.ap_uint<10>"* noalias "unpacked"="4", i10* noalias nocapture readonly align 512 "unpacked"="5.0") unnamed_addr #2 {
entry:
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %0, i10* align 512 %1)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %2, i10* align 512 %3)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %4, i10* align 512 %5)
  ret void
}

; Function Attrs: argmemonly noinline norecurse willreturn
define internal fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* noalias "unpacked"="0" %dst, i10* noalias nocapture readonly align 512 "unpacked"="1.0" %src) unnamed_addr #3 {
entry:
  %0 = icmp eq %"struct.ap_uint<10>"* %dst, null
  br i1 %0, label %ret, label %copy

copy:                                             ; preds = %entry
  %dst.0.0.04 = getelementptr %"struct.ap_uint<10>", %"struct.ap_uint<10>"* %dst, i64 0, i32 0, i32 0, i32 0
  %1 = bitcast i10* %src to i16*
  %2 = load i16, i16* %1
  %3 = trunc i16 %2 to i10
  store i10 %3, i10* %dst.0.0.04, align 2
  br label %ret

ret:                                              ; preds = %copy, %entry
  ret void
}

; Function Attrs: argmemonly noinline norecurse willreturn
define internal fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>"(i10* noalias nocapture align 512 "unpacked"="0.0" %dst, %"struct.ap_uint<10>"* noalias readonly "unpacked"="1" %src) unnamed_addr #3 {
entry:
  %0 = icmp eq %"struct.ap_uint<10>"* %src, null
  br i1 %0, label %ret, label %copy

copy:                                             ; preds = %entry
  %src.0.0.03 = getelementptr %"struct.ap_uint<10>", %"struct.ap_uint<10>"* %src, i64 0, i32 0, i32 0, i32 0
  %1 = bitcast i10* %src.0.0.03 to i16*
  %2 = load i16, i16* %1
  %3 = trunc i16 %2 to i10
  store i10 %3, i10* %dst, align 512
  br label %ret

ret:                                              ; preds = %copy, %entry
  ret void
}

declare i8* @malloc(i64)

declare void @free(i8*)

declare void @apatb_snake_top_hw(%"struct.ap_uint<10>"*, %"struct.ap_uint<10>"*, i1, %"struct.ap_uint<10>"*, %"struct.ap_uint<10>"*, i1, i1, i10*, i10*, i10*)

; Function Attrs: argmemonly noinline norecurse willreturn
define internal fastcc void @copy_back(%"struct.ap_uint<10>"* noalias "unpacked"="0", i10* noalias nocapture readonly align 512 "unpacked"="1.0", %"struct.ap_uint<10>"* noalias "unpacked"="2", i10* noalias nocapture readonly align 512 "unpacked"="3.0", %"struct.ap_uint<10>"* noalias "unpacked"="4", i10* noalias nocapture readonly align 512 "unpacked"="5.0") unnamed_addr #2 {
entry:
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %0, i10* align 512 %1)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %2, i10* align 512 %3)
  call fastcc void @"onebyonecpy_hls.p0struct.ap_uint<10>.34"(%"struct.ap_uint<10>"* %4, i10* align 512 %5)
  ret void
}

declare void @snake_top_hw_stub(%"struct.ap_uint<10>"* nocapture readonly, %"struct.ap_uint<10>"* nocapture readonly, i1 zeroext, %"struct.ap_uint<10>"* nocapture readonly, %"struct.ap_uint<10>"* nocapture readonly, i1 zeroext, i1 zeroext, %"struct.ap_uint<10>"* noalias nocapture nonnull, %"struct.ap_uint<10>"* noalias nocapture nonnull, %"struct.ap_uint<10>"* noalias nocapture nonnull)

define void @snake_top_hw_stub_wrapper(%"struct.ap_uint<10>"*, %"struct.ap_uint<10>"*, i1, %"struct.ap_uint<10>"*, %"struct.ap_uint<10>"*, i1, i1, i10*, i10*, i10*) #4 {
entry:
  %10 = call i8* @malloc(i64 2)
  %11 = bitcast i8* %10 to %"struct.ap_uint<10>"*
  %12 = call i8* @malloc(i64 2)
  %13 = bitcast i8* %12 to %"struct.ap_uint<10>"*
  %14 = call i8* @malloc(i64 2)
  %15 = bitcast i8* %14 to %"struct.ap_uint<10>"*
  call void @copy_out(%"struct.ap_uint<10>"* %11, i10* %7, %"struct.ap_uint<10>"* %13, i10* %8, %"struct.ap_uint<10>"* %15, i10* %9)
  call void @snake_top_hw_stub(%"struct.ap_uint<10>"* %0, %"struct.ap_uint<10>"* %1, i1 %2, %"struct.ap_uint<10>"* %3, %"struct.ap_uint<10>"* %4, i1 %5, i1 %6, %"struct.ap_uint<10>"* %11, %"struct.ap_uint<10>"* %13, %"struct.ap_uint<10>"* %15)
  call void @copy_in(%"struct.ap_uint<10>"* %11, i10* %7, %"struct.ap_uint<10>"* %13, i10* %8, %"struct.ap_uint<10>"* %15, i10* %9)
  call void @free(i8* %10)
  call void @free(i8* %12)
  call void @free(i8* %14)
  ret void
}

attributes #0 = { noinline willreturn "fpga.wrapper.func"="wrapper" }
attributes #1 = { argmemonly noinline norecurse willreturn "fpga.wrapper.func"="copyin" }
attributes #2 = { argmemonly noinline norecurse willreturn "fpga.wrapper.func"="copyout" }
attributes #3 = { argmemonly noinline norecurse willreturn "fpga.wrapper.func"="onebyonecpy_hls" }
attributes #4 = { "fpga.wrapper.func"="stub" }

!llvm.dbg.cu = !{}
!llvm.ident = !{!0, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1, !1}
!llvm.module.flags = !{!2, !3, !4}
!blackbox_cfg = !{!5}

!0 = !{!"AMD/Xilinx clang version 16.0.6"}
!1 = !{!"clang version 7.0.0 "}
!2 = !{i32 2, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{}
