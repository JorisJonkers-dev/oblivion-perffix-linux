; ModuleID = 'src/diagnostics/tick_split.cpp'
source_filename = "src/diagnostics/tick_split.cpp"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.33.0"

%"class.std::unordered_map" = type { %"class.std::_Hash" }
%"class.std::_Hash" = type { %"class.std::_Umap_traits", %"class.std::list", %"struct.std::_Hash_vec", i64, i64 }
%"class.std::_Umap_traits" = type { %"class.std::_Uhash_compare" }
%"class.std::_Uhash_compare" = type { %"class.std::_Compressed_pair.0" }
%"class.std::_Compressed_pair.0" = type { %"class.std::_Compressed_pair.1" }
%"class.std::_Compressed_pair.1" = type { float }
%"class.std::list" = type { %"class.std::_Compressed_pair.2" }
%"class.std::_Compressed_pair.2" = type { %"class.std::_List_val" }
%"class.std::_List_val" = type { ptr, i64 }
%"struct.std::_Hash_vec" = type { %"class.std::_Compressed_pair.5" }
%"class.std::_Compressed_pair.5" = type { %"class.std::_Vector_val" }
%"class.std::_Vector_val" = type { ptr, ptr, ptr }
%"struct.opf::(anonymous namespace)::Window" = type { [4096 x %"struct.opf::(anonymous namespace)::Entry"], i32, i64, i64, i64, i64, i64, i64, [8 x i64], i64, i64, i64, [9 x i64], i64, i64, %"struct.opf::(anonymous namespace)::PercAcc" }
%"struct.opf::(anonymous namespace)::Entry" = type { ptr, ptr, i32, i32, i64, i64, i64, i64 }
%"struct.opf::(anonymous namespace)::PercAcc" = type { [10 x %"struct.opf::(anonymous namespace)::PercStat"], i64, [4 x i64], i64, i64, [3 x i64], [3 x i64], [3 x i64] }
%"struct.opf::(anonymous namespace)::PercStat" = type { i64, i64, i64 }
%"struct.opf::(anonymous namespace)::TRec" = type { i64, i64, i32, [3 x %"struct.opf::(anonymous namespace)::Top"], [9 x i32], i32, i32 }
%"struct.opf::(anonymous namespace)::Top" = type { ptr, ptr, i32, i32 }
%struct.anon = type { i32, i32 }
%rtti.TypeDescriptor30 = type { ptr, ptr, [31 x i8] }
%eh.CatchableType = type { i32, i32, i32, i32, i32, i32, i32 }
%rtti.TypeDescriptor19 = type { ptr, ptr, [20 x i8] }
%eh.CatchableTypeArray.3 = type { i32, [3 x i32] }
%eh.ThrowInfo = type { i32, i32, i32, i32 }
%rtti.CompleteObjectLocator = type { i32, i32, i32, i32, i32, i32 }
%rtti.ClassHierarchyDescriptor = type { i32, i32, i32, i32 }
%rtti.BaseClassDescriptor = type { i32, i32, i32, i32, i32, i32, i32 }
%"struct.opf::(anonymous namespace)::OffKind" = type { %"struct.std::atomic.38", %"struct.std::atomic.9", %"struct.std::atomic.9" }
%"struct.std::atomic.38" = type { %"struct.std::_Atomic_nonobject_pointer" }
%"struct.std::_Atomic_nonobject_pointer" = type { %"struct.std::_Atomic_storage.39" }
%"struct.std::_Atomic_storage.39" = type { %"struct.std::_Atomic_padded.40" }
%"struct.std::_Atomic_padded.40" = type { ptr }
%"struct.std::atomic.9" = type { %"struct.std::_Atomic_integral_facade" }
%"struct.std::_Atomic_integral_facade" = type { %"struct.std::_Atomic_integral" }
%"struct.std::_Atomic_integral" = type { %"struct.std::_Atomic_storage.10" }
%"struct.std::_Atomic_storage.10" = type { %"struct.std::_Atomic_padded.11" }
%"struct.std::_Atomic_padded.11" = type { i64 }
%"struct.opf::(anonymous namespace)::KindState" = type { ptr, i32 }
%"struct.std::_Atomic_padded" = type { i8 }
%"struct.std::_Atomic_padded.16" = type { i32 }
%"struct.std::_Atomic_padded.21" = type { i32 }
%"class.std::span" = type { %"struct.std::_Span_extent_type" }
%"struct.std::_Span_extent_type" = type { ptr, i64 }
%"class.std::basic_string" = type { %"class.std::_Compressed_pair" }
%"class.std::_Compressed_pair" = type { %"class.std::_String_val" }
%"class.std::_String_val" = type { %"union.std::_String_val<std::_Simple_types<wchar_t>>::_Bxty", i64, i64 }
%"union.std::_String_val<std::_Simple_types<wchar_t>>::_Bxty" = type { ptr, [8 x i8] }
%"class.std::vector" = type { %"class.std::_Compressed_pair.29" }
%"class.std::_Compressed_pair.29" = type { %"class.std::_Vector_val.32" }
%"class.std::_Vector_val.32" = type { ptr, ptr, ptr }
%"struct.opf::Pattern" = type { %"class.std::vector.33", %"class.std::vector.33" }
%"class.std::vector.33" = type { %"class.std::_Compressed_pair.34" }
%"class.std::_Compressed_pair.34" = type { %"class.std::_Vector_val.37" }
%"class.std::_Vector_val.37" = type { ptr, ptr, ptr }
%"class.std::basic_string_view" = type { ptr, i64 }
%union._LARGE_INTEGER = type { i64 }
%"class.std::basic_string.22" = type { %"class.std::_Compressed_pair.23" }
%"class.std::_Compressed_pair.23" = type { %"class.std::_String_val.26" }
%"class.std::_String_val.26" = type { %"union.std::_String_val<std::_Simple_types<char>>::_Bxty", i64, i64 }
%"union.std::_String_val<std::_Simple_types<char>>::_Bxty" = type { ptr, [8 x i8] }
%"class.std::allocator" = type { i8 }
%"class.std::bad_array_new_length" = type { %"class.std::bad_alloc" }
%"class.std::bad_alloc" = type { %"class.std::exception" }
%"class.std::exception" = type { ptr, %struct.__std_exception_data }
%struct.__std_exception_data = type { ptr, i8 }
%struct._MEMORY_BASIC_INFORMATION = type { ptr, ptr, i32, i16, i64, i32, i32, i32 }
%"struct.std::pair.44" = type { %"class.std::_List_iterator", i8 }
%"class.std::_List_iterator" = type { %"class.std::_List_const_iterator" }
%"class.std::_List_const_iterator" = type { %"class.std::_List_unchecked_const_iterator" }
%"class.std::_List_unchecked_const_iterator" = type { ptr }
%"struct.std::_List_node_emplace_op2" = type { %"struct.std::_Alloc_construct_ptr" }
%"struct.std::_Alloc_construct_ptr" = type { ptr, ptr }
%"struct.std::_Hash<std::_Umap_traits<const void *, std::basic_string<char>, std::_Uhash_compare<const void *, std::hash<const void *>, std::equal_to<const void *>>, std::allocator<std::pair<const void *const, std::basic_string<char>>>, false>>::_Clear_guard" = type { ptr }
%"class.std::allocator.49" = type { i8 }

$"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ" = comdat any

$"??1?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ" = comdat any

$"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@QEB_W@Z" = comdat any

$"??1?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAA@XZ" = comdat any

$"??1?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA@XZ" = comdat any

$"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z" = comdat any

$"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ" = comdat any

$"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W_K@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEB_W0@Z@PEB_W_K@Z" = comdat any

$"?_Xlen_string@std@@YAXXZ" = comdat any

$"?_Throw_bad_array_new_length@std@@YAXXZ" = comdat any

$"??0bad_array_new_length@std@@QEAA@XZ" = comdat any

$"??0bad_array_new_length@std@@QEAA@AEBV01@@Z" = comdat any

$"??0bad_alloc@std@@QEAA@AEBV01@@Z" = comdat any

$"??0exception@std@@QEAA@AEBV01@@Z" = comdat any

$"??1exception@std@@UEAA@XZ" = comdat any

$"??_Gbad_array_new_length@std@@UEAAPEAXI@Z" = comdat any

$"?what@exception@std@@UEBAPEBDXZ" = comdat any

$"??_Gbad_alloc@std@@UEAAPEAXI@Z" = comdat any

$"??_Gexception@std@@UEAAPEAXI@Z" = comdat any

$"??1Pattern@opf@@QEAA@XZ" = comdat any

$"??1?$vector@PEAEV?$allocator@PEAE@std@@@std@@QEAA@XZ" = comdat any

$"??1?$vector@EV?$allocator@E@std@@@std@@QEAA@XZ" = comdat any

$"?Contains@Section@opf@@QEBA_NPEBX@Z" = comdat any

$snprintf = comdat any

$"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@AEBV01@_K1AEBV?$allocator@_W@1@@Z" = comdat any

$"?_Xran@?$_String_val@U?$_Simple_types@_W@std@@@std@@SAXXZ" = comdat any

$__local_stdio_printf_options = comdat any

$"??$emplace@AEAPEBXAEAY0KA@D@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AU?$pair@V?$_List_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@_N@1@AEAPEBXAEAY0KA@D@Z" = comdat any

$"??1?$_List_node_emplace_op2@V?$allocator@U?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@std@@@std@@QEAA@XZ" = comdat any

$"??0?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@QEBD@Z" = comdat any

$"?_Forced_rehash@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAAX_K@Z" = comdat any

$"?_Assign_grow@?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAAX_KV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@@Z" = comdat any

$"??1_Clear_guard@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ" = comdat any

$"?_Unchecked_erase@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@AEAAPEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@2@PEAU32@QEAU32@@Z" = comdat any

$"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAAAEAV34@QEBD_K@Z@PEBD_K@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEBD0@Z@PEBD_K@Z" = comdat any

$"??$_Reallocate_for@V<lambda_1>@?0??assign@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??assign@01@QEAAAEAV01@QEB_W0@Z@PEB_W@Z" = comdat any

$"??0?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAA@AEBV?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@1@AEBV?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@1@@Z" = comdat any

$"??_C@_1DO@OMHMLJDE@?$AA?2?$AAO?$AAb?$AAl?$AAi?$AAv?$AAi?$AAo?$AAn?$AAP?$AAe?$AAr?$AAf?$AAF?$AAi?$AAx?$AA?9?$AAt?$AAi?$AAc?$AAk?$AAs?$AAp?$AAl?$AAi?$AAt?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@" = comdat any

$"??_C@_0GB@FOFFKKBF@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = comdat any

$"??_C@_0FA@MCMEKDLE@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = comdat any

$"??_C@_0DK@LMNCKLPI@?$FLticksplit?$FN?5no?5memory?5near?5the?5g@" = comdat any

$"??_C@_0CB@DJHBCLHN@the?5tick?5task?8s?5ExecuteTick?5call@" = comdat any

$"??_C@_0BH@IGFJAIEK@TickObjects?8?5Tick?5call?$AA@" = comdat any

$"??_C@_0CC@CFKFCEJK@the?5timer?5manager?8s?5delegate?5cal@" = comdat any

$"??_C@_0CG@BBFGHKOI@the?5timer?5manager?8s?5ProcessEvent@" = comdat any

$"??_C@_0CD@EOFGHCKA@the?5timer?5manager?8s?5TFunction?5ca@" = comdat any

$"??_C@_0CJ@MIHNDPNJ@UWorld?3?3Tick?8s?5timer?5and?5tickabl@" = comdat any

$"??_C@_0CO@MLPLNNMG@UWorld?3?3Tick?8s?5SetupPhysicsTickF@" = comdat any

$"??_C@_0CP@NHCICKLN@UWorld?3?3Tick?8s?5EnsureCollisionTr@" = comdat any

$"??_C@_0CJ@MAEPLMN@UWorld?3?3Tick?8s?5ProcessLatentActi@" = comdat any

$"??_C@_05NAPFDJNG@timer?$AA@" = comdat any

$"??_C@_0M@PPDPACCC@tickobjects?$AA@" = comdat any

$"??_C@_0DB@DPPPLJPI@UWorld?3?3Tick?8s?5InternalUpdateStr@" = comdat any

$"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@" = comdat any

$"??_C@_0EO@PKKBIJCB@?$FLticksplit?$FN?5could?5not?5redirect?5t@" = comdat any

$"??_C@_0EN@BKKGNFJM@?$FLticksplit?$FN?5could?5not?5redirect?5t@" = comdat any

$"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@" = comdat any

$"??_C@_0BK@GELKNIDE@the?5timers?8?5delegate?5call?$AA@" = comdat any

$"??_C@_0BO@MMLNOBPC@the?5timers?8?5ProcessEvent?5call?$AA@" = comdat any

$"??_C@_0BL@HPHJODLD@the?5timers?8?5TFunction?5call?$AA@" = comdat any

$"??_C@_05MMGNIMAB@timed?$AA@" = comdat any

$"??_C@_01JOAMLHOP@?9?$AA@" = comdat any

$"??_C@_09DOMJCJCO@installed?$AA@" = comdat any

$"??_C@_0DD@PJBCBDCM@NOT?5installed?5?$CIthe?5ExecuteTick?5c@" = comdat any

$"??_C@_0JL@ODHELHNK@?$FLticksplit?$FN?5?$CFs?3?5tick?5functions?5?$CF@" = comdat any

$"??_C@_0HC@MLKAEPAE@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = comdat any

$"??_C@_0BE@EHLDMMMC@splitting?5tick?5time?$AA@" = comdat any

$"??_C@_07IEOHBIGJ@stopped?$AA@" = comdat any

$"??_C@_0P@JAPMPJJJ@?$FLticksplit?$FN?5?$CFs?$AA@" = comdat any

$"??_C@_0BA@JFNIOLAK@string?5too?5long?$AA@" = comdat any

$"??_R0?AVbad_array_new_length@std@@@8" = comdat any

$"_CT??_R0?AVbad_array_new_length@std@@@8??0bad_array_new_length@std@@QEAA@AEBV01@@Z24" = comdat any

$"??_R0?AVbad_alloc@std@@@8" = comdat any

$"_CT??_R0?AVbad_alloc@std@@@8??0bad_alloc@std@@QEAA@AEBV01@@Z24" = comdat any

$"??_R0?AVexception@std@@@8" = comdat any

$"_CT??_R0?AVexception@std@@@8??0exception@std@@QEAA@AEBV01@@Z24" = comdat any

$"_CTA3?AVbad_array_new_length@std@@" = comdat any

$"_TI3?AVbad_array_new_length@std@@" = comdat any

$"??_C@_0BF@KINCDENJ@bad?5array?5new?5length?$AA@" = comdat any

$"??_7bad_array_new_length@std@@6B@" = comdat largest

$"??_R4bad_array_new_length@std@@6B@" = comdat any

$"??_R3bad_array_new_length@std@@8" = comdat any

$"??_R2bad_array_new_length@std@@8" = comdat any

$"??_R1A@?0A@EA@bad_array_new_length@std@@8" = comdat any

$"??_R1A@?0A@EA@bad_alloc@std@@8" = comdat any

$"??_R3bad_alloc@std@@8" = comdat any

$"??_R2bad_alloc@std@@8" = comdat any

$"??_R1A@?0A@EA@exception@std@@8" = comdat any

$"??_R3exception@std@@8" = comdat any

$"??_R2exception@std@@8" = comdat any

$"??_7bad_alloc@std@@6B@" = comdat largest

$"??_R4bad_alloc@std@@6B@" = comdat any

$"??_7exception@std@@6B@" = comdat largest

$"??_R4exception@std@@6B@" = comdat any

$"??_C@_0BC@EOODALEL@Unknown?5exception?$AA@" = comdat any

$"??_C@_09GNNAFPDF@not?5found?$AA@" = comdat any

$"??_C@_09BCDCAHEC@ambiguous?$AA@" = comdat any

$"??_C@_0BN@NJLBEKLK@?$FLticksplit?$FN?5?$CFs?5?$CFs?3?5not?5timed?$AA@" = comdat any

$"??_C@_1O@GLCFMFBP@?$AA?4?$AA1?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@" = comdat any

$"??_C@_13CIFDLIMG@?$AAw?$AA?$AA@" = comdat any

$"??_C@_0CB@HDKOBCJ@?$FLticksplit?$FN?5could?5not?5create?5?$CFls@" = comdat any

$"??_C@_0EMA@BFPHIDFE@?$CD?5OblivionPerfFix?9ticksplit?5v1?0?5@" = comdat any

$"??_C@_0CK@JNAPDPCD@?$FLticksplit?$FN?5writing?5the?5tick?5spl@" = comdat any

$"??_C@_0BI@CFPLBAOH@invalid?5string?5position?$AA@" = comdat any

$"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA" = comdat any

$"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@" = comdat any

$"??_C@_0BJ@PPABGLFN@T?0?$CFllu?0?$CF?43f?0?$CF?43f?0?$CFu?0?$CF?43f?$AA@" = comdat any

$"??_C@_0BB@GOELHNLD@?0?$CFu?00x?$CFX?0?$CFs?0?$CF?43f?$AA@" = comdat any

$"??_C@_04NPGOAOEL@?0?0?0?0?$AA@" = comdat any

$"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@" = comdat any

$"??_C@_01EEMJAFIK@?6?$AA@" = comdat any

$"??_C@_0M@OAJNJFNP@vt?3exe?$CL0x?$CFX?$AA@" = comdat any

$"??_C@_05BBDLBDLH@vt?3?$CFp?$AA@" = comdat any

$"??_C@_0CD@KKPKGCCK@?$FLticksplit?$FN?5FName?5pool?5at?5exe?$CL0x@" = comdat any

$"??_C@_0DP@HKEOIGNE@?$FLticksplit?$FN?5FName?5pool?5not?5found@" = comdat any

$"??_C@_06JHKGMGPP@cls?3?$CFp?$AA@" = comdat any

$"??_C@_04OHJIHAFH@None?$AA@" = comdat any

$"??_C@_03CBBLDGKP@_?$CFu?$AA@" = comdat any

$"??_C@_0BL@GOIGLPKN@unordered_map?1set?5too?5long?$AA@" = comdat any

$"??_C@_0BK@OGNNAFAB@invalid?5hash?5bucket?5count?$AA@" = comdat any

$"??_C@_0CF@KMOIDJIM@W?0?$CF?43f?0?$CF?43f?0?$CFllu?0?$CFllu?0?$CF?43f?0?$CF?43f?0@" = comdat any

$"??_C@_0BI@EJEDBKLJ@?0?$CFllu?0?$CF?43f?0?$CFllu?0?$CF?43f?0?$CFu?$AA@" = comdat any

$"??_C@_0BP@ECEGIOMC@P?0?$CF?43f?0?$CFllu?0?$CFs?0?$CFllu?0?$CF?46f?0?$CF?46f?6?$AA@" = comdat any

$"??_C@_0M@LECLBMHC@Q?0?$CF?43f?0?$CFllu?$AA@" = comdat any

$"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@" = comdat any

$"??_C@_0L@CJPDDBCK@?0?$CFllu?0?$CFllu?$AA@" = comdat any

$"??_C@_0BA@CLBIGIHG@?0?$CFllu?0?$CFllu?0?$CFllu?$AA@" = comdat any

$"??_C@_0CD@CCJMPANC@E?0?$CF?43f?0?$CFu?0?$CFd?00x?$CFX?0?$CFs?0?$CFu?0?$CF?44f?0?$CF?44@" = comdat any

$"??_C@_0BH@PLKFBJEJ@O?0?$CF?43f?00x?$CFX?0?$CFllu?0?$CF?44f?6?$AA@" = comdat any

$"??_C@_05MLFKBFFK@whole?$AA@" = comdat any

$"??_C@_04DONFEANM@list?$AA@" = comdat any

$"??_C@_03OINCMOHA@los?$AA@" = comdat any

$"??_C@_06GDPEBLPA@ignore?$AA@" = comdat any

$"??_C@_06DJNOHABK@trace1?$AA@" = comdat any

$"??_C@_06BCPDCDNJ@trace2?$AA@" = comdat any

$"??_C@_06LOIBCJI@trace3?$AA@" = comdat any

$"??_C@_08BIDMIFAH@los_rest?$AA@" = comdat any

$"??_C@_08BPLPECIC@commands?$AA@" = comdat any

$"??_C@_09HALKBBKJ@remainder?$AA@" = comdat any

@"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A" = internal global { { { { [8 x i16] }, i64, i64 } } } { { { { [8 x i16] }, i64, i64 } } { { { [8 x i16] }, i64, i64 } { { [8 x i16] } zeroinitializer, i64 0, i64 7 } } }, align 8
@"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A" = internal global %"class.std::unordered_map" zeroinitializer, align 8
@"?g_installed@?A0xB9C01504@opf@@3_NA" = internal unnamed_addr global i8 0, align 1
@"??_C@_1DO@OMHMLJDE@?$AA?2?$AAO?$AAb?$AAl?$AAi?$AAv?$AAi?$AAo?$AAn?$AAP?$AAe?$AAr?$AAf?$AAF?$AAi?$AAx?$AA?9?$AAt?$AAi?$AAc?$AAk?$AAs?$AAp?$AAl?$AAi?$AAt?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@" = linkonce_odr dso_local unnamed_addr constant [31 x i16] [i16 92, i16 79, i16 98, i16 108, i16 105, i16 118, i16 105, i16 111, i16 110, i16 80, i16 101, i16 114, i16 102, i16 70, i16 105, i16 120, i16 45, i16 116, i16 105, i16 99, i16 107, i16 115, i16 112, i16 108, i16 105, i16 116, i16 46, i16 99, i16 115, i16 118, i16 0], comdat, align 2
@"??_C@_0GB@FOFFKKBF@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = linkonce_odr dso_local unnamed_addr constant [97 x i8] c"[ticksplit] HitchLedgerTickSplit: can only be installed at start-up (version.dll), not installed\00", comdat, align 1
@"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA" = internal unnamed_addr global ptr null, align 8
@"??_C@_0FA@MCMEKDLE@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = linkonce_odr dso_local unnamed_addr constant [80 x i8] c"[ticksplit] HitchLedgerTickSplit needs HitchLedger=1 at start-up: not installed\00", comdat, align 1
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10" = internal unnamed_addr global ptr null, align 8
@"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.11" = internal unnamed_addr global ptr null, align 8
@"??_C@_0DK@LMNCKLPI@?$FLticksplit?$FN?5no?5memory?5near?5the?5g@" = linkonce_odr dso_local unnamed_addr constant [58 x i8] c"[ticksplit] no memory near the game's code: not installed\00", comdat, align 1
@"??_C@_0CB@DJHBCLHN@the?5tick?5task?8s?5ExecuteTick?5call@" = linkonce_odr dso_local unnamed_addr constant [33 x i8] c"the tick task's ExecuteTick call\00", comdat, align 1
@"?kExecSite@?A0xB9C01504@opf@@3QBDB" = internal constant [81 x i8] c"F3 0F 11 4A 24 48 8D BB ?? ?? ?? ?? 0F 28 CA 48 89 7C 24 20 44 8B CE 41 FF D2 EB\00", align 16
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.mov" = private unnamed_addr constant [3 x i8] c"D\8B\CE", align 1
@"??_C@_0BH@IGFJAIEK@TickObjects?8?5Tick?5call?$AA@" = linkonce_odr dso_local unnamed_addr constant [23 x i8] c"TickObjects' Tick call\00", comdat, align 1
@"?kTickableSite@?A0xB9C01504@opf@@3QBDB" = internal constant [84 x i8] c"48 8B 03 48 8D 55 ?? 48 8B CB FF 50 20 48 8B 03 0F 28 CE 48 8B CB FF 10 48 83 3F 00\00", align 16
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre" = private unnamed_addr constant [6 x i8] c"H\8B\CB\0F(\CE", align 1
@"??_C@_0CC@CFKFCEJK@the?5timer?5manager?8s?5delegate?5cal@" = linkonce_odr dso_local unnamed_addr constant [34 x i8] c"the timer manager's delegate call\00", comdat, align 1
@"?kTimerNative@?A0xB9C01504@opf@@3QBDB" = internal constant [51 x i8] c"83 7B 18 00 74 ?? 48 8B 4B 10 48 8B 01 FF 50 58 E9\00", align 16
@"?g_nativeSlot@?A0xB9C01504@opf@@3IA" = internal unnamed_addr global i32 88, align 4
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre.1" = private unnamed_addr constant [7 x i8] c"H\8BK\10L\8B\C3", align 1
@"??_C@_0CG@BBFGHKOI@the?5timer?5manager?8s?5ProcessEvent@" = linkonce_odr dso_local unnamed_addr constant [38 x i8] c"the timer manager's ProcessEvent call\00", comdat, align 1
@"?kTimerDynamic@?A0xB9C01504@opf@@3QBDB" = internal constant [66 x i8] c"4C 8B 0B 45 33 C0 48 8B D0 48 8B CB 41 FF 91 ?? ?? 00 00 41 8B FE\00", align 16
@"?g_peSlot@?A0xB9C01504@opf@@3IA" = internal unnamed_addr global i32 616, align 4
@"??_C@_0CD@EOFGHCKA@the?5timer?5manager?8s?5TFunction?5ca@" = linkonce_odr dso_local unnamed_addr constant [35 x i8] c"the timer manager's TFunction call\00", comdat, align 1
@"?kTimerCallback@?A0xB9C01504@opf@@3QBDB" = internal constant [48 x i8] c"48 8B 01 FF 50 08 48 8B C8 FF D6 49 8D 74 24 08\00", align 16
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre.2" = private unnamed_addr constant [9 x i8] c"H\8B\C8H\8B\D6L\8B\C3", align 1
@"??_C@_0CJ@MIHNDPNJ@UWorld?3?3Tick?8s?5timer?5and?5tickabl@" = linkonce_odr dso_local unnamed_addr constant [41 x i8] c"UWorld::Tick's timer and tickables calls\00", comdat, align 1
@"?kTimerSite@?A0xB9C01504@opf@@3QBDB" = internal constant [117 x i8] c"48 8B CF E8 ?? ?? ?? ?? 0F 28 CE 48 8B C8 E8 ?? ?? ?? ?? 0F 28 DE 45 0F B6 C5 8B D3 48 8B CF E8 ?? ?? ?? ?? 48 8D 55\00", align 16
@"?kSetupSite@?A0xB9C01504@opf@@3QBDB" = internal constant [57 x i8] c"0F 28 CE 48 8B CF E8 ?? ?? ?? ?? 44 88 A7 ?? ?? 00 00 E8\00", align 16
@"??_C@_0CO@MLPLNNMG@UWorld?3?3Tick?8s?5SetupPhysicsTickF@" = linkonce_odr dso_local unnamed_addr constant [46 x i8] c"UWorld::Tick's SetupPhysicsTickFunctions call\00", comdat, align 1
@"?g_setupOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA" = internal unnamed_addr global ptr null, align 8
@"?kCollSite@?A0xB9C01504@opf@@3QBDB" = internal constant [57 x i8] c"80 A7 ?? ?? 00 00 FB E8 ?? ?? ?? ?? 80 8F ?? ?? 00 00 04\00", align 16
@"??_C@_0CP@NHCICKLN@UWorld?3?3Tick?8s?5EnsureCollisionTr@" = linkonce_odr dso_local unnamed_addr constant [47 x i8] c"UWorld::Tick's EnsureCollisionTreeIsBuilt call\00", comdat, align 1
@"?g_collOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA" = internal unnamed_addr global ptr null, align 8
@"?kLatentSite@?A0xB9C01504@opf@@3QBDB" = internal constant [48 x i8] c"0F 28 D6 33 D2 48 8B CE E8 ?? ?? ?? ?? 8B 5C 24\00", align 16
@"??_C@_0CJ@MAEPLMN@UWorld?3?3Tick?8s?5ProcessLatentActi@" = linkonce_odr dso_local unnamed_addr constant [41 x i8] c"UWorld::Tick's ProcessLatentActions call\00", comdat, align 1
@"?g_latentOrig@?A0xB9C01504@opf@@3P6AXPEAX0M@ZEA" = internal unnamed_addr global ptr null, align 8
@"??_C@_05NAPFDJNG@timer?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c"timer\00", comdat, align 1
@"?g_timerOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA" = internal unnamed_addr global ptr null, align 8
@"??_C@_0M@PPDPACCC@tickobjects?$AA@" = linkonce_odr dso_local unnamed_addr constant [12 x i8] c"tickobjects\00", comdat, align 1
@"?g_tickObjOrig@?A0xB9C01504@opf@@3P6AXPEAXH_NM@ZEA" = internal unnamed_addr global ptr null, align 8
@"?kStreamSite@?A0xB9C01504@opf@@3QBDB" = internal constant [63 x i8] c"45 84 ED 75 ?? 48 8B CF E8 ?? ?? ?? ?? 84 C0 74 08 48 8B CF E8\00", align 16
@"??_C@_0DB@DPPPLJPI@UWorld?3?3Tick?8s?5InternalUpdateStr@" = linkonce_odr dso_local unnamed_addr constant [49 x i8] c"UWorld::Tick's InternalUpdateStreamingState call\00", comdat, align 1
@"?g_streamOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA" = internal unnamed_addr global ptr null, align 8
@"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@" = linkonce_odr dso_local unnamed_addr constant [57 x i8] c"[ticksplit] %s: not a call to the game's code: not timed\00", comdat, align 1
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.call" = private unnamed_addr constant [6 x i8] c"\E8\00\00\00\00\90", align 1
@"??_C@_0EO@PKKBIJCB@?$FLticksplit?$FN?5could?5not?5redirect?5t@" = linkonce_odr dso_local unnamed_addr constant [78 x i8] c"[ticksplit] could not redirect the ExecuteTick call: tick functions not timed\00", comdat, align 1
@"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.call.3" = private unnamed_addr constant [11 x i8] c"\E8\00\00\00\00f\0F\1FD\00\00", align 1
@"??_C@_0EN@BKKGNFJM@?$FLticksplit?$FN?5could?5not?5redirect?5t@" = linkonce_odr dso_local unnamed_addr constant [77 x i8] c"[ticksplit] could not redirect the tickables' Tick call: tickables not split\00", comdat, align 1
@"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@" = linkonce_odr dso_local unnamed_addr constant [34 x i8] c"[ticksplit] could not redirect %s\00", comdat, align 1
@"??_C@_0BK@GELKNIDE@the?5timers?8?5delegate?5call?$AA@" = linkonce_odr dso_local unnamed_addr constant [26 x i8] c"the timers' delegate call\00", comdat, align 1
@"??_C@_0BO@MMLNOBPC@the?5timers?8?5ProcessEvent?5call?$AA@" = linkonce_odr dso_local unnamed_addr constant [30 x i8] c"the timers' ProcessEvent call\00", comdat, align 1
@"??_C@_0BL@HPHJODLD@the?5timers?8?5TFunction?5call?$AA@" = linkonce_odr dso_local unnamed_addr constant [27 x i8] c"the timers' TFunction call\00", comdat, align 1
@"??_C@_05MMGNIMAB@timed?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c"timed\00", comdat, align 1
@"??_C@_01JOAMLHOP@?9?$AA@" = linkonce_odr dso_local unnamed_addr constant [2 x i8] c"-\00", comdat, align 1
@"??_C@_09DOMJCJCO@installed?$AA@" = linkonce_odr dso_local unnamed_addr constant [10 x i8] c"installed\00", comdat, align 1
@"??_C@_0DD@PJBCBDCM@NOT?5installed?5?$CIthe?5ExecuteTick?5c@" = linkonce_odr dso_local unnamed_addr constant [51 x i8] c"NOT installed (the ExecuteTick call was not found)\00", comdat, align 1
@"??_C@_0JL@ODHELHNK@?$FLticksplit?$FN?5?$CFs?3?5tick?5functions?5?$CF@" = linkonce_odr dso_local unnamed_addr constant [155 x i8] c"[ticksplit] %s: tick functions %s, tickables %s, buckets setup %s, colltree %s, latent %s, timers %s, tickobjects %s, streaming %s, timers' calls %s/%s/%s\00", comdat, align 1
@"?logged@?1??SetTickSplit@opf@@YAX_N@Z@4_NA" = internal unnamed_addr global i1 false, align 1
@"??_C@_0HC@MLKAEPAE@?$FLticksplit?$FN?5HitchLedgerTickSplit@" = linkonce_odr dso_local unnamed_addr constant [114 x i8] c"[ticksplit] HitchLedgerTickSplit=1 but the split was not installed at start-up (needs HitchLedger=1 too): restart\00", comdat, align 1
@"??_C@_0BE@EHLDMMMC@splitting?5tick?5time?$AA@" = linkonce_odr dso_local unnamed_addr constant [20 x i8] c"splitting tick time\00", comdat, align 1
@"??_C@_07IEOHBIGJ@stopped?$AA@" = linkonce_odr dso_local unnamed_addr constant [8 x i8] c"stopped\00", comdat, align 1
@"??_C@_0P@JAPMPJJJ@?$FLticksplit?$FN?5?$CFs?$AA@" = linkonce_odr dso_local unnamed_addr constant [15 x i8] c"[ticksplit] %s\00", comdat, align 1
@"?g_curGroup@?A0xB9C01504@opf@@3IA" = internal unnamed_addr global i32 15, align 4
@"?g_setupEnd@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 0, align 8
@"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA" = internal unnamed_addr global [9 x i64] zeroinitializer, align 32
@"?g_camTs@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 0, align 8
@"?g_preTs@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 0, align 8
@"?g_win@?A0xB9C01504@opf@@3PAUWindow@?A0xB9C01504@1@A" = internal global [2 x %"struct.opf::(anonymous namespace)::Window"] zeroinitializer, align 16
@"?g_active@?A0xB9C01504@opf@@3HA" = internal unnamed_addr global i32 0, align 4
@"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A" = internal unnamed_addr global %"struct.opf::(anonymous namespace)::PercAcc" zeroinitializer, align 16
@"?g_frameExecTicks@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 0, align 8
@"?g_frameExecCalls@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 0, align 8
@"?g_nTouched@?A0xB9C01504@opf@@3IA" = internal unnamed_addr global i32 0, align 4
@"?g_touched@?A0xB9C01504@opf@@3PAPEAUEntry@?A0xB9C01504@1@A" = internal unnamed_addr global [2048 x ptr] zeroinitializer, align 16
@"?g_frameNo@?A0xB9C01504@opf@@3_KA" = internal unnamed_addr global i64 1, align 8
@"?g_tring@?A0xB9C01504@opf@@3PAUTRec@?A0xB9C01504@1@A" = internal unnamed_addr global [512 x %"struct.opf::(anonymous namespace)::TRec"] zeroinitializer, align 16
@"?g_depth@?A0xB9C01504@opf@@3HA" = internal unnamed_addr global i32 0, align 4
@"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA" = internal unnamed_addr global ptr null, align 8
@"?g_fileBytes@?A0xB9C01504@opf@@3JA" = internal unnamed_addr global i32 0, align 4
@"?g_fileFailed@?A0xB9C01504@opf@@3_NA" = internal unnamed_addr global i1 false, align 1
@"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A" = internal global { %struct.anon } zeroinitializer, align 8
@"??_C@_0BA@JFNIOLAK@string?5too?5long?$AA@" = linkonce_odr dso_local unnamed_addr constant [16 x i8] c"string too long\00", comdat, align 1
@"??_7type_info@@6B@" = external constant ptr
@"??_R0?AVbad_array_new_length@std@@@8" = linkonce_odr global %rtti.TypeDescriptor30 { ptr @"??_7type_info@@6B@", ptr null, [31 x i8] c".?AVbad_array_new_length@std@@\00" }, comdat
@__ImageBase = external dso_local constant i8
@"_CT??_R0?AVbad_array_new_length@std@@@8??0bad_array_new_length@std@@QEAA@AEBV01@@Z24" = linkonce_odr unnamed_addr constant %eh.CatchableType { i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_array_new_length@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0, i32 -1, i32 0, i32 24, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??0bad_array_new_length@std@@QEAA@AEBV01@@Z" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, section ".xdata", comdat
@"??_R0?AVbad_alloc@std@@@8" = linkonce_odr global %rtti.TypeDescriptor19 { ptr @"??_7type_info@@6B@", ptr null, [20 x i8] c".?AVbad_alloc@std@@\00" }, comdat
@"_CT??_R0?AVbad_alloc@std@@@8??0bad_alloc@std@@QEAA@AEBV01@@Z24" = linkonce_odr unnamed_addr constant %eh.CatchableType { i32 16, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_alloc@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0, i32 -1, i32 0, i32 24, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??0bad_alloc@std@@QEAA@AEBV01@@Z" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, section ".xdata", comdat
@"??_R0?AVexception@std@@@8" = linkonce_odr global %rtti.TypeDescriptor19 { ptr @"??_7type_info@@6B@", ptr null, [20 x i8] c".?AVexception@std@@\00" }, comdat
@"_CT??_R0?AVexception@std@@@8??0exception@std@@QEAA@AEBV01@@Z24" = linkonce_odr unnamed_addr constant %eh.CatchableType { i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVexception@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0, i32 -1, i32 0, i32 24, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??0exception@std@@QEAA@AEBV01@@Z" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, section ".xdata", comdat
@"_CTA3?AVbad_array_new_length@std@@" = linkonce_odr unnamed_addr constant %eh.CatchableTypeArray.3 { i32 3, [3 x i32] [i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"_CT??_R0?AVbad_array_new_length@std@@@8??0bad_array_new_length@std@@QEAA@AEBV01@@Z24" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"_CT??_R0?AVbad_alloc@std@@@8??0bad_alloc@std@@QEAA@AEBV01@@Z24" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"_CT??_R0?AVexception@std@@@8??0exception@std@@QEAA@AEBV01@@Z24" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32)] }, section ".xdata", comdat
@"_TI3?AVbad_array_new_length@std@@" = linkonce_odr unnamed_addr constant %eh.ThrowInfo { i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??1exception@std@@UEAA@XZ" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"_CTA3?AVbad_array_new_length@std@@" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, section ".xdata", comdat
@"??_C@_0BF@KINCDENJ@bad?5array?5new?5length?$AA@" = linkonce_odr dso_local unnamed_addr constant [21 x i8] c"bad array new length\00", comdat, align 1
@0 = private unnamed_addr constant { [3 x ptr] } { [3 x ptr] [ptr @"??_R4bad_array_new_length@std@@6B@", ptr @"??_Gbad_array_new_length@std@@UEAAPEAXI@Z", ptr @"?what@exception@std@@UEBAPEBDXZ"] }, comdat($"??_7bad_array_new_length@std@@6B@")
@"??_R4bad_array_new_length@std@@6B@" = linkonce_odr constant %rtti.CompleteObjectLocator { i32 1, i32 0, i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_array_new_length@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3bad_array_new_length@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R4bad_array_new_length@std@@6B@" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R3bad_array_new_length@std@@8" = linkonce_odr constant %rtti.ClassHierarchyDescriptor { i32 0, i32 0, i32 3, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R2bad_array_new_length@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R2bad_array_new_length@std@@8" = linkonce_odr constant [4 x i32] [i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@bad_array_new_length@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@bad_alloc@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0], comdat
@"??_R1A@?0A@EA@bad_array_new_length@std@@8" = linkonce_odr constant %rtti.BaseClassDescriptor { i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_array_new_length@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 2, i32 0, i32 -1, i32 0, i32 64, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3bad_array_new_length@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R1A@?0A@EA@bad_alloc@std@@8" = linkonce_odr constant %rtti.BaseClassDescriptor { i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_alloc@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 1, i32 0, i32 -1, i32 0, i32 64, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3bad_alloc@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R3bad_alloc@std@@8" = linkonce_odr constant %rtti.ClassHierarchyDescriptor { i32 0, i32 0, i32 2, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R2bad_alloc@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R2bad_alloc@std@@8" = linkonce_odr constant [3 x i32] [i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@bad_alloc@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0], comdat
@"??_R1A@?0A@EA@exception@std@@8" = linkonce_odr constant %rtti.BaseClassDescriptor { i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVexception@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0, i32 0, i32 -1, i32 0, i32 64, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R3exception@std@@8" = linkonce_odr constant %rtti.ClassHierarchyDescriptor { i32 0, i32 0, i32 1, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R2exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_R2exception@std@@8" = linkonce_odr constant [2 x i32] [i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R1A@?0A@EA@exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 0], comdat
@1 = private unnamed_addr constant { [3 x ptr] } { [3 x ptr] [ptr @"??_R4bad_alloc@std@@6B@", ptr @"??_Gbad_alloc@std@@UEAAPEAXI@Z", ptr @"?what@exception@std@@UEBAPEBDXZ"] }, comdat($"??_7bad_alloc@std@@6B@")
@"??_R4bad_alloc@std@@6B@" = linkonce_odr constant %rtti.CompleteObjectLocator { i32 1, i32 0, i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVbad_alloc@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3bad_alloc@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R4bad_alloc@std@@6B@" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@2 = private unnamed_addr constant { [3 x ptr] } { [3 x ptr] [ptr @"??_R4exception@std@@6B@", ptr @"??_Gexception@std@@UEAAPEAXI@Z", ptr @"?what@exception@std@@UEBAPEBDXZ"] }, comdat($"??_7exception@std@@6B@")
@"??_R4exception@std@@6B@" = linkonce_odr constant %rtti.CompleteObjectLocator { i32 1, i32 0, i32 0, i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R0?AVexception@std@@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R3exception@std@@8" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32), i32 trunc (i64 sub nuw nsw (i64 ptrtoint (ptr @"??_R4exception@std@@6B@" to i64), i64 ptrtoint (ptr @__ImageBase to i64)) to i32) }, comdat
@"??_C@_0BC@EOODALEL@Unknown?5exception?$AA@" = linkonce_odr dso_local unnamed_addr constant [18 x i8] c"Unknown exception\00", comdat, align 1
@"??_C@_09GNNAFPDF@not?5found?$AA@" = linkonce_odr dso_local unnamed_addr constant [10 x i8] c"not found\00", comdat, align 1
@"??_C@_09BCDCAHEC@ambiguous?$AA@" = linkonce_odr dso_local unnamed_addr constant [10 x i8] c"ambiguous\00", comdat, align 1
@"??_C@_0BN@NJLBEKLK@?$FLticksplit?$FN?5?$CFs?5?$CFs?3?5not?5timed?$AA@" = linkonce_odr dso_local unnamed_addr constant [29 x i8] c"[ticksplit] %s %s: not timed\00", comdat, align 1
@"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs" = private unnamed_addr constant [6 x i8] c"\FF%\00\00\00\00", align 1
@"?g_child@?A0xB9C01504@opf@@3PA_KA" = internal unnamed_addr global [32 x i64] zeroinitializer, align 16
@"?g_off@?A0xB9C01504@opf@@3PAUOffKind@?A0xB9C01504@1@A" = internal global [64 x %"struct.opf::(anonymous namespace)::OffKind"] zeroinitializer, align 16
@"?g_offOverflowCalls@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A" = internal global { %"struct.std::_Atomic_padded.11" } zeroinitializer, align 8
@"?g_offOverflowTicks@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A" = internal global { %"struct.std::_Atomic_padded.11" } zeroinitializer, align 8
@"?g_kinds@?A0xB9C01504@opf@@3PAUKindState@?A0xB9C01504@1@A" = internal unnamed_addr global [256 x %"struct.opf::(anonymous namespace)::KindState"] zeroinitializer, align 16
@"__const.??R<lambda_0>@?0??InstallTickSplit@opf@@YA_N_NPEB_W@Z@QEBA?A?<auto>@@AEAPEAEPEAE_KPEBD@Z.code" = private unnamed_addr constant <{ i8, [15 x i8] }> <{ i8 -24, [15 x i8] zeroinitializer }>, align 16
@"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A" = internal global { %"struct.std::_Atomic_padded" } zeroinitializer, align 1
@"?g_percOn@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A" = internal global { %"struct.std::_Atomic_padded" } zeroinitializer, align 1
@"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A" = internal global { %"struct.std::_Atomic_padded.11" } zeroinitializer, align 8
@"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A" = internal global { %"struct.std::_Atomic_padded.11" } zeroinitializer, align 8
@"?g_tdropped@?A0xB9C01504@opf@@3U?$atomic@I@std@@A" = internal global { %"struct.std::_Atomic_padded.16" } zeroinitializer, align 4
@"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A" = internal global { %"struct.std::_Atomic_padded.21" } { %"struct.std::_Atomic_padded.21" { i32 -1 } }, align 4
@"??_C@_1O@GLCFMFBP@?$AA?4?$AA1?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i16] [i16 46, i16 49, i16 46, i16 99, i16 115, i16 118, i16 0], comdat, align 2
@"??_C@_13CIFDLIMG@?$AAw?$AA?$AA@" = linkonce_odr dso_local unnamed_addr constant [2 x i16] [i16 119, i16 0], comdat, align 2
@"??_C@_0CB@HDKOBCJ@?$FLticksplit?$FN?5could?5not?5create?5?$CFls@" = linkonce_odr dso_local unnamed_addr constant [33 x i8] c"[ticksplit] could not create %ls\00", comdat, align 1
@"??_C@_0EMA@BFPHIDFE@?$CD?5OblivionPerfFix?9ticksplit?5v1?0?5@" = linkonce_odr dso_local unnamed_addr constant [1216 x i8] c"# OblivionPerfFix-ticksplit v1, OblivionPerfFix 1.2.4, pid=%lu, qpc_freq=%lld; read with tools/tick_split.py; 2 s windows; groups: 0-7 TG_PrePhysics..TG_NewlySpawned (the group being released), 15 outside a release, 16 tickable, 17-19 timer delegates (17 native: fn = the bound method, else the delegate vtable; 18 dynamic: class::function; 19 TFunction: fn = invoker)\0A#W,end_ms,seconds,frames,slow_frames,period_ms,actor_ms,pair_ms,tg0_ms,tg1_ms,tg2_ms,tg3_ms,tg4_ms,tg5_ms,tg6_ms,tg7_ms,exec_calls,exec_ms,overflow_calls,overflow_ms,entries,b_actorstart_ms,b_setup_ms,b_startframe_ms,b_colltree_ms,b_latent_ms,b_timers_ms,b_tickables_ms,b_camera_ms,b_streaming_ms\0A#E,end_ms,group,actual_group,fn_rva,class,calls,ms,max_ms\0A#O,end_ms,fn_rva,calls,ms\0A#T,frame,end_ms,period_ms,exec_calls,exec_ms,{group,fn_rva,class,ms}x3,b_actorstart_ms..b_streaming_ms\0A#P,end_ms,enabled_frames,stage,calls,ms,max_ms (whole/los inclusive; rest derived per call; ignore=9 gather/add calls)\0A#Q,end_ms,enabled_frames,checks_0traces,checks_1trace,checks_2traces,checks_3traces,visible,invisible,trace1_hits,trace1_blocking,trace1_penetrating,trace2_hits,trace2_blocking,trace2_penetrating,trace3_hits,trace3_blocking,trace3_penetrating\0A\00", comdat, align 1
@"??_C@_0CK@JNAPDPCD@?$FLticksplit?$FN?5writing?5the?5tick?5spl@" = linkonce_odr dso_local unnamed_addr constant [42 x i8] c"[ticksplit] writing the tick split to %ls\00", comdat, align 1
@"??_C@_0BI@CFPLBAOH@invalid?5string?5position?$AA@" = linkonce_odr dso_local unnamed_addr constant [24 x i8] c"invalid string position\00", comdat, align 1
@"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA" = linkonce_odr dso_local global i64 0, comdat, align 8
@"?g_capLogged@?A0xB9C01504@opf@@3_NA" = internal unnamed_addr global i1 false, align 1
@"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@" = linkonce_odr dso_local unnamed_addr constant [70 x i8] c"[ticksplit] the csv reached its %ld MB cap: no more rows this session\00", comdat, align 1
@"??_C@_0BJ@PPABGLFN@T?0?$CFllu?0?$CF?43f?0?$CF?43f?0?$CFu?0?$CF?43f?$AA@" = linkonce_odr dso_local unnamed_addr constant [25 x i8] c"T,%llu,%.3f,%.3f,%u,%.3f\00", comdat, align 1
@"??_C@_0BB@GOELHNLD@?0?$CFu?00x?$CFX?0?$CFs?0?$CF?43f?$AA@" = linkonce_odr dso_local unnamed_addr constant [17 x i8] c",%u,0x%X,%s,%.3f\00", comdat, align 1
@"??_C@_04NPGOAOEL@?0?0?0?0?$AA@" = linkonce_odr dso_local unnamed_addr constant [5 x i8] c",,,,\00", comdat, align 1
@"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c",%.3f\00", comdat, align 1
@"??_C@_01EEMJAFIK@?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [2 x i8] c"\0A\00", comdat, align 1
@"??_C@_0M@OAJNJFNP@vt?3exe?$CL0x?$CFX?$AA@" = linkonce_odr dso_local unnamed_addr constant [12 x i8] c"vt:exe+0x%X\00", comdat, align 1
@"??_C@_05BBDLBDLH@vt?3?$CFp?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c"vt:%p\00", comdat, align 1
@"?g_poolSearched@?A0xB9C01504@opf@@3_NA" = internal unnamed_addr global i1 false, align 1
@"?g_pool@?A0xB9C01504@opf@@3PEBEEB" = internal unnamed_addr global ptr null, align 8
@"??_C@_0CD@KKPKGCCK@?$FLticksplit?$FN?5FName?5pool?5at?5exe?$CL0x@" = linkonce_odr dso_local unnamed_addr constant [35 x i8] c"[ticksplit] FName pool at exe+0x%X\00", comdat, align 1
@"??_C@_0DP@HKEOIGNE@?$FLticksplit?$FN?5FName?5pool?5not?5found@" = linkonce_odr dso_local unnamed_addr constant [63 x i8] c"[ticksplit] FName pool not found: classes written as addresses\00", comdat, align 1
@"??_C@_06JHKGMGPP@cls?3?$CFp?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i8] c"cls:%p\00", comdat, align 1
@"??_C@_04OHJIHAFH@None?$AA@" = linkonce_odr dso_local unnamed_addr constant [5 x i8] c"None\00", comdat, align 1
@"??_C@_03CBBLDGKP@_?$CFu?$AA@" = linkonce_odr dso_local unnamed_addr constant [4 x i8] c"_%u\00", comdat, align 1
@"??_C@_0BL@GOIGLPKN@unordered_map?1set?5too?5long?$AA@" = linkonce_odr dso_local unnamed_addr constant [27 x i8] c"unordered_map/set too long\00", comdat, align 1
@"??_C@_0BK@OGNNAFAB@invalid?5hash?5bucket?5count?$AA@" = linkonce_odr dso_local unnamed_addr constant [26 x i8] c"invalid hash bucket count\00", comdat, align 1
@"??_C@_0CF@KMOIDJIM@W?0?$CF?43f?0?$CF?43f?0?$CFllu?0?$CFllu?0?$CF?43f?0?$CF?43f?0@" = linkonce_odr dso_local unnamed_addr constant [37 x i8] c"W,%.3f,%.3f,%llu,%llu,%.3f,%.3f,%.3f\00", comdat, align 1
@"??_C@_0BI@EJEDBKLJ@?0?$CFllu?0?$CF?43f?0?$CFllu?0?$CF?43f?0?$CFu?$AA@" = linkonce_odr dso_local unnamed_addr constant [24 x i8] c",%llu,%.3f,%llu,%.3f,%u\00", comdat, align 1
@"?kPercNames@?A0xB9C01504@opf@@3QBQEBDB" = internal unnamed_addr constant [10 x ptr] [ptr @"??_C@_05MLFKBFFK@whole?$AA@", ptr @"??_C@_04DONFEANM@list?$AA@", ptr @"??_C@_03OINCMOHA@los?$AA@", ptr @"??_C@_06GDPEBLPA@ignore?$AA@", ptr @"??_C@_06DJNOHABK@trace1?$AA@", ptr @"??_C@_06BCPDCDNJ@trace2?$AA@", ptr @"??_C@_06LOIBCJI@trace3?$AA@", ptr @"??_C@_08BIDMIFAH@los_rest?$AA@", ptr @"??_C@_08BPLPECIC@commands?$AA@", ptr @"??_C@_09HALKBBKJ@remainder?$AA@"], align 16
@"??_C@_0BP@ECEGIOMC@P?0?$CF?43f?0?$CFllu?0?$CFs?0?$CFllu?0?$CF?46f?0?$CF?46f?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [31 x i8] c"P,%.3f,%llu,%s,%llu,%.6f,%.6f\0A\00", comdat, align 1
@"??_C@_0M@LECLBMHC@Q?0?$CF?43f?0?$CFllu?$AA@" = linkonce_odr dso_local unnamed_addr constant [12 x i8] c"Q,%.3f,%llu\00", comdat, align 1
@"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c",%llu\00", comdat, align 1
@"??_C@_0L@CJPDDBCK@?0?$CFllu?0?$CFllu?$AA@" = linkonce_odr dso_local unnamed_addr constant [11 x i8] c",%llu,%llu\00", comdat, align 1
@"??_C@_0BA@CLBIGIHG@?0?$CFllu?0?$CFllu?0?$CFllu?$AA@" = linkonce_odr dso_local unnamed_addr constant [16 x i8] c",%llu,%llu,%llu\00", comdat, align 1
@"??_C@_0CD@CCJMPANC@E?0?$CF?43f?0?$CFu?0?$CFd?00x?$CFX?0?$CFs?0?$CFu?0?$CF?44f?0?$CF?44@" = linkonce_odr dso_local unnamed_addr constant [35 x i8] c"E,%.3f,%u,%d,0x%X,%s,%u,%.4f,%.4f\0A\00", comdat, align 1
@"?g_offLastCalls@?A0xB9C01504@opf@@3PA_KA" = internal unnamed_addr global [64 x i64] zeroinitializer, align 16
@"?g_offLastTicks@?A0xB9C01504@opf@@3PA_KA" = internal unnamed_addr global [64 x i64] zeroinitializer, align 16
@"??_C@_0BH@PLKFBJEJ@O?0?$CF?43f?00x?$CFX?0?$CFllu?0?$CF?44f?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [23 x i8] c"O,%.3f,0x%X,%llu,%.4f\0A\00", comdat, align 1
@"??_C@_05MLFKBFFK@whole?$AA@" = linkonce_odr dso_local unnamed_addr constant [6 x i8] c"whole\00", comdat, align 1
@"??_C@_04DONFEANM@list?$AA@" = linkonce_odr dso_local unnamed_addr constant [5 x i8] c"list\00", comdat, align 1
@"??_C@_03OINCMOHA@los?$AA@" = linkonce_odr dso_local unnamed_addr constant [4 x i8] c"los\00", comdat, align 1
@"??_C@_06GDPEBLPA@ignore?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i8] c"ignore\00", comdat, align 1
@"??_C@_06DJNOHABK@trace1?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i8] c"trace1\00", comdat, align 1
@"??_C@_06BCPDCDNJ@trace2?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i8] c"trace2\00", comdat, align 1
@"??_C@_06LOIBCJI@trace3?$AA@" = linkonce_odr dso_local unnamed_addr constant [7 x i8] c"trace3\00", comdat, align 1
@"??_C@_08BIDMIFAH@los_rest?$AA@" = linkonce_odr dso_local unnamed_addr constant [9 x i8] c"los_rest\00", comdat, align 1
@"??_C@_08BPLPECIC@commands?$AA@" = linkonce_odr dso_local unnamed_addr constant [9 x i8] c"commands\00", comdat, align 1
@"??_C@_09HALKBBKJ@remainder?$AA@" = linkonce_odr dso_local unnamed_addr constant [10 x i8] c"remainder\00", comdat, align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @_GLOBAL__sub_I_tick_split.cpp, ptr null }]

@"??_7bad_array_new_length@std@@6B@" = unnamed_addr alias ptr, getelementptr inbounds ({ [3 x ptr] }, ptr @0, i32 0, i32 0, i32 1)
@"??_7bad_alloc@std@@6B@" = unnamed_addr alias ptr, getelementptr inbounds ({ [3 x ptr] }, ptr @1, i32 0, i32 0, i32 1)
@"??_7exception@std@@6B@" = unnamed_addr alias ptr, getelementptr inbounds ({ [3 x ptr] }, ptr @2, i32 0, i32 0, i32 1)

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %0) unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %32

2:                                                ; preds = %1
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %4 = load i64, ptr %3, align 8
  %5 = icmp ugt i64 %4, 7
  br i1 %5, label %6, label %25

6:                                                ; preds = %2
  %7 = load ptr, ptr %0, align 8
  %8 = shl i64 %4, 1
  %9 = add i64 %8, 2
  %10 = icmp ugt i64 %9, 4095
  br i1 %10, label %11, label %22

11:                                               ; preds = %6
  %12 = getelementptr inbounds i8, ptr %7, i64 -8
  %13 = load i64, ptr %12, align 8
  %14 = ptrtoint ptr %7 to i64
  %15 = add i64 %14, -8
  %16 = sub i64 %15, %13
  %17 = icmp ult i64 %16, 32
  br i1 %17, label %19, label %18

18:                                               ; preds = %11
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

19:                                               ; preds = %11
  %20 = add i64 %8, 41
  %21 = inttoptr i64 %13 to ptr
  br label %22

22:                                               ; preds = %19, %6
  %23 = phi i64 [ %20, %19 ], [ %9, %6 ]
  %24 = phi ptr [ %21, %19 ], [ %7, %6 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %24, i64 noundef %23) #30
  br label %25

25:                                               ; preds = %2, %22
  %26 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 0, ptr %26, align 8
  store i64 7, ptr %3, align 8
  store i16 0, ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %27 unwind label %32

27:                                               ; preds = %25
  invoke void @llvm.seh.scope.begin()
          to label %28 unwind label %29

28:                                               ; preds = %27
  invoke void @llvm.seh.scope.end()
          to label %31 unwind label %29

29:                                               ; preds = %28, %27
  %30 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %30 unwind to caller

31:                                               ; preds = %28
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  ret void

32:                                               ; preds = %25, %1
  %33 = cleanuppad within none []
  invoke void @llvm.seh.scope.begin()
          to label %34 unwind label %35

34:                                               ; preds = %32
  invoke void @llvm.seh.scope.end()
          to label %37 unwind label %35

35:                                               ; preds = %34, %32
  %36 = cleanuppad within %33 []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %36 unwind to caller

37:                                               ; preds = %34
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %33 unwind to caller
}

; Function Attrs: sspstrong uwtable
define internal void @"??__Fg_path@?A0xB9C01504@opf@@YAXXZ"() #1 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %1 unwind label %28

1:                                                ; preds = %0
  %2 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %3 = icmp ugt i64 %2, 7
  br i1 %3, label %4, label %23

4:                                                ; preds = %1
  %5 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %6 = shl i64 %2, 1
  %7 = add i64 %6, 2
  %8 = icmp ugt i64 %7, 4095
  br i1 %8, label %9, label %20

9:                                                ; preds = %4
  %10 = getelementptr inbounds i8, ptr %5, i64 -8
  %11 = load i64, ptr %10, align 8
  %12 = ptrtoint ptr %5 to i64
  %13 = add i64 %12, -8
  %14 = sub i64 %13, %11
  %15 = icmp ult i64 %14, 32
  br i1 %15, label %17, label %16

16:                                               ; preds = %9
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

17:                                               ; preds = %9
  %18 = add i64 %6, 41
  %19 = inttoptr i64 %11 to ptr
  br label %20

20:                                               ; preds = %17, %4
  %21 = phi i64 [ %18, %17 ], [ %7, %4 ]
  %22 = phi ptr [ %19, %17 ], [ %5, %4 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %22, i64 noundef %21) #30
  br label %23

23:                                               ; preds = %20, %1
  store i64 0, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 16), align 8
  store i64 7, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  store i16 0, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  invoke void @llvm.seh.scope.end()
          to label %24 unwind label %28

24:                                               ; preds = %23
  invoke void @llvm.seh.scope.begin()
          to label %25 unwind label %26

25:                                               ; preds = %24
  invoke void @llvm.seh.scope.end()
          to label %34 unwind label %26

26:                                               ; preds = %25, %24
  %27 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %27 unwind to caller

28:                                               ; preds = %23, %0
  %29 = cleanuppad within none []
  invoke void @llvm.seh.scope.begin()
          to label %30 unwind label %31

30:                                               ; preds = %28
  invoke void @llvm.seh.scope.end()
          to label %33 unwind label %31

31:                                               ; preds = %30, %28
  %32 = cleanuppad within %29 []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %32 unwind to caller

33:                                               ; preds = %30
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %29 unwind to caller

34:                                               ; preds = %25
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  ret void
}

; Function Attrs: nofree nounwind
declare dso_local i32 @atexit(ptr) local_unnamed_addr #2

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(64) %0) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %47

2:                                                ; preds = %1
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %43

3:                                                ; preds = %2
  invoke void @llvm.seh.scope.end()
          to label %4 unwind label %43

4:                                                ; preds = %3
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %6 = load ptr, ptr %5, align 8
  %7 = icmp eq ptr %6, null
  br i1 %7, label %28, label %8

8:                                                ; preds = %4
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %10 = load ptr, ptr %9, align 8
  %11 = ptrtoint ptr %10 to i64
  %12 = ptrtoint ptr %6 to i64
  %13 = sub i64 %11, %12
  %14 = icmp ugt i64 %13, 4095
  br i1 %14, label %15, label %25

15:                                               ; preds = %8
  %16 = getelementptr inbounds i8, ptr %6, i64 -8
  %17 = load i64, ptr %16, align 8
  %18 = add i64 %12, -8
  %19 = sub i64 %18, %17
  %20 = icmp ult i64 %19, 32
  br i1 %20, label %22, label %21

21:                                               ; preds = %15
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

22:                                               ; preds = %15
  %23 = add i64 %13, 39
  %24 = inttoptr i64 %17 to ptr
  br label %25

25:                                               ; preds = %22, %8
  %26 = phi i64 [ %23, %22 ], [ %13, %8 ]
  %27 = phi ptr [ %24, %22 ], [ %6, %8 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %27, i64 noundef %26) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %5, i8 0, i64 24, i1 false)
  br label %28

28:                                               ; preds = %4, %25
  invoke void @llvm.seh.scope.end()
          to label %29 unwind label %47

29:                                               ; preds = %28
  %30 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %31 = load ptr, ptr %30, align 8
  %32 = getelementptr inbounds nuw i8, ptr %31, i64 8
  %33 = load ptr, ptr %32, align 8
  store ptr null, ptr %33, align 8
  %34 = load ptr, ptr %31, align 8
  %35 = icmp eq ptr %34, null
  br i1 %35, label %41, label %36

36:                                               ; preds = %29, %36
  %37 = phi ptr [ %38, %36 ], [ %34, %29 ]
  %38 = load ptr, ptr %37, align 8
  %39 = getelementptr inbounds nuw i8, ptr %37, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %39) #30
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %37, i64 noundef 56) #30
  %40 = icmp eq ptr %38, null
  br i1 %40, label %41, label %36, !llvm.loop !18

41:                                               ; preds = %36, %29
  %42 = load ptr, ptr %30, align 8
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %42, i64 noundef 56) #30
  ret void

43:                                               ; preds = %3, %2
  %44 = cleanuppad within none []
  invoke void @llvm.seh.scope.end() [ "funclet"(token %44) ]
          to label %45 unwind label %47

45:                                               ; preds = %43
  %46 = getelementptr inbounds nuw i8, ptr %0, i64 24
  call void @"??1?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %46) #30 [ "funclet"(token %44) ]
  cleanupret from %44 unwind label %47

47:                                               ; preds = %28, %45, %43, %1
  %48 = cleanuppad within none []
  %49 = getelementptr inbounds nuw i8, ptr %0, i64 8
  call void @"??1?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(16) %49) #30 [ "funclet"(token %48) ]
  cleanupret from %48 unwind to caller
}

; Function Attrs: nounwind sspstrong uwtable
define internal void @"??__Fg_names@?A0xB9C01504@opf@@YAXXZ"() #4 {
  tail call void @"??1?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ"(ptr @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A")
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define dso_local noundef zeroext i1 @"?InstallTickSplit@opf@@YA_N_NPEB_W@Z"(i1 noundef zeroext %0, ptr noundef %1) local_unnamed_addr #5 personality ptr @__CxxFrameHandler3 {
  %3 = alloca i32, align 4
  %4 = alloca %"class.std::span", align 8
  %5 = alloca [16 x i8], align 16
  %6 = alloca %"class.std::span", align 8
  %7 = alloca [16 x i8], align 16
  %8 = alloca %"class.std::span", align 8
  %9 = alloca [16 x i8], align 16
  %10 = alloca %"class.std::span", align 8
  %11 = alloca %"class.std::basic_string", align 8
  %12 = alloca %"class.std::basic_string", align 8
  %13 = alloca i32, align 4
  %14 = alloca [6 x i8], align 1
  %15 = alloca %"class.std::span", align 8
  %16 = alloca [11 x i8], align 1
  %17 = alloca %"class.std::span", align 8
  %18 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %19 = trunc nuw i8 %18 to i1
  br i1 %19, label %528, label %20

20:                                               ; preds = %2
  %21 = tail call i32 @QueryPerformanceFrequency(ptr noundef nonnull @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A")
  %22 = icmp eq ptr %1, null
  br i1 %22, label %107, label %23

23:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %11) #30
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %12) #30
  %24 = call noundef ptr @"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@QEB_W@Z"(ptr noundef nonnull align 8 dereferenceable(32) %12, ptr noundef nonnull %1)
  invoke void @llvm.seh.scope.begin()
          to label %25 unwind label %105

25:                                               ; preds = %23
  %26 = getelementptr inbounds nuw i8, ptr %12, i64 16
  %27 = load i64, ptr %26, align 8, !noalias !22
  %28 = getelementptr inbounds nuw i8, ptr %12, i64 24
  %29 = load i64, ptr %28, align 8, !noalias !22
  %30 = sub i64 %29, %27
  %31 = icmp ult i64 %30, 30
  br i1 %31, label %39, label %32

32:                                               ; preds = %25
  %33 = add i64 %27, 30
  store i64 %33, ptr %26, align 8, !noalias !22
  %34 = icmp ugt i64 %29, 7
  %35 = load ptr, ptr %12, align 8, !noalias !22
  %36 = select i1 %34, ptr %35, ptr %12
  %37 = getelementptr inbounds nuw i16, ptr %36, i64 %27
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 2 dereferenceable(60) %37, ptr noundef nonnull align 2 dereferenceable(60) @"??_C@_1DO@OMHMLJDE@?$AA?2?$AAO?$AAb?$AAl?$AAi?$AAv?$AAi?$AAo?$AAn?$AAP?$AAe?$AAr?$AAf?$AAF?$AAi?$AAx?$AA?9?$AAt?$AAi?$AAc?$AAk?$AAs?$AAp?$AAl?$AAi?$AAt?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@", i64 60, i1 false), !noalias !22
  %38 = getelementptr inbounds nuw i16, ptr %36, i64 %33
  store i16 0, ptr %38, align 2, !noalias !22
  br label %41

39:                                               ; preds = %25
  %40 = invoke noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W_K@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEB_W0@Z@PEB_W_K@Z"(ptr noundef nonnull align 8 dereferenceable(32) %12, i64 noundef 30, i8 undef, ptr noundef nonnull @"??_C@_1DO@OMHMLJDE@?$AA?2?$AAO?$AAb?$AAl?$AAi?$AAv?$AAi?$AAo?$AAn?$AAP?$AAe?$AAr?$AAf?$AAF?$AAi?$AAx?$AA?9?$AAt?$AAi?$AAc?$AAk?$AAs?$AAp?$AAl?$AAi?$AAt?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@", i64 noundef 30)
          to label %41 unwind label %105

41:                                               ; preds = %32, %39
  %42 = phi ptr [ %12, %32 ], [ %40, %39 ]
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %11, ptr noundef nonnull align 8 dereferenceable(32) %42, i64 32, i1 false)
  %43 = getelementptr inbounds nuw i8, ptr %42, i64 16
  store i64 0, ptr %43, align 8, !noalias !22
  %44 = getelementptr inbounds nuw i8, ptr %42, i64 24
  store i64 7, ptr %44, align 8, !noalias !22
  store i16 0, ptr %42, align 8, !noalias !22
  invoke void @llvm.seh.scope.begin()
          to label %45 unwind label %102

45:                                               ; preds = %41
  %46 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %47 = icmp ugt i64 %46, 7
  br i1 %47, label %48, label %67

48:                                               ; preds = %45
  %49 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %50 = shl i64 %46, 1
  %51 = add i64 %50, 2
  %52 = icmp ugt i64 %51, 4095
  br i1 %52, label %53, label %64

53:                                               ; preds = %48
  %54 = getelementptr inbounds i8, ptr %49, i64 -8
  %55 = load i64, ptr %54, align 8
  %56 = ptrtoint ptr %49 to i64
  %57 = add i64 %56, -8
  %58 = sub i64 %57, %55
  %59 = icmp ult i64 %58, 32
  br i1 %59, label %61, label %60

60:                                               ; preds = %53
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

61:                                               ; preds = %53
  %62 = add i64 %50, 41
  %63 = inttoptr i64 %55 to ptr
  br label %64

64:                                               ; preds = %61, %48
  %65 = phi i64 [ %62, %61 ], [ %51, %48 ]
  %66 = phi ptr [ %63, %61 ], [ %49, %48 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %66, i64 noundef %65) #30
  br label %67

67:                                               ; preds = %45, %64
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", ptr noundef nonnull align 8 dereferenceable(32) %11, i64 32, i1 false)
  %68 = getelementptr inbounds nuw i8, ptr %11, i64 16
  store i64 0, ptr %68, align 8
  %69 = getelementptr inbounds nuw i8, ptr %11, i64 24
  store i64 7, ptr %69, align 8
  store i16 0, ptr %11, align 8
  invoke void @llvm.seh.scope.end()
          to label %70 unwind label %102

70:                                               ; preds = %67
  invoke void @llvm.seh.scope.begin()
          to label %71 unwind label %73

71:                                               ; preds = %70
  store i64 7, ptr %69, align 8
  invoke void @llvm.seh.scope.end()
          to label %72 unwind label %73

72:                                               ; preds = %71
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  invoke void @llvm.seh.scope.end()
          to label %75 unwind label %105

73:                                               ; preds = %71, %70
  %74 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %74 unwind to caller

75:                                               ; preds = %72
  invoke void @llvm.seh.scope.begin()
          to label %76 unwind label %100

76:                                               ; preds = %75
  %77 = load i64, ptr %28, align 8
  %78 = icmp ugt i64 %77, 7
  br i1 %78, label %79, label %98

79:                                               ; preds = %76
  %80 = load ptr, ptr %12, align 8
  %81 = shl i64 %77, 1
  %82 = add i64 %81, 2
  %83 = icmp ugt i64 %82, 4095
  br i1 %83, label %84, label %95

84:                                               ; preds = %79
  %85 = getelementptr inbounds i8, ptr %80, i64 -8
  %86 = load i64, ptr %85, align 8
  %87 = ptrtoint ptr %80 to i64
  %88 = add i64 %87, -8
  %89 = sub i64 %88, %86
  %90 = icmp ult i64 %89, 32
  br i1 %90, label %92, label %91

91:                                               ; preds = %84
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

92:                                               ; preds = %84
  %93 = add i64 %81, 41
  %94 = inttoptr i64 %86 to ptr
  br label %95

95:                                               ; preds = %92, %79
  %96 = phi i64 [ %93, %92 ], [ %82, %79 ]
  %97 = phi ptr [ %94, %92 ], [ %80, %79 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %97, i64 noundef %96) #30
  br label %98

98:                                               ; preds = %95, %76
  invoke void @llvm.seh.scope.end()
          to label %99 unwind label %100

99:                                               ; preds = %98
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %12) #30
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %11) #30
  br label %107

100:                                              ; preds = %98, %75
  %101 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %101 unwind to caller

102:                                              ; preds = %67, %41
  %103 = cleanuppad within none []
  invoke void @llvm.seh.scope.end() [ "funclet"(token %103) ]
          to label %104 unwind label %105

104:                                              ; preds = %102
  call void @"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %11) #30 [ "funclet"(token %103) ]
  cleanupret from %103 unwind label %105

105:                                              ; preds = %39, %72, %104, %102, %23
  %106 = cleanuppad within none []
  call void @"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %12) #30 [ "funclet"(token %106) ]
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %12) #30
  cleanupret from %106 unwind to caller

107:                                              ; preds = %99, %20
  br i1 %0, label %109, label %108

108:                                              ; preds = %107
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0GB@FOFFKKBF@?$FLticksplit?$FN?5HitchLedgerTickSplit@")
  br label %528

109:                                              ; preds = %107
  %110 = call noundef i64 @"?LedgerClockUs@opf@@YA_KXZ"()
  %111 = icmp ne i64 %110, 0
  %112 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %113 = icmp ne ptr %112, null
  %114 = select i1 %111, i1 true, i1 %113
  br i1 %114, label %116, label %115

115:                                              ; preds = %109
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0FA@MCMEKDLE@?$FLticksplit?$FN?5HitchLedgerTickSplit@")
  br label %528

116:                                              ; preds = %109
  %117 = call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %118 = call noundef ptr @"?AllocNearGame@opf@@YAPEAE_K@Z"(i64 noundef 256)
  store ptr %118, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.11", align 8
  %119 = icmp eq ptr %118, null
  br i1 %119, label %120, label %121

120:                                              ; preds = %116
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DK@LMNCKLPI@?$FLticksplit?$FN?5no?5memory?5near?5the?5g@")
  br label %528

121:                                              ; preds = %116
  %122 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kExecSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CB@DJHBCLHN@the?5tick?5task?8s?5ExecuteTick?5call@")
  %123 = icmp eq ptr %122, null
  br i1 %123, label %128, label %124

124:                                              ; preds = %121
  %125 = getelementptr inbounds nuw i8, ptr %122, i64 20
  store ptr %125, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0", align 8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %118, ptr noundef nonnull align 1 dereferenceable(3) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.mov", i64 3, i1 false)
  %126 = getelementptr inbounds nuw i8, ptr %118, i64 3
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %126, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %127 = getelementptr inbounds nuw i8, ptr %118, i64 9
  store ptr @"?ExecHook@?A0xB9C01504@opf@@YAXPEAXMHHPEBX@Z", ptr %127, align 1
  br label %128

128:                                              ; preds = %124, %121
  %129 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kTickableSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0BH@IGFJAIEK@TickObjects?8?5Tick?5call?$AA@")
  %130 = icmp eq ptr %129, null
  br i1 %130, label %136, label %131

131:                                              ; preds = %128
  %132 = getelementptr inbounds nuw i8, ptr %129, i64 13
  store ptr %132, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1", align 8
  %133 = getelementptr inbounds nuw i8, ptr %118, i64 32
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %133, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre", i64 6, i1 false)
  %134 = getelementptr inbounds nuw i8, ptr %118, i64 38
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %134, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %135 = getelementptr inbounds nuw i8, ptr %118, i64 44
  store ptr @"?TickableHook@?A0xB9C01504@opf@@YAXPEAXM@Z", ptr %135, align 1
  br label %136

136:                                              ; preds = %131, %128
  %137 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kTimerNative@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CC@CFKFCEJK@the?5timer?5manager?8s?5delegate?5cal@")
  %138 = icmp eq ptr %137, null
  br i1 %138, label %147, label %139

139:                                              ; preds = %136
  %140 = getelementptr inbounds nuw i8, ptr %137, i64 6
  store ptr %140, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8", align 8
  %141 = getelementptr inbounds nuw i8, ptr %137, i64 15
  %142 = load i8, ptr %141, align 1
  %143 = zext i8 %142 to i32
  store i32 %143, ptr @"?g_nativeSlot@?A0xB9C01504@opf@@3IA", align 4
  %144 = getelementptr inbounds nuw i8, ptr %118, i64 160
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(7) %144, ptr noundef nonnull align 1 dereferenceable(7) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre.1", i64 7, i1 false)
  %145 = getelementptr inbounds nuw i8, ptr %118, i64 167
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %145, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %146 = getelementptr inbounds nuw i8, ptr %118, i64 173
  store ptr @"?TimerNativeHook@?A0xB9C01504@opf@@YAXPEAX00@Z", ptr %146, align 1
  br label %147

147:                                              ; preds = %139, %136
  %148 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kTimerDynamic@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CG@BBFGHKOI@the?5timer?5manager?8s?5ProcessEvent@")
  %149 = icmp eq ptr %148, null
  br i1 %149, label %162, label %150

150:                                              ; preds = %147
  %151 = getelementptr inbounds nuw i8, ptr %148, i64 12
  store ptr %151, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  %152 = getelementptr inbounds nuw i8, ptr %148, i64 15
  %153 = load i32, ptr %152, align 1
  store i32 %153, ptr @"?g_peSlot@?A0xB9C01504@opf@@3IA", align 4
  %154 = icmp ult i32 %153, 4097
  %155 = and i32 %153, 7
  %156 = icmp eq i32 %155, 0
  %157 = and i1 %154, %156
  br i1 %157, label %159, label %158

158:                                              ; preds = %150
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  br label %162

159:                                              ; preds = %150
  %160 = getelementptr inbounds nuw i8, ptr %118, i64 192
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %160, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %161 = getelementptr inbounds nuw i8, ptr %118, i64 198
  store ptr @"?TimerDynamicHook@?A0xB9C01504@opf@@YAXPEAX00@Z", ptr %161, align 1
  br label %162

162:                                              ; preds = %158, %159, %147
  %163 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kTimerCallback@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CD@EOFGHCKA@the?5timer?5manager?8s?5TFunction?5ca@")
  %164 = icmp eq ptr %163, null
  br i1 %164, label %170, label %165

165:                                              ; preds = %162
  %166 = getelementptr inbounds nuw i8, ptr %163, i64 6
  store ptr %166, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10", align 8
  %167 = getelementptr inbounds nuw i8, ptr %118, i64 224
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(9) %167, ptr noundef nonnull align 1 dereferenceable(9) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.pre.2", i64 9, i1 false)
  %168 = getelementptr inbounds nuw i8, ptr %118, i64 233
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %168, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %169 = getelementptr inbounds nuw i8, ptr %118, i64 239
  store ptr @"?TimerCallbackHook@?A0xB9C01504@opf@@YAXPEAX00@Z", ptr %169, align 1
  br label %170

170:                                              ; preds = %165, %162
  %171 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kTimerSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CJ@MIHNDPNJ@UWorld?3?3Tick?8s?5timer?5and?5tickabl@")
  %172 = getelementptr inbounds nuw i8, ptr %117, i64 8
  %173 = getelementptr inbounds nuw i8, ptr %117, i64 16
  %174 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kSetupSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CO@MLPLNNMG@UWorld?3?3Tick?8s?5SetupPhysicsTickF@")
  %175 = icmp eq ptr %174, null
  br i1 %175, label %193, label %176

176:                                              ; preds = %170
  %177 = getelementptr inbounds nuw i8, ptr %118, i64 64
  %178 = getelementptr inbounds nuw i8, ptr %174, i64 6
  %179 = load i8, ptr %178, align 1
  %180 = icmp eq i8 %179, -24
  br i1 %180, label %181, label %191

181:                                              ; preds = %176
  %182 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %178, i64 noundef 1, i64 noundef 5)
  %183 = load ptr, ptr %172, align 8
  %184 = icmp uge ptr %182, %183
  %185 = load ptr, ptr %173, align 8
  %186 = icmp ult ptr %182, %185
  %187 = select i1 %184, i1 %186, i1 false
  br i1 %187, label %188, label %191

188:                                              ; preds = %181
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %177, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %189 = getelementptr inbounds nuw i8, ptr %118, i64 70
  store ptr @"?SetupHook@?A0xB9C01504@opf@@YAXPEAXM@Z", ptr %189, align 1
  %190 = icmp eq ptr %182, null
  br i1 %190, label %191, label %192

191:                                              ; preds = %181, %176, %188
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_0CO@MLPLNNMG@UWorld?3?3Tick?8s?5SetupPhysicsTickF@")
  br label %193

192:                                              ; preds = %188
  store ptr %182, ptr @"?g_setupOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  store ptr %178, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2", align 8
  br label %193

193:                                              ; preds = %191, %192, %170
  %194 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kCollSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CP@NHCICKLN@UWorld?3?3Tick?8s?5EnsureCollisionTr@")
  %195 = icmp eq ptr %194, null
  br i1 %195, label %213, label %196

196:                                              ; preds = %193
  %197 = getelementptr inbounds nuw i8, ptr %118, i64 80
  %198 = getelementptr inbounds nuw i8, ptr %194, i64 7
  %199 = load i8, ptr %198, align 1
  %200 = icmp eq i8 %199, -24
  br i1 %200, label %201, label %212

201:                                              ; preds = %196
  %202 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %198, i64 noundef 1, i64 noundef 5)
  %203 = load ptr, ptr %172, align 8
  %204 = icmp uge ptr %202, %203
  %205 = load ptr, ptr %173, align 8
  %206 = icmp ult ptr %202, %205
  %207 = select i1 %204, i1 %206, i1 false
  br i1 %207, label %208, label %212

208:                                              ; preds = %201
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %197, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %209 = getelementptr inbounds nuw i8, ptr %118, i64 86
  store ptr @"?CollHook@?A0xB9C01504@opf@@YAXPEAX@Z", ptr %209, align 1
  %210 = icmp eq ptr %202, null
  br i1 %210, label %212, label %211

211:                                              ; preds = %208
  store ptr %202, ptr @"?g_collOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  store ptr %198, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3", align 8
  br label %213

212:                                              ; preds = %208, %201, %196
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_0CP@NHCICKLN@UWorld?3?3Tick?8s?5EnsureCollisionTr@")
  br label %213

213:                                              ; preds = %212, %211, %193
  %214 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kLatentSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0CJ@MAEPLMN@UWorld?3?3Tick?8s?5ProcessLatentActi@")
  %215 = icmp eq ptr %214, null
  br i1 %215, label %233, label %216

216:                                              ; preds = %213
  %217 = getelementptr inbounds nuw i8, ptr %118, i64 96
  %218 = getelementptr inbounds nuw i8, ptr %214, i64 8
  %219 = load i8, ptr %218, align 1
  %220 = icmp eq i8 %219, -24
  br i1 %220, label %221, label %232

221:                                              ; preds = %216
  %222 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %218, i64 noundef 1, i64 noundef 5)
  %223 = load ptr, ptr %172, align 8
  %224 = icmp uge ptr %222, %223
  %225 = load ptr, ptr %173, align 8
  %226 = icmp ult ptr %222, %225
  %227 = select i1 %224, i1 %226, i1 false
  br i1 %227, label %228, label %232

228:                                              ; preds = %221
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %217, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %229 = getelementptr inbounds nuw i8, ptr %118, i64 102
  store ptr @"?LatentHook@?A0xB9C01504@opf@@YAXPEAX0M@Z", ptr %229, align 1
  %230 = icmp eq ptr %222, null
  br i1 %230, label %232, label %231

231:                                              ; preds = %228
  store ptr %222, ptr @"?g_latentOrig@?A0xB9C01504@opf@@3P6AXPEAX0M@ZEA", align 8
  store ptr %218, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4", align 8
  br label %233

232:                                              ; preds = %228, %221, %216
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_0CJ@MAEPLMN@UWorld?3?3Tick?8s?5ProcessLatentActi@")
  br label %233

233:                                              ; preds = %213, %231, %232
  %234 = icmp eq ptr %171, null
  br i1 %234, label %269, label %235

235:                                              ; preds = %233
  %236 = getelementptr inbounds nuw i8, ptr %118, i64 112
  %237 = getelementptr inbounds nuw i8, ptr %171, i64 14
  %238 = load i8, ptr %237, align 1
  %239 = icmp eq i8 %238, -24
  br i1 %239, label %240, label %251

240:                                              ; preds = %235
  %241 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %237, i64 noundef 1, i64 noundef 5)
  %242 = load ptr, ptr %172, align 8
  %243 = icmp uge ptr %241, %242
  %244 = load ptr, ptr %173, align 8
  %245 = icmp ult ptr %241, %244
  %246 = select i1 %243, i1 %245, i1 false
  br i1 %246, label %247, label %251

247:                                              ; preds = %240
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %236, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %248 = getelementptr inbounds nuw i8, ptr %118, i64 118
  store ptr @"?TimerHook@?A0xB9C01504@opf@@YAXPEAXM@Z", ptr %248, align 1
  %249 = icmp eq ptr %241, null
  br i1 %249, label %251, label %250

250:                                              ; preds = %247
  store ptr %241, ptr @"?g_timerOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  store ptr %237, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5", align 8
  br label %252

251:                                              ; preds = %247, %240, %235
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_05NAPFDJNG@timer?$AA@")
  br label %252

252:                                              ; preds = %250, %251
  %253 = getelementptr inbounds nuw i8, ptr %118, i64 128
  %254 = getelementptr inbounds nuw i8, ptr %171, i64 31
  %255 = load i8, ptr %254, align 1
  %256 = icmp eq i8 %255, -24
  br i1 %256, label %257, label %268

257:                                              ; preds = %252
  %258 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %254, i64 noundef 1, i64 noundef 5)
  %259 = load ptr, ptr %172, align 8
  %260 = icmp uge ptr %258, %259
  %261 = load ptr, ptr %173, align 8
  %262 = icmp ult ptr %258, %261
  %263 = select i1 %260, i1 %262, i1 false
  br i1 %263, label %264, label %268

264:                                              ; preds = %257
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %253, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %265 = getelementptr inbounds nuw i8, ptr %118, i64 134
  store ptr @"?TickObjectsHook@?A0xB9C01504@opf@@YAXPEAXH_NM@Z", ptr %265, align 1
  %266 = icmp eq ptr %258, null
  br i1 %266, label %268, label %267

267:                                              ; preds = %264
  store ptr %258, ptr @"?g_tickObjOrig@?A0xB9C01504@opf@@3P6AXPEAXH_NM@ZEA", align 8
  store ptr %254, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6", align 8
  br label %269

268:                                              ; preds = %264, %257, %252
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_0M@PPDPACCC@tickobjects?$AA@")
  br label %269

269:                                              ; preds = %233, %268, %267
  %270 = call fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %117, ptr noundef nonnull @"?kStreamSite@?A0xB9C01504@opf@@3QBDB", ptr noundef nonnull @"??_C@_0DB@DPPPLJPI@UWorld?3?3Tick?8s?5InternalUpdateStr@")
  %271 = icmp eq ptr %270, null
  br i1 %271, label %289, label %272

272:                                              ; preds = %269
  %273 = getelementptr inbounds nuw i8, ptr %118, i64 144
  %274 = getelementptr inbounds nuw i8, ptr %270, i64 20
  %275 = load i8, ptr %274, align 1
  %276 = icmp eq i8 %275, -24
  br i1 %276, label %277, label %288

277:                                              ; preds = %272
  %278 = call noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef nonnull %274, i64 noundef 1, i64 noundef 5)
  %279 = load ptr, ptr %172, align 8
  %280 = icmp uge ptr %278, %279
  %281 = load ptr, ptr %173, align 8
  %282 = icmp ult ptr %278, %281
  %283 = select i1 %280, i1 %282, i1 false
  br i1 %283, label %284, label %288

284:                                              ; preds = %277
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %273, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?JmpStub@?A0xB9C01504@opf@@YAXPEAEPEAX@Z.jmpAbs", i64 6, i1 false)
  %285 = getelementptr inbounds nuw i8, ptr %118, i64 150
  store ptr @"?StreamHook@?A0xB9C01504@opf@@YAXPEAX@Z", ptr %285, align 1
  %286 = icmp eq ptr %278, null
  br i1 %286, label %288, label %287

287:                                              ; preds = %284
  store ptr %278, ptr @"?g_streamOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  store ptr %274, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7", align 8
  br label %289

288:                                              ; preds = %284, %277, %272
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DJ@OLGFIOAG@?$FLticksplit?$FN?5?$CFs?3?5not?5a?5call?5to?5th@", ptr noundef nonnull @"??_C@_0DB@DPPPLJPI@UWorld?3?3Tick?8s?5InternalUpdateStr@")
  br label %289

289:                                              ; preds = %288, %287, %269
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %13) #30
  %290 = call i32 @VirtualProtect(ptr noundef nonnull %118, i64 noundef 256, i32 noundef 32, ptr noundef nonnull %13)
  %291 = call ptr @GetCurrentProcess()
  %292 = call i32 @FlushInstructionCache(ptr noundef %291, ptr noundef nonnull %118, i64 noundef 256)
  %293 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0", align 8
  %294 = icmp eq ptr %293, null
  br i1 %294, label %309, label %295

295:                                              ; preds = %289
  call void @llvm.lifetime.start.p0(i64 6, ptr nonnull %14) #30
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(6) %14, ptr noundef nonnull align 1 dereferenceable(6) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.call", i64 6, i1 false)
  %296 = getelementptr inbounds nuw i8, ptr %293, i64 5
  %297 = ptrtoint ptr %118 to i64
  %298 = ptrtoint ptr %296 to i64
  %299 = sub i64 %297, %298
  %300 = trunc i64 %299 to i32
  %301 = getelementptr inbounds nuw i8, ptr %14, i64 1
  store i32 %300, ptr %301, align 1
  %302 = add i64 %299, 2147483648
  %303 = icmp ult i64 %302, 4294967296
  br i1 %303, label %304, label %307

304:                                              ; preds = %295
  store ptr %14, ptr %15, align 8
  %305 = getelementptr inbounds nuw i8, ptr %15, i64 8
  store i64 6, ptr %305, align 8
  %306 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %293, ptr noundef nonnull %15)
  br i1 %306, label %308, label %307

307:                                              ; preds = %304, %295
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EO@PKKBIJCB@?$FLticksplit?$FN?5could?5not?5redirect?5t@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0", align 8
  br label %308

308:                                              ; preds = %307, %304
  call void @llvm.lifetime.end.p0(i64 6, ptr nonnull %14) #30
  br label %309

309:                                              ; preds = %308, %289
  %310 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1", align 8
  %311 = icmp eq ptr %310, null
  br i1 %311, label %327, label %312

312:                                              ; preds = %309
  call void @llvm.lifetime.start.p0(i64 11, ptr nonnull %16) #30
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(11) %16, ptr noundef nonnull align 1 dereferenceable(11) @"__const.?InstallTickSplit@opf@@YA_N_NPEB_W@Z.call.3", i64 11, i1 false)
  %313 = getelementptr inbounds nuw i8, ptr %118, i64 32
  %314 = getelementptr inbounds nuw i8, ptr %310, i64 5
  %315 = ptrtoint ptr %313 to i64
  %316 = ptrtoint ptr %314 to i64
  %317 = sub i64 %315, %316
  %318 = trunc i64 %317 to i32
  %319 = getelementptr inbounds nuw i8, ptr %16, i64 1
  store i32 %318, ptr %319, align 1
  %320 = add i64 %317, 2147483648
  %321 = icmp ult i64 %320, 4294967296
  br i1 %321, label %322, label %325

322:                                              ; preds = %312
  store ptr %16, ptr %17, align 8
  %323 = getelementptr inbounds nuw i8, ptr %17, i64 8
  store i64 11, ptr %323, align 8
  %324 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %310, ptr noundef nonnull %17)
  br i1 %324, label %326, label %325

325:                                              ; preds = %322, %312
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EN@BKKGNFJM@?$FLticksplit?$FN?5could?5not?5redirect?5t@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1", align 8
  br label %326

326:                                              ; preds = %325, %322
  call void @llvm.lifetime.end.p0(i64 11, ptr nonnull %16) #30
  br label %327

327:                                              ; preds = %326, %309
  %328 = getelementptr inbounds nuw i8, ptr %4, i64 8
  %329 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2", align 8
  %330 = icmp eq ptr %329, null
  br i1 %330, label %440, label %426

331:                                              ; preds = %525
  %332 = getelementptr inbounds nuw i8, ptr %118, i64 160
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %9) #30
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %9, ptr noundef nonnull align 16 dereferenceable(16) @"__const.??R<lambda_0>@?0??InstallTickSplit@opf@@YA_N_NPEB_W@Z@QEBA?A?<auto>@@AEAPEAEPEAE_KPEBD@Z.code", i64 16, i1 false)
  %333 = getelementptr inbounds nuw i8, ptr %526, i64 5
  %334 = ptrtoint ptr %332 to i64
  %335 = ptrtoint ptr %333 to i64
  %336 = sub i64 %334, %335
  %337 = trunc i64 %336 to i32
  %338 = getelementptr inbounds nuw i8, ptr %9, i64 1
  store i32 %337, ptr %338, align 1
  %339 = getelementptr inbounds nuw i8, ptr %9, i64 5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(5) %339, i8 -112, i64 5, i1 false)
  %340 = add i64 %336, 2147483648
  %341 = icmp ult i64 %340, 4294967296
  br i1 %341, label %342, label %345

342:                                              ; preds = %331
  store ptr %9, ptr %10, align 8
  %343 = getelementptr inbounds nuw i8, ptr %10, i64 8
  store i64 10, ptr %343, align 8
  %344 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %526, ptr noundef nonnull %10)
  br i1 %344, label %346, label %345

345:                                              ; preds = %342, %331
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0BK@GELKNIDE@the?5timers?8?5delegate?5call?$AA@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8", align 8
  br label %346

346:                                              ; preds = %345, %342
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %9) #30
  br label %347

347:                                              ; preds = %525, %346
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %10)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %8)
  %348 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  %349 = icmp eq ptr %348, null
  br i1 %349, label %366, label %350

350:                                              ; preds = %347
  %351 = getelementptr inbounds nuw i8, ptr %118, i64 192
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #30
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %7, ptr noundef nonnull align 16 dereferenceable(16) @"__const.??R<lambda_0>@?0??InstallTickSplit@opf@@YA_N_NPEB_W@Z@QEBA?A?<auto>@@AEAPEAEPEAE_KPEBD@Z.code", i64 16, i1 false)
  %352 = getelementptr inbounds nuw i8, ptr %348, i64 5
  %353 = ptrtoint ptr %351 to i64
  %354 = ptrtoint ptr %352 to i64
  %355 = sub i64 %353, %354
  %356 = trunc i64 %355 to i32
  %357 = getelementptr inbounds nuw i8, ptr %7, i64 1
  store i32 %356, ptr %357, align 1
  %358 = getelementptr inbounds nuw i8, ptr %7, i64 5
  store i16 -28528, ptr %358, align 1
  %359 = add i64 %355, 2147483648
  %360 = icmp ult i64 %359, 4294967296
  br i1 %360, label %361, label %364

361:                                              ; preds = %350
  store ptr %7, ptr %8, align 8
  %362 = getelementptr inbounds nuw i8, ptr %8, i64 8
  store i64 7, ptr %362, align 8
  %363 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %348, ptr noundef nonnull %8)
  br i1 %363, label %365, label %364

364:                                              ; preds = %361, %350
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0BO@MMLNOBPC@the?5timers?8?5ProcessEvent?5call?$AA@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  br label %365

365:                                              ; preds = %364, %361
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #30
  br label %366

366:                                              ; preds = %347, %365
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6)
  %367 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10", align 8
  %368 = icmp eq ptr %367, null
  br i1 %368, label %389, label %369

369:                                              ; preds = %366
  %370 = getelementptr inbounds nuw i8, ptr %118, i64 224
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #30
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, ptr noundef nonnull align 16 dereferenceable(16) @"__const.??R<lambda_0>@?0??InstallTickSplit@opf@@YA_N_NPEB_W@Z@QEBA?A?<auto>@@AEAPEAEPEAE_KPEBD@Z.code", i64 16, i1 false)
  %371 = getelementptr inbounds nuw i8, ptr %367, i64 5
  %372 = ptrtoint ptr %370 to i64
  %373 = ptrtoint ptr %371 to i64
  %374 = sub i64 %372, %373
  %375 = trunc i64 %374 to i32
  %376 = getelementptr inbounds nuw i8, ptr %5, i64 1
  store i32 %375, ptr %376, align 1
  %377 = add i64 %374, 2147483648
  %378 = icmp ult i64 %377, 4294967296
  br i1 %378, label %379, label %386

379:                                              ; preds = %369
  store ptr %5, ptr %6, align 8
  %380 = getelementptr inbounds nuw i8, ptr %6, i64 8
  store i64 5, ptr %380, align 8
  %381 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %367, ptr noundef nonnull %6)
  br i1 %381, label %382, label %386

382:                                              ; preds = %379
  %383 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10", align 8
  %384 = icmp eq ptr %383, null
  %385 = select i1 %384, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  br label %387

386:                                              ; preds = %379, %369
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0BL@HPHJODLD@the?5timers?8?5TFunction?5call?$AA@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10", align 8
  br label %387

387:                                              ; preds = %382, %386
  %388 = phi ptr [ %385, %382 ], [ @"??_C@_01JOAMLHOP@?9?$AA@", %386 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #30
  br label %389

389:                                              ; preds = %366, %387
  %390 = phi ptr [ @"??_C@_01JOAMLHOP@?9?$AA@", %366 ], [ %388, %387 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6)
  %391 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0", align 8
  %392 = icmp ne ptr %391, null
  %393 = zext i1 %392 to i8
  store i8 %393, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1
  %394 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  %395 = icmp eq ptr %394, null
  %396 = select i1 %395, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %397 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8", align 8
  %398 = icmp eq ptr %397, null
  %399 = select i1 %398, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %400 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7", align 8
  %401 = icmp eq ptr %400, null
  %402 = select i1 %401, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %403 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6", align 8
  %404 = icmp eq ptr %403, null
  %405 = select i1 %404, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %406 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5", align 8
  %407 = icmp eq ptr %406, null
  %408 = select i1 %407, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %409 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4", align 8
  %410 = icmp eq ptr %409, null
  %411 = select i1 %410, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %412 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3", align 8
  %413 = icmp eq ptr %412, null
  %414 = select i1 %413, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %415 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2", align 8
  %416 = icmp eq ptr %415, null
  %417 = select i1 %416, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %418 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1", align 8
  %419 = icmp eq ptr %418, null
  %420 = select i1 %419, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %421 = icmp eq ptr %391, null
  %422 = select i1 %421, ptr @"??_C@_01JOAMLHOP@?9?$AA@", ptr @"??_C@_05MMGNIMAB@timed?$AA@"
  %423 = select i1 %392, ptr @"??_C@_09DOMJCJCO@installed?$AA@", ptr @"??_C@_0DD@PJBCBDCM@NOT?5installed?5?$CIthe?5ExecuteTick?5c@"
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0JL@ODHELHNK@?$FLticksplit?$FN?5?$CFs?3?5tick?5functions?5?$CF@", ptr noundef nonnull %423, ptr noundef nonnull %422, ptr noundef nonnull %420, ptr noundef nonnull %417, ptr noundef nonnull %414, ptr noundef nonnull %411, ptr noundef nonnull %408, ptr noundef nonnull %405, ptr noundef nonnull %402, ptr noundef nonnull %399, ptr noundef nonnull %396, ptr noundef nonnull %390)
  %424 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %425 = trunc nuw i8 %424 to i1
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %13) #30
  br label %528

426:                                              ; preds = %327
  %427 = getelementptr inbounds nuw i8, ptr %118, i64 64
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %428 = getelementptr inbounds nuw i8, ptr %329, i64 5
  %429 = ptrtoint ptr %427 to i64
  %430 = ptrtoint ptr %428 to i64
  %431 = sub i64 %429, %430
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %432 = trunc i64 %431 to i32
  store i32 %432, ptr %3, align 4
  %433 = add i64 %431, 2147483648
  %434 = icmp ult i64 %433, 4294967296
  br i1 %434, label %436, label %435

435:                                              ; preds = %426
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %439

436:                                              ; preds = %426
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %437 = getelementptr inbounds nuw i8, ptr %329, i64 1
  %438 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %437, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %438, label %440, label %439

439:                                              ; preds = %435, %436
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0CO@MLPLNNMG@UWorld?3?3Tick?8s?5SetupPhysicsTickF@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2", align 8
  br label %440

440:                                              ; preds = %439, %436, %327
  %441 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3", align 8
  %442 = icmp eq ptr %441, null
  br i1 %442, label %457, label %443

443:                                              ; preds = %440
  %444 = getelementptr inbounds nuw i8, ptr %118, i64 80
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %445 = getelementptr inbounds nuw i8, ptr %441, i64 5
  %446 = ptrtoint ptr %444 to i64
  %447 = ptrtoint ptr %445 to i64
  %448 = sub i64 %446, %447
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %449 = trunc i64 %448 to i32
  store i32 %449, ptr %3, align 4
  %450 = add i64 %448, 2147483648
  %451 = icmp ult i64 %450, 4294967296
  br i1 %451, label %453, label %452

452:                                              ; preds = %443
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %456

453:                                              ; preds = %443
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %454 = getelementptr inbounds nuw i8, ptr %441, i64 1
  %455 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %454, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %455, label %457, label %456

456:                                              ; preds = %453, %452
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0CP@NHCICKLN@UWorld?3?3Tick?8s?5EnsureCollisionTr@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3", align 8
  br label %457

457:                                              ; preds = %456, %453, %440
  %458 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4", align 8
  %459 = icmp eq ptr %458, null
  br i1 %459, label %474, label %460

460:                                              ; preds = %457
  %461 = getelementptr inbounds nuw i8, ptr %118, i64 96
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %462 = getelementptr inbounds nuw i8, ptr %458, i64 5
  %463 = ptrtoint ptr %461 to i64
  %464 = ptrtoint ptr %462 to i64
  %465 = sub i64 %463, %464
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %466 = trunc i64 %465 to i32
  store i32 %466, ptr %3, align 4
  %467 = add i64 %465, 2147483648
  %468 = icmp ult i64 %467, 4294967296
  br i1 %468, label %470, label %469

469:                                              ; preds = %460
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %473

470:                                              ; preds = %460
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %471 = getelementptr inbounds nuw i8, ptr %458, i64 1
  %472 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %471, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %472, label %474, label %473

473:                                              ; preds = %470, %469
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0CJ@MAEPLMN@UWorld?3?3Tick?8s?5ProcessLatentActi@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4", align 8
  br label %474

474:                                              ; preds = %473, %470, %457
  %475 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5", align 8
  %476 = icmp eq ptr %475, null
  br i1 %476, label %491, label %477

477:                                              ; preds = %474
  %478 = getelementptr inbounds nuw i8, ptr %118, i64 112
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %479 = getelementptr inbounds nuw i8, ptr %475, i64 5
  %480 = ptrtoint ptr %478 to i64
  %481 = ptrtoint ptr %479 to i64
  %482 = sub i64 %480, %481
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %483 = trunc i64 %482 to i32
  store i32 %483, ptr %3, align 4
  %484 = add i64 %482, 2147483648
  %485 = icmp ult i64 %484, 4294967296
  br i1 %485, label %487, label %486

486:                                              ; preds = %477
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %490

487:                                              ; preds = %477
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %488 = getelementptr inbounds nuw i8, ptr %475, i64 1
  %489 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %488, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %489, label %491, label %490

490:                                              ; preds = %487, %486
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_05NAPFDJNG@timer?$AA@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5", align 8
  br label %491

491:                                              ; preds = %490, %487, %474
  %492 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6", align 8
  %493 = icmp eq ptr %492, null
  br i1 %493, label %508, label %494

494:                                              ; preds = %491
  %495 = getelementptr inbounds nuw i8, ptr %118, i64 128
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %496 = getelementptr inbounds nuw i8, ptr %492, i64 5
  %497 = ptrtoint ptr %495 to i64
  %498 = ptrtoint ptr %496 to i64
  %499 = sub i64 %497, %498
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %500 = trunc i64 %499 to i32
  store i32 %500, ptr %3, align 4
  %501 = add i64 %499, 2147483648
  %502 = icmp ult i64 %501, 4294967296
  br i1 %502, label %504, label %503

503:                                              ; preds = %494
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %507

504:                                              ; preds = %494
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %505 = getelementptr inbounds nuw i8, ptr %492, i64 1
  %506 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %505, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %506, label %508, label %507

507:                                              ; preds = %504, %503
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0M@PPDPACCC@tickobjects?$AA@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6", align 8
  br label %508

508:                                              ; preds = %507, %504, %491
  %509 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7", align 8
  %510 = icmp eq ptr %509, null
  br i1 %510, label %525, label %511

511:                                              ; preds = %508
  %512 = getelementptr inbounds nuw i8, ptr %118, i64 144
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %513 = getelementptr inbounds nuw i8, ptr %509, i64 5
  %514 = ptrtoint ptr %512 to i64
  %515 = ptrtoint ptr %513 to i64
  %516 = sub i64 %514, %515
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #30
  %517 = trunc i64 %516 to i32
  store i32 %517, ptr %3, align 4
  %518 = add i64 %516, 2147483648
  %519 = icmp ult i64 %518, 4294967296
  br i1 %519, label %521, label %520

520:                                              ; preds = %511
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br label %524

521:                                              ; preds = %511
  store ptr %3, ptr %4, align 8
  store i64 4, ptr %328, align 8
  %522 = getelementptr inbounds nuw i8, ptr %509, i64 1
  %523 = call noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef nonnull %522, ptr noundef nonnull %4)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #30
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  br i1 %523, label %525, label %524

524:                                              ; preds = %521, %520
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CC@PBOOBDPM@?$FLticksplit?$FN?5could?5not?5redirect?5?$CF@", ptr noundef nonnull @"??_C@_0DB@DPPPLJPI@UWorld?3?3Tick?8s?5InternalUpdateStr@")
  store ptr null, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7", align 8
  br label %525

525:                                              ; preds = %524, %521, %508
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %10)
  %526 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8", align 8
  %527 = icmp eq ptr %526, null
  br i1 %527, label %347, label %331

528:                                              ; preds = %120, %389, %2, %115, %108
  %529 = phi i1 [ false, %115 ], [ false, %108 ], [ true, %2 ], [ %425, %389 ], [ false, %120 ]
  ret i1 %529
}

declare dllimport i32 @QueryPerformanceFrequency(ptr noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #7

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@QEB_W@Z"(ptr noundef nonnull returned align 8 dereferenceable(32) %0, ptr noundef %1) unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %0, i8 0, i64 32, i1 false)
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %46

3:                                                ; preds = %2
  %4 = tail call noundef i64 @wcslen(ptr noundef %1) #31
  %5 = icmp ugt i64 %4, 9223372036854775806
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  invoke void @"?_Xlen_string@std@@YAXXZ"() #32
          to label %7 unwind label %46

7:                                                ; preds = %6
  unreachable

8:                                                ; preds = %3
  %9 = icmp samesign ult i64 %4, 8
  br i1 %9, label %10, label %15

10:                                               ; preds = %8
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %4, ptr %11, align 8
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 7, ptr %12, align 8
  %13 = shl nuw nsw i64 %4, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(32) %0, ptr align 2 %1, i64 %13, i1 false)
  %14 = getelementptr inbounds nuw [8 x i16], ptr %0, i64 0, i64 %4
  store i16 0, ptr %14, align 2
  br label %44

15:                                               ; preds = %8
  %16 = or i64 %4, 7
  %17 = icmp samesign ugt i64 %16, 9223372036854775806
  br i1 %17, label %24, label %18

18:                                               ; preds = %15
  %19 = tail call i64 @llvm.umax.i64(i64 %16, i64 10)
  %20 = shl nuw i64 %19, 1
  %21 = icmp samesign ugt i64 %16, 2046
  br i1 %21, label %22, label %35

22:                                               ; preds = %18
  %23 = icmp samesign ult i64 %16, 9223372036854775788
  br i1 %23, label %26, label %24

24:                                               ; preds = %22, %15
  invoke void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
          to label %25 unwind label %46

25:                                               ; preds = %24
  unreachable

26:                                               ; preds = %22
  %27 = add i64 %20, 41
  %28 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %27) #33
          to label %29 unwind label %46

29:                                               ; preds = %26
  %30 = ptrtoint ptr %28 to i64
  %31 = add i64 %30, 39
  %32 = and i64 %31, -32
  %33 = inttoptr i64 %32 to ptr
  %34 = getelementptr inbounds i8, ptr %33, i64 -8
  store i64 %30, ptr %34, align 8
  br label %38

35:                                               ; preds = %18
  %36 = add nuw nsw i64 %20, 2
  %37 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %36) #33
          to label %38 unwind label %46

38:                                               ; preds = %35, %29
  %39 = phi ptr [ %33, %29 ], [ %37, %35 ]
  store ptr %39, ptr %0, align 8
  %40 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %4, ptr %40, align 8
  %41 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 %19, ptr %41, align 8
  %42 = shl nuw i64 %4, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 2 %39, ptr align 2 %1, i64 %42, i1 false)
  %43 = getelementptr inbounds nuw i16, ptr %39, i64 %4
  store i16 0, ptr %43, align 2
  br label %44

44:                                               ; preds = %38, %10
  invoke void @llvm.seh.scope.end()
          to label %45 unwind label %46

45:                                               ; preds = %44
  ret ptr %0

46:                                               ; preds = %35, %26, %24, %6, %44, %2
  %47 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %47 unwind to caller
}

declare dso_local i32 @__CxxFrameHandler3(...)

; Function Attrs: nofree nosync nounwind memory(none)
declare dso_local void @llvm.seh.scope.begin() #8

; Function Attrs: nofree nosync nounwind memory(none)
declare dso_local void @llvm.seh.scope.end() #8

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #7

declare dso_local void @"?Log@opf@@YAXPEBDZZ"(ptr noundef, ...) local_unnamed_addr #6

declare dso_local noundef i64 @"?LedgerClockUs@opf@@YA_KXZ"() local_unnamed_addr #6

declare dso_local noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"() local_unnamed_addr #6

declare dso_local noundef ptr @"?AllocNearGame@opf@@YAPEAE_K@Z"(i64 noundef) local_unnamed_addr #6

; Function Attrs: mustprogress sspstrong uwtable
define internal fastcc noundef ptr @"?FindOne@?A0xB9C01504@opf@@YAPEAEAEBUGameModule@1@PEBD1@Z"(ptr noundef nonnull align 8 dereferenceable(64) %0, ptr noundef %1, ptr noundef %2) unnamed_addr #5 personality ptr @__CxxFrameHandler3 {
  %4 = alloca %"class.std::vector", align 8
  %5 = alloca %"struct.opf::Pattern", align 8
  %6 = alloca %"class.std::basic_string_view", align 8
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #30
  call void @llvm.lifetime.start.p0(i64 48, ptr nonnull %5) #30
  store ptr %1, ptr %6, align 8
  %7 = getelementptr inbounds nuw i8, ptr %6, i64 8
  %8 = tail call noundef i64 @strlen(ptr noundef nonnull dereferenceable(1) %1) #30
  store i64 %8, ptr %7, align 8
  call void @"?ParsePattern@opf@@YA?AUPattern@1@V?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z"(ptr dead_on_unwind nonnull writable sret(%"struct.opf::Pattern") align 8 %5, ptr noundef nonnull %6)
  invoke void @llvm.seh.scope.begin()
          to label %9 unwind label %23

9:                                                ; preds = %3
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 8
  invoke void @"?FindAll@opf@@YA?AV?$vector@PEAEV?$allocator@PEAE@std@@@std@@AEBUSection@1@AEBUPattern@1@@Z"(ptr dead_on_unwind nonnull writable sret(%"class.std::vector") align 8 %4, ptr noundef nonnull align 8 dereferenceable(16) %10, ptr noundef nonnull align 8 dereferenceable(48) %5)
          to label %11 unwind label %23

11:                                               ; preds = %9
  invoke void @llvm.seh.scope.end()
          to label %12 unwind label %23

12:                                               ; preds = %11
  call void @"??1Pattern@opf@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(48) %5) #30
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %5) #30
  invoke void @llvm.seh.scope.begin()
          to label %13 unwind label %54

13:                                               ; preds = %12
  %14 = getelementptr inbounds nuw i8, ptr %4, i64 8
  %15 = load ptr, ptr %14, align 8
  %16 = load ptr, ptr %4, align 8
  %17 = ptrtoint ptr %15 to i64
  %18 = ptrtoint ptr %16 to i64
  %19 = sub i64 %17, %18
  %20 = icmp eq i64 %19, 8
  br i1 %20, label %21, label %25

21:                                               ; preds = %13
  %22 = load ptr, ptr %16, align 8
  br label %28

23:                                               ; preds = %11, %9, %3
  %24 = cleanuppad within none []
  call void @"??1Pattern@opf@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(48) %5) #30 [ "funclet"(token %24) ]
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %5) #30
  cleanupret from %24 unwind to caller

25:                                               ; preds = %13
  %26 = icmp eq ptr %16, %15
  %27 = select i1 %26, ptr @"??_C@_09GNNAFPDF@not?5found?$AA@", ptr @"??_C@_09BCDCAHEC@ambiguous?$AA@"
  invoke void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0BN@NJLBEKLK@?$FLticksplit?$FN?5?$CFs?5?$CFs?3?5not?5timed?$AA@", ptr noundef %2, ptr noundef nonnull %27)
          to label %28 unwind label %54

28:                                               ; preds = %25, %21
  %29 = phi ptr [ %22, %21 ], [ null, %25 ]
  invoke void @llvm.seh.scope.end()
          to label %30 unwind label %54

30:                                               ; preds = %28
  %31 = load ptr, ptr %4, align 8
  %32 = icmp eq ptr %31, null
  br i1 %32, label %53, label %33

33:                                               ; preds = %30
  %34 = getelementptr inbounds nuw i8, ptr %4, i64 16
  %35 = load ptr, ptr %34, align 8
  %36 = ptrtoint ptr %35 to i64
  %37 = ptrtoint ptr %31 to i64
  %38 = sub i64 %36, %37
  %39 = icmp ugt i64 %38, 4095
  br i1 %39, label %40, label %50

40:                                               ; preds = %33
  %41 = getelementptr inbounds i8, ptr %31, i64 -8
  %42 = load i64, ptr %41, align 8
  %43 = add i64 %37, -8
  %44 = sub i64 %43, %42
  %45 = icmp ult i64 %44, 32
  br i1 %45, label %47, label %46

46:                                               ; preds = %40
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

47:                                               ; preds = %40
  %48 = add i64 %38, 39
  %49 = inttoptr i64 %42 to ptr
  br label %50

50:                                               ; preds = %47, %33
  %51 = phi i64 [ %48, %47 ], [ %38, %33 ]
  %52 = phi ptr [ %49, %47 ], [ %31, %33 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %52, i64 noundef %51) #30
  br label %53

53:                                               ; preds = %30, %50
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #30
  ret ptr %29

54:                                               ; preds = %28, %25, %12
  %55 = cleanuppad within none []
  call void @"??1?$vector@PEAEV?$allocator@PEAE@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %4) #30 [ "funclet"(token %55) ]
  cleanupret from %55 unwind to caller
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #9

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?ExecHook@?A0xB9C01504@opf@@YAXPEAXMHHPEBX@Z"(ptr noundef %0, float noundef %1, i32 noundef %2, i32 noundef %3, ptr noundef %4) #5 personality ptr @__C_specific_handler {
  %6 = alloca %union._LARGE_INTEGER, align 8
  %7 = alloca %union._LARGE_INTEGER, align 8
  %8 = alloca i32, align 4
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = alloca ptr, align 8
  %13 = alloca i32, align 4
  %14 = alloca ptr, align 8
  %15 = alloca %union._LARGE_INTEGER, align 8
  %16 = alloca %union._LARGE_INTEGER, align 8
  %17 = load ptr, ptr %0, align 8
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 8
  %19 = load ptr, ptr %18, align 8
  %20 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %21 = trunc i8 %20 to i1
  br i1 %21, label %23, label %22

22:                                               ; preds = %5
  tail call void %19(ptr noundef nonnull %0, float noundef %1, i32 noundef %2, i32 noundef %3, ptr noundef %4)
  br label %240

23:                                               ; preds = %5
  %24 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %24, label %94, label %25

25:                                               ; preds = %23
  %26 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %27 = icmp eq ptr %26, null
  br i1 %27, label %30, label %28

28:                                               ; preds = %25
  %29 = tail call noundef i64 %26()
  br label %33

30:                                               ; preds = %25
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %16) #30
  %31 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %16)
  %32 = load i64, ptr %16, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %16) #30
  br label %33

33:                                               ; preds = %28, %30
  %34 = phi i64 [ %29, %28 ], [ %32, %30 ]
  call void %19(ptr noundef nonnull %0, float noundef %1, i32 noundef %2, i32 noundef %3, ptr noundef %4)
  %35 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %36 = icmp eq ptr %35, null
  br i1 %36, label %39, label %37

37:                                               ; preds = %33
  %38 = call noundef i64 %35()
  br label %42

39:                                               ; preds = %33
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %15) #30
  %40 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %15)
  %41 = load i64, ptr %15, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %15) #30
  br label %42

42:                                               ; preds = %37, %39
  %43 = phi i64 [ %38, %37 ], [ %41, %39 ]
  %44 = sub i64 %43, %34
  %45 = ptrtoint ptr %19 to i64
  %46 = lshr i64 %45, 4
  br label %47

47:                                               ; preds = %85, %42
  %48 = phi i64 [ %46, %42 ], [ %87, %85 ]
  %49 = phi i32 [ 0, %42 ], [ %86, %85 ]
  %50 = and i64 %48, 63
  %51 = getelementptr inbounds nuw [64 x %"struct.opf::(anonymous namespace)::OffKind"], ptr @"?g_off@?A0xB9C01504@opf@@3PAUOffKind@?A0xB9C01504@1@A", i64 0, i64 %50
  %52 = load volatile i64, ptr %51, align 8
  fence syncscope("singlethread") seq_cst
  %53 = inttoptr i64 %52 to ptr
  %54 = icmp eq i64 %52, 0
  br i1 %54, label %55, label %61

55:                                               ; preds = %47
  %56 = cmpxchg volatile ptr %51, i64 0, i64 %45 seq_cst seq_cst, align 8
  %57 = extractvalue { i64, i1 } %56, 1
  %58 = extractvalue { i64, i1 } %56, 0
  %59 = inttoptr i64 %58 to ptr
  %60 = select i1 %57, ptr %19, ptr %59
  br label %61

61:                                               ; preds = %55, %47
  %62 = phi ptr [ %53, %47 ], [ %60, %55 ]
  %63 = icmp eq ptr %62, %19
  br i1 %63, label %64, label %69

64:                                               ; preds = %82, %61
  %65 = phi ptr [ %51, %61 ], [ %72, %82 ]
  %66 = getelementptr inbounds nuw i8, ptr %65, i64 8
  %67 = atomicrmw add ptr %66, i64 1 seq_cst, align 8
  %68 = getelementptr inbounds nuw i8, ptr %65, i64 16
  br label %91

69:                                               ; preds = %61
  %70 = add nsw i64 %48, 1
  %71 = and i64 %70, 63
  %72 = getelementptr inbounds nuw [64 x %"struct.opf::(anonymous namespace)::OffKind"], ptr @"?g_off@?A0xB9C01504@opf@@3PAUOffKind@?A0xB9C01504@1@A", i64 0, i64 %71
  %73 = load volatile i64, ptr %72, align 8
  fence syncscope("singlethread") seq_cst
  %74 = inttoptr i64 %73 to ptr
  %75 = icmp eq i64 %73, 0
  br i1 %75, label %76, label %82

76:                                               ; preds = %69
  %77 = cmpxchg volatile ptr %72, i64 0, i64 %45 seq_cst seq_cst, align 8
  %78 = extractvalue { i64, i1 } %77, 1
  %79 = extractvalue { i64, i1 } %77, 0
  %80 = inttoptr i64 %79 to ptr
  %81 = select i1 %78, ptr %19, ptr %80
  br label %82

82:                                               ; preds = %76, %69
  %83 = phi ptr [ %74, %69 ], [ %81, %76 ]
  %84 = icmp eq ptr %83, %19
  br i1 %84, label %64, label %85

85:                                               ; preds = %82
  %86 = add nuw nsw i32 %49, 2
  %87 = add nuw nsw i64 %71, 1
  %88 = icmp eq i32 %86, 64
  br i1 %88, label %89, label %47, !llvm.loop !25

89:                                               ; preds = %85
  %90 = atomicrmw add ptr @"?g_offOverflowCalls@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", i64 1 seq_cst, align 8
  br label %91

91:                                               ; preds = %64, %89
  %92 = phi ptr [ %68, %64 ], [ @"?g_offOverflowTicks@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", %89 ]
  %93 = atomicrmw add ptr %92, i64 %44 seq_cst, align 8
  br label %240

94:                                               ; preds = %23
  %95 = ptrtoint ptr %19 to i64
  %96 = lshr i64 %95, 4
  br label %97

97:                                               ; preds = %186, %94
  %98 = phi i64 [ %96, %94 ], [ %188, %186 ]
  %99 = phi i32 [ 0, %94 ], [ %187, %186 ]
  %100 = and i64 %98, 255
  %101 = getelementptr inbounds nuw [256 x %"struct.opf::(anonymous namespace)::KindState"], ptr @"?g_kinds@?A0xB9C01504@opf@@3PAUKindState@?A0xB9C01504@1@A", i64 0, i64 %100
  %102 = load ptr, ptr %101, align 16
  %103 = icmp eq ptr %102, %19
  %104 = icmp eq ptr %102, null
  %105 = or i1 %103, %104
  br i1 %105, label %106, label %178

106:                                              ; preds = %178, %97
  %107 = phi ptr [ %101, %97 ], [ %181, %178 ]
  %108 = phi i1 [ %104, %97 ], [ %184, %178 ]
  br i1 %108, label %109, label %110

109:                                              ; preds = %106
  store ptr %19, ptr %107, align 8
  br label %110

110:                                              ; preds = %109, %106
  %111 = getelementptr inbounds nuw i8, ptr %107, i64 8
  %112 = load i32, ptr %111, align 8
  %113 = icmp eq i32 %112, 0
  br i1 %113, label %114, label %168

114:                                              ; preds = %110
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %11)
  store ptr %0, ptr %9, align 8
  invoke void @llvm.seh.try.begin()
          to label %121 unwind label %115

115:                                              ; preds = %114
  %116 = catchswitch within none [label %117] unwind to caller

117:                                              ; preds = %115
  %118 = catchpad within %116 [ptr null]
  catchret from %118 to label %119

119:                                              ; preds = %117
  %120 = tail call i32 @llvm.eh.exceptioncode(token %118)
  br label %166

121:                                              ; preds = %114
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)
  %122 = load volatile ptr, ptr %9, align 8
  %123 = getelementptr inbounds nuw i8, ptr %122, i64 40
  %124 = load volatile ptr, ptr %123, align 8
  store volatile ptr %124, ptr %10, align 8
  %125 = load volatile ptr, ptr %10, align 8
  %126 = icmp eq ptr %125, null
  br i1 %126, label %127, label %128

127:                                              ; preds = %121
  store volatile i32 0, ptr %8, align 4
  store volatile i32 1, ptr %11, align 4
  br label %163

128:                                              ; preds = %121
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %12)
  %129 = load volatile ptr, ptr %10, align 8
  %130 = getelementptr inbounds nuw i8, ptr %129, i64 16
  %131 = load volatile ptr, ptr %130, align 8
  store volatile ptr %131, ptr %12, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %13)
  store volatile i32 0, ptr %13, align 4
  %132 = load volatile i32, ptr %13, align 4
  %133 = icmp slt i32 %132, 4
  br i1 %133, label %134, label %137

134:                                              ; preds = %128, %152
  %135 = load volatile ptr, ptr %12, align 8
  %136 = icmp eq ptr %135, null
  br i1 %136, label %137, label %138

137:                                              ; preds = %152, %134, %128
  store volatile i32 3, ptr %11, align 4
  br label %157

138:                                              ; preds = %134
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %14)
  %139 = load volatile ptr, ptr %12, align 8
  %140 = getelementptr inbounds nuw i8, ptr %139, i64 16
  %141 = load volatile ptr, ptr %140, align 8
  store volatile ptr %141, ptr %14, align 8
  %142 = load volatile ptr, ptr %14, align 8
  %143 = load volatile ptr, ptr %12, align 8
  %144 = icmp eq ptr %142, %143
  br i1 %144, label %145, label %146

145:                                              ; preds = %138
  store volatile i32 1, ptr %8, align 4
  br label %148

146:                                              ; preds = %138
  %147 = load volatile ptr, ptr %14, align 8
  store volatile ptr %147, ptr %12, align 8
  br label %148

148:                                              ; preds = %146, %145
  %149 = phi i32 [ 0, %146 ], [ 1, %145 ]
  store volatile i32 %149, ptr %11, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %14)
  %150 = load volatile i32, ptr %11, align 4
  %151 = icmp eq i32 %150, 0
  br i1 %151, label %152, label %157

152:                                              ; preds = %148
  %153 = load volatile i32, ptr %13, align 4
  %154 = add nsw i32 %153, 1
  store volatile i32 %154, ptr %13, align 4
  %155 = load volatile i32, ptr %13, align 4
  %156 = icmp slt i32 %155, 4
  br i1 %156, label %134, label %137, !llvm.loop !26

157:                                              ; preds = %148, %137
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %13)
  %158 = load volatile i32, ptr %11, align 4
  %159 = icmp eq i32 %158, 3
  br i1 %159, label %160, label %161

160:                                              ; preds = %157
  store volatile i32 2, ptr %8, align 4
  store volatile i32 1, ptr %11, align 4
  br label %161

161:                                              ; preds = %160, %157
  %162 = phi i32 [ 1, %157 ], [ 2, %160 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %12)
  br label %163

163:                                              ; preds = %161, %127
  %164 = phi i32 [ %162, %161 ], [ 0, %127 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)
  %165 = load volatile i32, ptr %11, align 4
  br label %166

166:                                              ; preds = %163, %119
  %167 = phi i32 [ %164, %163 ], [ 2, %119 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %11)
  store i32 %167, ptr %111, align 8
  br label %168

168:                                              ; preds = %166, %110
  %169 = phi i32 [ %167, %166 ], [ %112, %110 ]
  %170 = icmp eq i32 %169, 1
  br i1 %170, label %171, label %190

171:                                              ; preds = %168
  %172 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %173 = load ptr, ptr %172, align 8
  %174 = icmp eq ptr %173, null
  br i1 %174, label %190, label %175

175:                                              ; preds = %171
  %176 = getelementptr inbounds nuw i8, ptr %173, i64 16
  %177 = load ptr, ptr %176, align 8
  br label %190

178:                                              ; preds = %97
  %179 = add nsw i64 %98, 1
  %180 = and i64 %179, 255
  %181 = getelementptr inbounds nuw [256 x %"struct.opf::(anonymous namespace)::KindState"], ptr @"?g_kinds@?A0xB9C01504@opf@@3PAUKindState@?A0xB9C01504@1@A", i64 0, i64 %180
  %182 = load ptr, ptr %181, align 16
  %183 = icmp eq ptr %182, %19
  %184 = icmp eq ptr %182, null
  %185 = or i1 %183, %184
  br i1 %185, label %106, label %186

186:                                              ; preds = %178
  %187 = add nuw nsw i32 %99, 2
  %188 = add nuw nsw i64 %180, 1
  %189 = icmp eq i32 %187, 256
  br i1 %189, label %190, label %97, !llvm.loop !27

190:                                              ; preds = %186, %168, %171, %175
  %191 = phi ptr [ null, %171 ], [ %177, %175 ], [ null, %168 ], [ null, %186 ]
  %192 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %193 = load ptr, ptr %192, align 8
  %194 = icmp eq ptr %193, null
  br i1 %194, label %200, label %195

195:                                              ; preds = %190
  %196 = getelementptr inbounds nuw i8, ptr %193, i64 1
  %197 = load i8, ptr %196, align 1
  %198 = zext i8 %197 to i32
  %199 = shl nuw nsw i32 %198, 8
  br label %200

200:                                              ; preds = %195, %190
  %201 = phi i32 [ %199, %195 ], [ 65280, %190 ]
  %202 = load i32, ptr @"?g_curGroup@?A0xB9C01504@opf@@3IA", align 4
  %203 = or i32 %202, %201
  %204 = load i32, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %205 = icmp sgt i32 %204, 31
  br i1 %205, label %206, label %207

206:                                              ; preds = %200
  tail call void %19(ptr noundef nonnull %0, float noundef %1, i32 noundef %2, i32 noundef %3, ptr noundef %4)
  br label %240

207:                                              ; preds = %200
  %208 = add nsw i32 %204, 1
  store i32 %208, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %209 = sext i32 %204 to i64
  %210 = getelementptr inbounds [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %209
  store i64 0, ptr %210, align 8
  %211 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %212 = icmp eq ptr %211, null
  br i1 %212, label %215, label %213

213:                                              ; preds = %207
  %214 = tail call noundef i64 %211()
  br label %218

215:                                              ; preds = %207
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7) #30
  %216 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %7)
  %217 = load i64, ptr %7, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7) #30
  br label %218

218:                                              ; preds = %213, %215
  %219 = phi i64 [ %214, %213 ], [ %217, %215 ]
  call void %19(ptr noundef nonnull %0, float noundef %1, i32 noundef %2, i32 noundef %3, ptr noundef %4)
  %220 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %221 = icmp eq ptr %220, null
  br i1 %221, label %224, label %222

222:                                              ; preds = %218
  %223 = call noundef i64 %220()
  br label %227

224:                                              ; preds = %218
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #30
  %225 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %6)
  %226 = load i64, ptr %6, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #30
  br label %227

227:                                              ; preds = %222, %224
  %228 = phi i64 [ %223, %222 ], [ %226, %224 ]
  %229 = sub i64 %228, %219
  store i32 %204, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %230 = load i64, ptr %210, align 8
  %231 = icmp sgt i32 %204, 0
  br i1 %231, label %232, label %238

232:                                              ; preds = %227
  %233 = add nsw i32 %204, -1
  %234 = zext nneg i32 %233 to i64
  %235 = getelementptr inbounds nuw [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %234
  %236 = load i64, ptr %235, align 8
  %237 = add i64 %236, %229
  store i64 %237, ptr %235, align 8
  br label %238

238:                                              ; preds = %232, %227
  %239 = call i64 @llvm.usub.sat.i64(i64 %229, i64 %230)
  call fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %19, ptr noundef %191, i32 noundef %203, i64 noundef %239)
  br label %240

240:                                              ; preds = %206, %238, %91, %22
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TickableHook@?A0xB9C01504@opf@@YAXPEAXM@Z"(ptr noundef %0, float noundef %1) #5 {
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = load ptr, ptr %0, align 8
  %6 = load ptr, ptr %5, align 8
  %7 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %8 = trunc i8 %7 to i1
  br i1 %8, label %9, label %14

9:                                                ; preds = %2
  %10 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  %11 = load i32, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %12 = icmp slt i32 %11, 32
  %13 = select i1 %10, i1 %12, i1 false
  br i1 %13, label %15, label %14

14:                                               ; preds = %2, %9
  tail call void %6(ptr noundef nonnull %0, float noundef %1)
  br label %49

15:                                               ; preds = %9
  %16 = add nsw i32 %11, 1
  store i32 %16, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %17 = sext i32 %11 to i64
  %18 = getelementptr inbounds [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %17
  store i64 0, ptr %18, align 8
  %19 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %20 = icmp eq ptr %19, null
  br i1 %20, label %23, label %21

21:                                               ; preds = %15
  %22 = tail call noundef i64 %19()
  br label %26

23:                                               ; preds = %15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %24 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %25 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %26

26:                                               ; preds = %21, %23
  %27 = phi i64 [ %22, %21 ], [ %25, %23 ]
  call void %6(ptr noundef nonnull %0, float noundef %1)
  %28 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %29 = icmp eq ptr %28, null
  br i1 %29, label %32, label %30

30:                                               ; preds = %26
  %31 = call noundef i64 %28()
  br label %35

32:                                               ; preds = %26
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %33 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %34 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %35

35:                                               ; preds = %30, %32
  %36 = phi i64 [ %31, %30 ], [ %34, %32 ]
  %37 = sub i64 %36, %27
  store i32 %11, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %38 = load i64, ptr %18, align 8
  %39 = icmp sgt i32 %11, 0
  br i1 %39, label %40, label %46

40:                                               ; preds = %35
  %41 = add nsw i32 %11, -1
  %42 = zext nneg i32 %41 to i64
  %43 = getelementptr inbounds nuw [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %42
  %44 = load i64, ptr %43, align 8
  %45 = add i64 %44, %37
  store i64 %45, ptr %43, align 8
  br label %46

46:                                               ; preds = %40, %35
  %47 = call i64 @llvm.usub.sat.i64(i64 %37, i64 %38)
  %48 = load ptr, ptr %0, align 8
  call fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %6, ptr noundef %48, i32 noundef 65296, i64 noundef %47)
  br label %49

49:                                               ; preds = %46, %14
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TimerNativeHook@?A0xB9C01504@opf@@YAXPEAX00@Z"(ptr noundef %0, ptr readnone captures(none) %1, ptr noundef readonly captures(none) %2) #5 personality ptr @__C_specific_handler {
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = alloca %union._LARGE_INTEGER, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca ptr, align 8
  %11 = alloca i32, align 4
  %12 = load ptr, ptr %0, align 8
  %13 = load i32, ptr @"?g_nativeSlot@?A0xB9C01504@opf@@3IA", align 4
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds nuw i8, ptr %12, i64 %14
  %16 = load ptr, ptr %15, align 8
  %17 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %18 = trunc i8 %17 to i1
  br i1 %18, label %19, label %47

19:                                               ; preds = %3
  %20 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %20, label %21, label %47

21:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %11)
  store ptr %0, ptr %9, align 8
  invoke void @llvm.seh.try.begin()
          to label %22 unwind label %37

22:                                               ; preds = %21
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)
  %23 = load volatile ptr, ptr %9, align 8
  %24 = getelementptr inbounds nuw i8, ptr %23, i64 32
  %25 = load volatile ptr, ptr %24, align 8
  store volatile ptr %25, ptr %10, align 8
  %26 = invoke noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"() #34
          to label %27 unwind label %37

27:                                               ; preds = %22
  %28 = getelementptr inbounds nuw i8, ptr %26, i64 8
  %29 = load volatile ptr, ptr %10, align 8
  %30 = invoke noundef zeroext i1 @"?Contains@Section@opf@@QEBA_NPEBX@Z"(ptr noundef nonnull align 8 dereferenceable(16) %28, ptr noundef %29) #34
          to label %31 unwind label %37

31:                                               ; preds = %27
  br i1 %30, label %32, label %34

32:                                               ; preds = %31
  %33 = load volatile ptr, ptr %10, align 8
  br label %34

34:                                               ; preds = %32, %31
  %35 = phi ptr [ %33, %32 ], [ null, %31 ]
  store volatile ptr %35, ptr %8, align 8
  store volatile i32 1, ptr %11, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)
  %36 = load volatile i32, ptr %11, align 4
  br label %43

37:                                               ; preds = %27, %22, %21
  %38 = catchswitch within none [label %39] unwind to caller

39:                                               ; preds = %37
  %40 = catchpad within %38 [ptr null]
  catchret from %40 to label %41

41:                                               ; preds = %39
  %42 = tail call i32 @llvm.eh.exceptioncode(token %40)
  br label %43

43:                                               ; preds = %34, %41
  %44 = phi ptr [ %35, %34 ], [ null, %41 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %11)
  %45 = icmp eq ptr %44, null
  %46 = select i1 %45, ptr %12, ptr %44
  br label %47

47:                                               ; preds = %3, %43, %19
  %48 = phi ptr [ %46, %43 ], [ %12, %19 ], [ %12, %3 ]
  %49 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %50 = trunc i8 %49 to i1
  br i1 %50, label %51, label %78

51:                                               ; preds = %47
  %52 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %52, label %53, label %78

53:                                               ; preds = %51
  %54 = getelementptr inbounds nuw i8, ptr %2, i64 120
  %55 = load ptr, ptr %54, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store ptr %55, ptr %7, align 8
  %56 = icmp eq ptr %55, null
  br i1 %56, label %76, label %57

57:                                               ; preds = %53
  %58 = ptrtoint ptr %55 to i64
  %59 = and i64 %58, 7
  %60 = icmp eq i64 %59, 0
  %61 = icmp uge ptr %55, inttoptr (i64 65536 to ptr)
  %62 = and i1 %61, %60
  %63 = icmp ult ptr %55, inttoptr (i64 140737488355328 to ptr)
  %64 = and i1 %63, %62
  br i1 %64, label %65, label %76

65:                                               ; preds = %57
  invoke void @llvm.seh.try.begin()
          to label %72 unwind label %66

66:                                               ; preds = %65
  %67 = catchswitch within none [label %68] unwind to caller

68:                                               ; preds = %66
  %69 = catchpad within %67 [ptr null]
  catchret from %69 to label %70

70:                                               ; preds = %68
  %71 = tail call i32 @llvm.eh.exceptioncode(token %69)
  br label %76

72:                                               ; preds = %65
  %73 = load volatile ptr, ptr %7, align 8
  %74 = getelementptr inbounds nuw i8, ptr %73, i64 16
  %75 = load volatile ptr, ptr %74, align 8
  store volatile ptr %75, ptr %6, align 8
  br label %76

76:                                               ; preds = %72, %70, %57, %53
  %77 = phi ptr [ null, %70 ], [ %75, %72 ], [ null, %57 ], [ null, %53 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  br label %78

78:                                               ; preds = %47, %51, %76
  %79 = phi ptr [ %77, %76 ], [ null, %51 ], [ null, %47 ]
  %80 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %81 = trunc i8 %80 to i1
  br i1 %81, label %82, label %87

82:                                               ; preds = %78
  %83 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  %84 = load i32, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %85 = icmp slt i32 %84, 32
  %86 = select i1 %83, i1 %85, i1 false
  br i1 %86, label %88, label %87

87:                                               ; preds = %82, %78
  tail call void %16(ptr noundef nonnull %0)
  br label %121

88:                                               ; preds = %82
  %89 = add nsw i32 %84, 1
  store i32 %89, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %90 = sext i32 %84 to i64
  %91 = getelementptr inbounds [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %90
  store i64 0, ptr %91, align 8
  %92 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %93 = icmp eq ptr %92, null
  br i1 %93, label %96, label %94

94:                                               ; preds = %88
  %95 = tail call noundef i64 %92()
  br label %99

96:                                               ; preds = %88
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #30
  %97 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %5)
  %98 = load i64, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #30
  br label %99

99:                                               ; preds = %96, %94
  %100 = phi i64 [ %95, %94 ], [ %98, %96 ]
  call void %16(ptr noundef nonnull %0)
  %101 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %102 = icmp eq ptr %101, null
  br i1 %102, label %105, label %103

103:                                              ; preds = %99
  %104 = call noundef i64 %101()
  br label %108

105:                                              ; preds = %99
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %106 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %107 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %108

108:                                              ; preds = %105, %103
  %109 = phi i64 [ %104, %103 ], [ %107, %105 ]
  %110 = sub i64 %109, %100
  store i32 %84, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %111 = load i64, ptr %91, align 8
  %112 = icmp sgt i32 %84, 0
  br i1 %112, label %113, label %119

113:                                              ; preds = %108
  %114 = add nsw i32 %84, -1
  %115 = zext nneg i32 %114 to i64
  %116 = getelementptr inbounds nuw [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %115
  %117 = load i64, ptr %116, align 8
  %118 = add i64 %117, %110
  store i64 %118, ptr %116, align 8
  br label %119

119:                                              ; preds = %113, %108
  %120 = call i64 @llvm.usub.sat.i64(i64 %110, i64 %111)
  call fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %48, ptr noundef %79, i32 noundef 65297, i64 noundef %120)
  br label %121

121:                                              ; preds = %87, %119
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TimerDynamicHook@?A0xB9C01504@opf@@YAXPEAX00@Z"(ptr noundef %0, ptr noundef %1, ptr noundef %2) #5 personality ptr @__C_specific_handler {
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = alloca %union._LARGE_INTEGER, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = load ptr, ptr %0, align 8
  %9 = load i32, ptr @"?g_peSlot@?A0xB9C01504@opf@@3IA", align 4
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds nuw i8, ptr %8, i64 %10
  %12 = load ptr, ptr %11, align 8
  %13 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %14 = trunc i8 %13 to i1
  br i1 %14, label %15, label %38

15:                                               ; preds = %3
  %16 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %16, label %17, label %38

17:                                               ; preds = %15
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store ptr %0, ptr %7, align 8
  %18 = ptrtoint ptr %0 to i64
  %19 = and i64 %18, 7
  %20 = icmp eq i64 %19, 0
  %21 = icmp uge ptr %0, inttoptr (i64 65536 to ptr)
  %22 = and i1 %21, %20
  %23 = icmp ult ptr %0, inttoptr (i64 140737488355328 to ptr)
  %24 = and i1 %23, %22
  br i1 %24, label %25, label %36

25:                                               ; preds = %17
  invoke void @llvm.seh.try.begin()
          to label %32 unwind label %26

26:                                               ; preds = %25
  %27 = catchswitch within none [label %28] unwind to caller

28:                                               ; preds = %26
  %29 = catchpad within %27 [ptr null]
  catchret from %29 to label %30

30:                                               ; preds = %28
  %31 = tail call i32 @llvm.eh.exceptioncode(token %29)
  br label %36

32:                                               ; preds = %25
  %33 = load volatile ptr, ptr %7, align 8
  %34 = getelementptr inbounds nuw i8, ptr %33, i64 16
  %35 = load volatile ptr, ptr %34, align 8
  store volatile ptr %35, ptr %6, align 8
  br label %36

36:                                               ; preds = %17, %30, %32
  %37 = phi ptr [ null, %30 ], [ %35, %32 ], [ null, %17 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  br label %38

38:                                               ; preds = %3, %15, %36
  %39 = phi ptr [ %37, %36 ], [ null, %15 ], [ null, %3 ]
  %40 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %41 = trunc i8 %40 to i1
  br i1 %41, label %42, label %47

42:                                               ; preds = %38
  %43 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  %44 = load i32, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %45 = icmp slt i32 %44, 32
  %46 = select i1 %43, i1 %45, i1 false
  br i1 %46, label %48, label %47

47:                                               ; preds = %42, %38
  tail call void %12(ptr noundef nonnull %0, ptr noundef %1, ptr noundef %2)
  br label %81

48:                                               ; preds = %42
  %49 = add nsw i32 %44, 1
  store i32 %49, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %50 = sext i32 %44 to i64
  %51 = getelementptr inbounds [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %50
  store i64 0, ptr %51, align 8
  %52 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %53 = icmp eq ptr %52, null
  br i1 %53, label %56, label %54

54:                                               ; preds = %48
  %55 = tail call noundef i64 %52()
  br label %59

56:                                               ; preds = %48
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #30
  %57 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %5)
  %58 = load i64, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #30
  br label %59

59:                                               ; preds = %56, %54
  %60 = phi i64 [ %55, %54 ], [ %58, %56 ]
  call void %12(ptr noundef nonnull %0, ptr noundef %1, ptr noundef %2)
  %61 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %62 = icmp eq ptr %61, null
  br i1 %62, label %65, label %63

63:                                               ; preds = %59
  %64 = call noundef i64 %61()
  br label %68

65:                                               ; preds = %59
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %66 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %67 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %68

68:                                               ; preds = %65, %63
  %69 = phi i64 [ %64, %63 ], [ %67, %65 ]
  %70 = sub i64 %69, %60
  store i32 %44, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %71 = load i64, ptr %51, align 8
  %72 = icmp sgt i32 %44, 0
  br i1 %72, label %73, label %79

73:                                               ; preds = %68
  %74 = add nsw i32 %44, -1
  %75 = zext nneg i32 %74 to i64
  %76 = getelementptr inbounds nuw [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %75
  %77 = load i64, ptr %76, align 8
  %78 = add i64 %77, %70
  store i64 %78, ptr %76, align 8
  br label %79

79:                                               ; preds = %73, %68
  %80 = call i64 @llvm.usub.sat.i64(i64 %70, i64 %71)
  call fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %1, ptr noundef %39, i32 noundef 65298, i64 noundef %80)
  br label %81

81:                                               ; preds = %47, %79
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TimerCallbackHook@?A0xB9C01504@opf@@YAXPEAX00@Z"(ptr noundef %0, ptr noundef %1, ptr noundef readonly captures(none) %2) #5 personality ptr @__C_specific_handler {
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = alloca %union._LARGE_INTEGER, align 8
  %6 = alloca ptr, align 8
  %7 = alloca ptr, align 8
  %8 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %9 = trunc i8 %8 to i1
  br i1 %9, label %10, label %37

10:                                               ; preds = %3
  %11 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %11, label %12, label %37

12:                                               ; preds = %10
  %13 = getelementptr inbounds nuw i8, ptr %2, i64 120
  %14 = load ptr, ptr %13, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)
  store ptr %14, ptr %7, align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %35, label %16

16:                                               ; preds = %12
  %17 = ptrtoint ptr %14 to i64
  %18 = and i64 %17, 7
  %19 = icmp eq i64 %18, 0
  %20 = icmp uge ptr %14, inttoptr (i64 65536 to ptr)
  %21 = and i1 %20, %19
  %22 = icmp ult ptr %14, inttoptr (i64 140737488355328 to ptr)
  %23 = and i1 %22, %21
  br i1 %23, label %24, label %35

24:                                               ; preds = %16
  invoke void @llvm.seh.try.begin()
          to label %31 unwind label %25

25:                                               ; preds = %24
  %26 = catchswitch within none [label %27] unwind to caller

27:                                               ; preds = %25
  %28 = catchpad within %26 [ptr null]
  catchret from %28 to label %29

29:                                               ; preds = %27
  %30 = tail call i32 @llvm.eh.exceptioncode(token %28)
  br label %35

31:                                               ; preds = %24
  %32 = load volatile ptr, ptr %7, align 8
  %33 = getelementptr inbounds nuw i8, ptr %32, i64 16
  %34 = load volatile ptr, ptr %33, align 8
  store volatile ptr %34, ptr %6, align 8
  br label %35

35:                                               ; preds = %31, %29, %16, %12
  %36 = phi ptr [ null, %29 ], [ %34, %31 ], [ null, %16 ], [ null, %12 ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)
  br label %37

37:                                               ; preds = %3, %10, %35
  %38 = phi ptr [ %36, %35 ], [ null, %10 ], [ null, %3 ]
  %39 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %40 = trunc i8 %39 to i1
  br i1 %40, label %41, label %46

41:                                               ; preds = %37
  %42 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  %43 = load i32, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %44 = icmp slt i32 %43, 32
  %45 = select i1 %42, i1 %44, i1 false
  br i1 %45, label %47, label %46

46:                                               ; preds = %41, %37
  tail call void %1(ptr noundef %0)
  br label %80

47:                                               ; preds = %41
  %48 = add nsw i32 %43, 1
  store i32 %48, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %49 = sext i32 %43 to i64
  %50 = getelementptr inbounds [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %49
  store i64 0, ptr %50, align 8
  %51 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %52 = icmp eq ptr %51, null
  br i1 %52, label %55, label %53

53:                                               ; preds = %47
  %54 = tail call noundef i64 %51()
  br label %58

55:                                               ; preds = %47
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #30
  %56 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %5)
  %57 = load i64, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #30
  br label %58

58:                                               ; preds = %55, %53
  %59 = phi i64 [ %54, %53 ], [ %57, %55 ]
  call void %1(ptr noundef %0)
  %60 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %61 = icmp eq ptr %60, null
  br i1 %61, label %64, label %62

62:                                               ; preds = %58
  %63 = call noundef i64 %60()
  br label %67

64:                                               ; preds = %58
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %65 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %66 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %67

67:                                               ; preds = %64, %62
  %68 = phi i64 [ %63, %62 ], [ %66, %64 ]
  %69 = sub i64 %68, %59
  store i32 %43, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  %70 = load i64, ptr %50, align 8
  %71 = icmp sgt i32 %43, 0
  br i1 %71, label %72, label %78

72:                                               ; preds = %67
  %73 = add nsw i32 %43, -1
  %74 = zext nneg i32 %73 to i64
  %75 = getelementptr inbounds nuw [32 x i64], ptr @"?g_child@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %74
  %76 = load i64, ptr %75, align 8
  %77 = add i64 %76, %69
  store i64 %77, ptr %75, align 8
  br label %78

78:                                               ; preds = %72, %67
  %79 = call i64 @llvm.usub.sat.i64(i64 %69, i64 %70)
  call fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %1, ptr noundef %38, i32 noundef 65299, i64 noundef %79)
  br label %80

80:                                               ; preds = %46, %78
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?SetupHook@?A0xB9C01504@opf@@YAXPEAXM@Z"(ptr noundef %0, float noundef %1) #5 {
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %6 = trunc i8 %5 to i1
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  %8 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %8, label %11, label %9

9:                                                ; preds = %2, %7
  %10 = load ptr, ptr @"?g_setupOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  tail call void %10(ptr noundef %0, float noundef %1)
  br label %41

11:                                               ; preds = %7
  %12 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %13 = icmp eq ptr %12, null
  br i1 %13, label %16, label %14

14:                                               ; preds = %11
  %15 = tail call noundef i64 %12()
  br label %19

16:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %17 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %18 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %19

19:                                               ; preds = %14, %16
  %20 = phi i64 [ %15, %14 ], [ %18, %16 ]
  %21 = load i64, ptr @"?g_preTs@?A0xB9C01504@opf@@3_KA", align 8
  %22 = icmp eq i64 %21, 0
  br i1 %22, label %27, label %23

23:                                               ; preds = %19
  %24 = sub i64 %20, %21
  %25 = load i64, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", align 16
  %26 = add i64 %24, %25
  store i64 %26, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", align 16
  store i64 0, ptr @"?g_preTs@?A0xB9C01504@opf@@3_KA", align 8
  br label %27

27:                                               ; preds = %23, %19
  %28 = load ptr, ptr @"?g_setupOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  call void %28(ptr noundef %0, float noundef %1)
  %29 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %30 = icmp eq ptr %29, null
  br i1 %30, label %33, label %31

31:                                               ; preds = %27
  %32 = call noundef i64 %29()
  br label %36

33:                                               ; preds = %27
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %34 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %35 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %36

36:                                               ; preds = %31, %33
  %37 = phi i64 [ %32, %31 ], [ %35, %33 ]
  %38 = sub i64 %37, %20
  %39 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 8), align 8
  %40 = add i64 %38, %39
  store i64 %40, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 8), align 8
  store i64 %37, ptr @"?g_setupEnd@?A0xB9C01504@opf@@3_KA", align 8
  br label %41

41:                                               ; preds = %36, %9
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?CollHook@?A0xB9C01504@opf@@YAXPEAX@Z"(ptr noundef %0) #5 {
  %2 = alloca %union._LARGE_INTEGER, align 8
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %5 = trunc i8 %4 to i1
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %7, label %10, label %8

8:                                                ; preds = %1, %6
  %9 = load ptr, ptr @"?g_collOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  tail call void %9(ptr noundef %0)
  br label %33

10:                                               ; preds = %6
  %11 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %12 = icmp eq ptr %11, null
  br i1 %12, label %15, label %13

13:                                               ; preds = %10
  %14 = tail call noundef i64 %11()
  br label %18

15:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %16 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %17 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %18

18:                                               ; preds = %13, %15
  %19 = phi i64 [ %14, %13 ], [ %17, %15 ]
  %20 = load ptr, ptr @"?g_collOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  call void %20(ptr noundef %0)
  %21 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %22 = icmp eq ptr %21, null
  br i1 %22, label %25, label %23

23:                                               ; preds = %18
  %24 = call noundef i64 %21()
  br label %28

25:                                               ; preds = %18
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #30
  %26 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %2)
  %27 = load i64, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #30
  br label %28

28:                                               ; preds = %23, %25
  %29 = phi i64 [ %24, %23 ], [ %27, %25 ]
  %30 = sub i64 %29, %19
  %31 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 24), align 8
  %32 = add i64 %30, %31
  store i64 %32, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 24), align 8
  br label %33

33:                                               ; preds = %28, %8
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?LatentHook@?A0xB9C01504@opf@@YAXPEAX0M@Z"(ptr noundef %0, ptr noundef %1, float noundef %2) #5 {
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = alloca %union._LARGE_INTEGER, align 8
  %6 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %7 = trunc i8 %6 to i1
  br i1 %7, label %8, label %10

8:                                                ; preds = %3
  %9 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %9, label %12, label %10

10:                                               ; preds = %3, %8
  %11 = load ptr, ptr @"?g_latentOrig@?A0xB9C01504@opf@@3P6AXPEAX0M@ZEA", align 8
  tail call void %11(ptr noundef %0, ptr noundef %1, float noundef %2)
  br label %35

12:                                               ; preds = %8
  %13 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %14 = icmp eq ptr %13, null
  br i1 %14, label %17, label %15

15:                                               ; preds = %12
  %16 = tail call noundef i64 %13()
  br label %20

17:                                               ; preds = %12
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #30
  %18 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %5)
  %19 = load i64, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #30
  br label %20

20:                                               ; preds = %15, %17
  %21 = phi i64 [ %16, %15 ], [ %19, %17 ]
  %22 = load ptr, ptr @"?g_latentOrig@?A0xB9C01504@opf@@3P6AXPEAX0M@ZEA", align 8
  call void %22(ptr noundef %0, ptr noundef %1, float noundef %2)
  %23 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %24 = icmp eq ptr %23, null
  br i1 %24, label %27, label %25

25:                                               ; preds = %20
  %26 = call noundef i64 %23()
  br label %30

27:                                               ; preds = %20
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %28 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %29 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %30

30:                                               ; preds = %25, %27
  %31 = phi i64 [ %26, %25 ], [ %29, %27 ]
  %32 = sub i64 %31, %21
  %33 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 32), align 16
  %34 = add i64 %32, %33
  store i64 %34, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 32), align 16
  br label %35

35:                                               ; preds = %30, %10
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TimerHook@?A0xB9C01504@opf@@YAXPEAXM@Z"(ptr noundef %0, float noundef %1) #5 {
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = alloca %union._LARGE_INTEGER, align 8
  %5 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %6 = trunc i8 %5 to i1
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  %8 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %8, label %11, label %9

9:                                                ; preds = %2, %7
  %10 = load ptr, ptr @"?g_timerOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  tail call void %10(ptr noundef %0, float noundef %1)
  br label %34

11:                                               ; preds = %7
  %12 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %13 = icmp eq ptr %12, null
  br i1 %13, label %16, label %14

14:                                               ; preds = %11
  %15 = tail call noundef i64 %12()
  br label %19

16:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  %17 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %4)
  %18 = load i64, ptr %4, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  br label %19

19:                                               ; preds = %14, %16
  %20 = phi i64 [ %15, %14 ], [ %18, %16 ]
  %21 = load ptr, ptr @"?g_timerOrig@?A0xB9C01504@opf@@3P6AXPEAXM@ZEA", align 8
  call void %21(ptr noundef %0, float noundef %1)
  %22 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %23 = icmp eq ptr %22, null
  br i1 %23, label %26, label %24

24:                                               ; preds = %19
  %25 = call noundef i64 %22()
  br label %29

26:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %27 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %28 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %29

29:                                               ; preds = %24, %26
  %30 = phi i64 [ %25, %24 ], [ %28, %26 ]
  %31 = sub i64 %30, %20
  %32 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 40), align 8
  %33 = add i64 %31, %32
  store i64 %33, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 40), align 8
  br label %34

34:                                               ; preds = %29, %9
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?TickObjectsHook@?A0xB9C01504@opf@@YAXPEAXH_NM@Z"(ptr noundef %0, i32 noundef %1, i1 noundef zeroext %2, float noundef %3) #5 {
  %5 = alloca %union._LARGE_INTEGER, align 8
  %6 = alloca %union._LARGE_INTEGER, align 8
  %7 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %8 = trunc i8 %7 to i1
  br i1 %8, label %9, label %11

9:                                                ; preds = %4
  %10 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %10, label %13, label %11

11:                                               ; preds = %4, %9
  %12 = load ptr, ptr @"?g_tickObjOrig@?A0xB9C01504@opf@@3P6AXPEAXH_NM@ZEA", align 8
  tail call void %12(ptr noundef %0, i32 noundef %1, i1 noundef zeroext %2, float noundef %3)
  br label %36

13:                                               ; preds = %9
  %14 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %18, label %16

16:                                               ; preds = %13
  %17 = tail call noundef i64 %14()
  br label %21

18:                                               ; preds = %13
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #30
  %19 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %6)
  %20 = load i64, ptr %6, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #30
  br label %21

21:                                               ; preds = %16, %18
  %22 = phi i64 [ %17, %16 ], [ %20, %18 ]
  %23 = load ptr, ptr @"?g_tickObjOrig@?A0xB9C01504@opf@@3P6AXPEAXH_NM@ZEA", align 8
  call void %23(ptr noundef %0, i32 noundef %1, i1 noundef zeroext %2, float noundef %3)
  %24 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %25 = icmp eq ptr %24, null
  br i1 %25, label %28, label %26

26:                                               ; preds = %21
  %27 = call noundef i64 %24()
  br label %31

28:                                               ; preds = %21
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #30
  %29 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %5)
  %30 = load i64, ptr %5, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #30
  br label %31

31:                                               ; preds = %26, %28
  %32 = phi i64 [ %27, %26 ], [ %30, %28 ]
  %33 = sub i64 %32, %22
  %34 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 48), align 16
  %35 = add i64 %33, %34
  store i64 %35, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 48), align 16
  store i64 %32, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  br label %36

36:                                               ; preds = %31, %11
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define internal void @"?StreamHook@?A0xB9C01504@opf@@YAXPEAX@Z"(ptr noundef %0) #5 {
  %2 = alloca %union._LARGE_INTEGER, align 8
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %5 = trunc i8 %4 to i1
  br i1 %5, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"()
  br i1 %7, label %10, label %8

8:                                                ; preds = %1, %6
  %9 = load ptr, ptr @"?g_streamOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  tail call void %9(ptr noundef %0)
  br label %40

10:                                               ; preds = %6
  %11 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %12 = icmp eq ptr %11, null
  br i1 %12, label %15, label %13

13:                                               ; preds = %10
  %14 = tail call noundef i64 %11()
  br label %18

15:                                               ; preds = %10
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %16 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %17 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %18

18:                                               ; preds = %13, %15
  %19 = phi i64 [ %14, %13 ], [ %17, %15 ]
  %20 = load i64, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  %21 = icmp eq i64 %20, 0
  br i1 %21, label %26, label %22

22:                                               ; preds = %18
  %23 = sub i64 %19, %20
  %24 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 56), align 8
  %25 = add i64 %23, %24
  store i64 %25, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 56), align 8
  store i64 0, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  br label %26

26:                                               ; preds = %22, %18
  %27 = load ptr, ptr @"?g_streamOrig@?A0xB9C01504@opf@@3P6AXPEAX@ZEA", align 8
  call void %27(ptr noundef %0)
  %28 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %29 = icmp eq ptr %28, null
  br i1 %29, label %32, label %30

30:                                               ; preds = %26
  %31 = call noundef i64 %28()
  br label %35

32:                                               ; preds = %26
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #30
  %33 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %2)
  %34 = load i64, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #30
  br label %35

35:                                               ; preds = %30, %32
  %36 = phi i64 [ %31, %30 ], [ %34, %32 ]
  %37 = sub i64 %36, %19
  %38 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 64), align 16
  %39 = add i64 %37, %38
  store i64 %39, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 64), align 16
  br label %40

40:                                               ; preds = %35, %8
  ret void
}

declare dllimport i32 @VirtualProtect(ptr noundef, i64 noundef, i32 noundef, ptr noundef) local_unnamed_addr #6

declare dllimport i32 @FlushInstructionCache(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #6

declare dllimport ptr @GetCurrentProcess() local_unnamed_addr #6

declare dso_local noundef zeroext i1 @"?WriteCode@opf@@YA_NPEAXV?$span@$$CBE$0?0@std@@@Z"(ptr noundef, ptr noundef) local_unnamed_addr #6

; Function Attrs: mustprogress sspstrong uwtable
define dso_local void @"?SetTickSplit@opf@@YAX_N@Z"(i1 noundef zeroext %0) local_unnamed_addr #5 {
  %2 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %3 = trunc nuw i8 %2 to i1
  br i1 %3, label %9, label %4

4:                                                ; preds = %1
  %5 = xor i1 %0, true
  %6 = load i1, ptr @"?logged@?1??SetTickSplit@opf@@YAX_N@Z@4_NA", align 1
  %7 = select i1 %5, i1 true, i1 %6
  br i1 %7, label %16, label %8

8:                                                ; preds = %4
  store i1 true, ptr @"?logged@?1??SetTickSplit@opf@@YAX_N@Z@4_NA", align 1
  tail call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0HC@MLKAEPAE@?$FLticksplit?$FN?5HitchLedgerTickSplit@")
  br label %16

9:                                                ; preds = %1
  %10 = zext i1 %0 to i8
  %11 = atomicrmw xchg ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", i8 %10 seq_cst, align 1
  %12 = trunc i8 %11 to i1
  %13 = xor i1 %0, %12
  br i1 %13, label %14, label %16

14:                                               ; preds = %9
  %15 = select i1 %0, ptr @"??_C@_0BE@EHLDMMMC@splitting?5tick?5time?$AA@", ptr @"??_C@_07IEOHBIGJ@stopped?$AA@"
  tail call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0P@JAPMPJJJ@?$FLticksplit?$FN?5?$CFs?$AA@", ptr noundef nonnull %15)
  br label %16

16:                                               ; preds = %4, %8, %14, %9
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define dso_local void @"?TickSplitGroup@opf@@YAXH_N@Z"(i32 noundef %0, i1 noundef zeroext %1) local_unnamed_addr #5 {
  %3 = alloca %union._LARGE_INTEGER, align 8
  %4 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %5 = trunc nuw i8 %4 to i1
  br i1 %5, label %6, label %40

6:                                                ; preds = %2
  %7 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %8 = trunc i8 %7 to i1
  br i1 %8, label %9, label %40

9:                                                ; preds = %6
  br i1 %1, label %11, label %10

10:                                               ; preds = %9
  store i32 15, ptr @"?g_curGroup@?A0xB9C01504@opf@@3IA", align 4
  br label %40

11:                                               ; preds = %9
  %12 = icmp ult i32 %0, 8
  %13 = select i1 %12, i32 %0, i32 15
  store i32 %13, ptr @"?g_curGroup@?A0xB9C01504@opf@@3IA", align 4
  %14 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %15 = icmp eq ptr %14, null
  br i1 %15, label %18, label %16

16:                                               ; preds = %11
  %17 = tail call noundef i64 %14()
  br label %21

18:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  %19 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %3)
  %20 = load i64, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  br label %21

21:                                               ; preds = %16, %18
  %22 = phi i64 [ %17, %16 ], [ %20, %18 ]
  %23 = icmp eq i32 %0, 0
  %24 = load i64, ptr @"?g_setupEnd@?A0xB9C01504@opf@@3_KA", align 8
  %25 = icmp ne i64 %24, 0
  %26 = select i1 %23, i1 %25, i1 false
  br i1 %26, label %27, label %31

27:                                               ; preds = %21
  %28 = sub i64 %22, %24
  %29 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 16), align 16
  %30 = add i64 %28, %29
  store i64 %30, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 16), align 16
  store i64 0, ptr @"?g_setupEnd@?A0xB9C01504@opf@@3_KA", align 8
  br label %40

31:                                               ; preds = %21
  %32 = icmp eq i32 %0, 5
  %33 = load i64, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  %34 = icmp ne i64 %33, 0
  %35 = select i1 %32, i1 %34, i1 false
  br i1 %35, label %36, label %40

36:                                               ; preds = %31
  %37 = sub i64 %22, %33
  %38 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 56), align 8
  %39 = add i64 %37, %38
  store i64 %39, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 56), align 8
  store i64 0, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  br label %40

40:                                               ; preds = %27, %31, %36, %2, %6, %10
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define dso_local void @"?TickSplitPreActor@opf@@YAXXZ"() local_unnamed_addr #5 {
  %1 = alloca %union._LARGE_INTEGER, align 8
  %2 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %3 = trunc nuw i8 %2 to i1
  br i1 %3, label %4, label %17

4:                                                ; preds = %0
  %5 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %6 = trunc i8 %5 to i1
  br i1 %6, label %7, label %17

7:                                                ; preds = %4
  %8 = load ptr, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %9 = icmp eq ptr %8, null
  br i1 %9, label %12, label %10

10:                                               ; preds = %7
  %11 = tail call noundef i64 %8()
  br label %15

12:                                               ; preds = %7
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %1) #30
  %13 = call i32 @QueryPerformanceCounter(ptr noundef nonnull %1)
  %14 = load i64, ptr %1, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %1) #30
  br label %15

15:                                               ; preds = %10, %12
  %16 = phi i64 [ %11, %10 ], [ %14, %12 ]
  store i64 %16, ptr @"?g_preTs@?A0xB9C01504@opf@@3_KA", align 8
  br label %17

17:                                               ; preds = %15, %4, %0
  ret void
}

; Function Attrs: mustprogress nofree norecurse nounwind sspstrong uwtable
define dso_local void @"?TickSplitFrameEnd@opf@@YAXAEBUTickSplitFrame@1@@Z"(ptr noundef nonnull readonly align 8 captures(none) dereferenceable(72) %0) local_unnamed_addr #10 {
  %2 = alloca %"struct.opf::(anonymous namespace)::TRec", align 16
  %3 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %4 = trunc nuw i8 %3 to i1
  br i1 %4, label %5, label %417

5:                                                ; preds = %1
  %6 = load i32, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds nuw [2 x %"struct.opf::(anonymous namespace)::Window"], ptr @"?g_win@?A0xB9C01504@opf@@3PAUWindow@?A0xB9C01504@1@A", i64 0, i64 %7
  %9 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %10 = trunc i8 %9 to i1
  %11 = load i8, ptr %0, align 8, !range !20
  %12 = trunc nuw i8 %11 to i1
  %13 = select i1 %10, i1 %12, i1 false
  br i1 %13, label %14, label %391

14:                                               ; preds = %5
  %15 = load volatile i8, ptr @"?g_percOn@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %16 = trunc i8 %15 to i1
  br i1 %16, label %17, label %151

17:                                               ; preds = %14
  store i64 1, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 240), align 16
  %18 = getelementptr inbounds nuw i8, ptr %8, i64 229608
  %19 = load <2 x i64>, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", align 16
  %20 = load <2 x i64>, ptr %18, align 8
  %21 = add <2 x i64> %20, %19
  store <2 x i64> %21, ptr %18, align 8
  %22 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 16), align 16
  %23 = getelementptr inbounds nuw i8, ptr %8, i64 229624
  %24 = load i64, ptr %23, align 8
  %25 = icmp ugt i64 %22, %24
  br i1 %25, label %26, label %27

26:                                               ; preds = %17
  store i64 %22, ptr %23, align 8
  br label %27

27:                                               ; preds = %26, %17
  %28 = getelementptr inbounds nuw i8, ptr %8, i64 229632
  %29 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 24), align 8
  %30 = load <2 x i64>, ptr %28, align 8
  %31 = add <2 x i64> %30, %29
  store <2 x i64> %31, ptr %28, align 8
  %32 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 40), align 8
  %33 = getelementptr inbounds nuw i8, ptr %8, i64 229648
  %34 = load i64, ptr %33, align 8
  %35 = icmp ugt i64 %32, %34
  br i1 %35, label %36, label %37

36:                                               ; preds = %27
  store i64 %32, ptr %33, align 8
  br label %37

37:                                               ; preds = %36, %27
  %38 = getelementptr inbounds nuw i8, ptr %8, i64 229656
  %39 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 48), align 16
  %40 = load <2 x i64>, ptr %38, align 8
  %41 = add <2 x i64> %40, %39
  store <2 x i64> %41, ptr %38, align 8
  %42 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 64), align 16
  %43 = getelementptr inbounds nuw i8, ptr %8, i64 229672
  %44 = load i64, ptr %43, align 8
  %45 = icmp ugt i64 %42, %44
  br i1 %45, label %46, label %47

46:                                               ; preds = %37
  store i64 %42, ptr %43, align 8
  br label %47

47:                                               ; preds = %46, %37
  %48 = getelementptr inbounds nuw i8, ptr %8, i64 229680
  %49 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 72), align 8
  %50 = load <2 x i64>, ptr %48, align 8
  %51 = add <2 x i64> %50, %49
  store <2 x i64> %51, ptr %48, align 8
  %52 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 88), align 8
  %53 = getelementptr inbounds nuw i8, ptr %8, i64 229696
  %54 = load i64, ptr %53, align 8
  %55 = icmp ugt i64 %52, %54
  br i1 %55, label %56, label %57

56:                                               ; preds = %47
  store i64 %52, ptr %53, align 8
  br label %57

57:                                               ; preds = %56, %47
  %58 = getelementptr inbounds nuw i8, ptr %8, i64 229704
  %59 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 96), align 16
  %60 = load <2 x i64>, ptr %58, align 8
  %61 = add <2 x i64> %60, %59
  store <2 x i64> %61, ptr %58, align 8
  %62 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 112), align 16
  %63 = getelementptr inbounds nuw i8, ptr %8, i64 229720
  %64 = load i64, ptr %63, align 8
  %65 = icmp ugt i64 %62, %64
  br i1 %65, label %66, label %67

66:                                               ; preds = %57
  store i64 %62, ptr %63, align 8
  br label %67

67:                                               ; preds = %66, %57
  %68 = getelementptr inbounds nuw i8, ptr %8, i64 229728
  %69 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 120), align 8
  %70 = load <2 x i64>, ptr %68, align 8
  %71 = add <2 x i64> %70, %69
  store <2 x i64> %71, ptr %68, align 8
  %72 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 136), align 8
  %73 = getelementptr inbounds nuw i8, ptr %8, i64 229744
  %74 = load i64, ptr %73, align 8
  %75 = icmp ugt i64 %72, %74
  br i1 %75, label %76, label %77

76:                                               ; preds = %67
  store i64 %72, ptr %73, align 8
  br label %77

77:                                               ; preds = %76, %67
  %78 = getelementptr inbounds nuw i8, ptr %8, i64 229752
  %79 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 144), align 16
  %80 = load <2 x i64>, ptr %78, align 8
  %81 = add <2 x i64> %80, %79
  store <2 x i64> %81, ptr %78, align 8
  %82 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 160), align 16
  %83 = getelementptr inbounds nuw i8, ptr %8, i64 229768
  %84 = load i64, ptr %83, align 8
  %85 = icmp ugt i64 %82, %84
  br i1 %85, label %86, label %87

86:                                               ; preds = %77
  store i64 %82, ptr %83, align 8
  br label %87

87:                                               ; preds = %86, %77
  %88 = getelementptr inbounds nuw i8, ptr %8, i64 229776
  %89 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 168), align 8
  %90 = load <2 x i64>, ptr %88, align 8
  %91 = add <2 x i64> %90, %89
  store <2 x i64> %91, ptr %88, align 8
  %92 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 184), align 8
  %93 = getelementptr inbounds nuw i8, ptr %8, i64 229792
  %94 = load i64, ptr %93, align 8
  %95 = icmp ugt i64 %92, %94
  br i1 %95, label %96, label %97

96:                                               ; preds = %87
  store i64 %92, ptr %93, align 8
  br label %97

97:                                               ; preds = %96, %87
  %98 = getelementptr inbounds nuw i8, ptr %8, i64 229800
  %99 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 192), align 16
  %100 = load <2 x i64>, ptr %98, align 8
  %101 = add <2 x i64> %100, %99
  store <2 x i64> %101, ptr %98, align 8
  %102 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 208), align 16
  %103 = getelementptr inbounds nuw i8, ptr %8, i64 229816
  %104 = load i64, ptr %103, align 8
  %105 = icmp ugt i64 %102, %104
  br i1 %105, label %106, label %107

106:                                              ; preds = %97
  store i64 %102, ptr %103, align 8
  br label %107

107:                                              ; preds = %106, %97
  %108 = getelementptr inbounds nuw i8, ptr %8, i64 229824
  %109 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 216), align 8
  %110 = load <2 x i64>, ptr %108, align 8
  %111 = add <2 x i64> %110, %109
  store <2 x i64> %111, ptr %108, align 8
  %112 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 232), align 8
  %113 = getelementptr inbounds nuw i8, ptr %8, i64 229840
  %114 = load i64, ptr %113, align 8
  %115 = icmp ugt i64 %112, %114
  br i1 %115, label %116, label %117

116:                                              ; preds = %107
  store i64 %112, ptr %113, align 8
  br label %117

117:                                              ; preds = %107, %116
  %118 = getelementptr inbounds nuw i8, ptr %8, i64 229848
  %119 = getelementptr inbounds nuw i8, ptr %8, i64 229896
  %120 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 248), align 8
  %121 = load <2 x i64>, ptr %118, align 8
  %122 = insertelement <2 x i64> <i64 1, i64 poison>, i64 %120, i64 1
  %123 = add <2 x i64> %121, %122
  store <2 x i64> %123, ptr %118, align 8
  %124 = getelementptr inbounds nuw i8, ptr %8, i64 229864
  %125 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 256), align 16
  %126 = load <2 x i64>, ptr %124, align 8
  %127 = add <2 x i64> %126, %125
  store <2 x i64> %127, ptr %124, align 8
  %128 = getelementptr inbounds nuw i8, ptr %8, i64 229880
  %129 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 272), align 16
  %130 = load <2 x i64>, ptr %128, align 8
  %131 = add <2 x i64> %130, %129
  store <2 x i64> %131, ptr %128, align 8
  %132 = getelementptr inbounds nuw i8, ptr %8, i64 229928
  %133 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 288), align 16
  %134 = load <2 x i64>, ptr %119, align 8
  %135 = add <2 x i64> %134, %133
  store <2 x i64> %135, ptr %119, align 8
  %136 = getelementptr inbounds nuw i8, ptr %8, i64 229912
  %137 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 320), align 16
  %138 = load <2 x i64>, ptr %132, align 8
  %139 = add <2 x i64> %138, %137
  store <2 x i64> %139, ptr %132, align 8
  %140 = getelementptr inbounds nuw i8, ptr %8, i64 229960
  %141 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 304), align 16
  %142 = load <2 x i64>, ptr %136, align 8
  %143 = add <2 x i64> %142, %141
  store <2 x i64> %143, ptr %136, align 8
  %144 = getelementptr inbounds nuw i8, ptr %8, i64 229944
  %145 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 336), align 16
  %146 = load <2 x i64>, ptr %144, align 8
  %147 = add <2 x i64> %146, %145
  store <2 x i64> %147, ptr %144, align 8
  %148 = load <2 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i64 352), align 16
  %149 = load <2 x i64>, ptr %140, align 8
  %150 = add <2 x i64> %149, %148
  store <2 x i64> %150, ptr %140, align 8
  br label %151

151:                                              ; preds = %117, %14
  %152 = getelementptr inbounds nuw i8, ptr %8, i64 229416
  %153 = load i64, ptr %152, align 8
  %154 = icmp eq i64 %153, 0
  br i1 %154, label %155, label %162

155:                                              ; preds = %151
  %156 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %157 = load i64, ptr %156, align 8
  %158 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %159 = load i32, ptr %158, align 8
  %160 = zext i32 %159 to i64
  %161 = sub i64 %157, %160
  store i64 %161, ptr %152, align 8
  br label %162

162:                                              ; preds = %155, %151
  %163 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %164 = load i64, ptr %163, align 8
  %165 = getelementptr inbounds nuw i8, ptr %8, i64 229424
  store i64 %164, ptr %165, align 8
  %166 = getelementptr inbounds nuw i8, ptr %8, i64 229400
  %167 = load i64, ptr %166, align 8
  %168 = add i64 %167, 1
  store i64 %168, ptr %166, align 8
  %169 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %170 = load i32, ptr %169, align 8
  %171 = zext i32 %170 to i64
  %172 = getelementptr inbounds nuw i8, ptr %8, i64 229512
  %173 = load i64, ptr %172, align 8
  %174 = add i64 %173, %171
  store i64 %174, ptr %172, align 8
  %175 = getelementptr inbounds nuw i8, ptr %0, i64 28
  %176 = load i32, ptr %175, align 4
  %177 = zext i32 %176 to i64
  %178 = getelementptr inbounds nuw i8, ptr %8, i64 229496
  %179 = load i64, ptr %178, align 8
  %180 = add i64 %179, %177
  store i64 %180, ptr %178, align 8
  %181 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %182 = load i32, ptr %181, align 8
  %183 = zext i32 %182 to i64
  %184 = getelementptr inbounds nuw i8, ptr %8, i64 229504
  %185 = load i64, ptr %184, align 8
  %186 = add i64 %185, %183
  store i64 %186, ptr %184, align 8
  %187 = getelementptr inbounds nuw i8, ptr %0, i64 36
  %188 = getelementptr inbounds nuw i8, ptr %8, i64 229432
  %189 = load i32, ptr %187, align 4
  %190 = zext i32 %189 to i64
  %191 = load i64, ptr %188, align 8
  %192 = add i64 %191, %190
  store i64 %192, ptr %188, align 8
  %193 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %194 = load i32, ptr %193, align 8
  %195 = zext i32 %194 to i64
  %196 = getelementptr inbounds nuw i8, ptr %8, i64 229440
  %197 = load i64, ptr %196, align 8
  %198 = add i64 %197, %195
  store i64 %198, ptr %196, align 8
  %199 = getelementptr inbounds nuw i8, ptr %0, i64 44
  %200 = load i32, ptr %199, align 4
  %201 = zext i32 %200 to i64
  %202 = getelementptr inbounds nuw i8, ptr %8, i64 229448
  %203 = load i64, ptr %202, align 8
  %204 = add i64 %203, %201
  store i64 %204, ptr %202, align 8
  %205 = getelementptr inbounds nuw i8, ptr %0, i64 48
  %206 = load i32, ptr %205, align 8
  %207 = zext i32 %206 to i64
  %208 = getelementptr inbounds nuw i8, ptr %8, i64 229456
  %209 = load i64, ptr %208, align 8
  %210 = add i64 %209, %207
  store i64 %210, ptr %208, align 8
  %211 = getelementptr inbounds nuw i8, ptr %0, i64 52
  %212 = load i32, ptr %211, align 4
  %213 = zext i32 %212 to i64
  %214 = getelementptr inbounds nuw i8, ptr %8, i64 229464
  %215 = load i64, ptr %214, align 8
  %216 = add i64 %215, %213
  store i64 %216, ptr %214, align 8
  %217 = getelementptr inbounds nuw i8, ptr %0, i64 56
  %218 = load i32, ptr %217, align 8
  %219 = zext i32 %218 to i64
  %220 = getelementptr inbounds nuw i8, ptr %8, i64 229472
  %221 = load i64, ptr %220, align 8
  %222 = add i64 %221, %219
  store i64 %222, ptr %220, align 8
  %223 = getelementptr inbounds nuw i8, ptr %0, i64 60
  %224 = load i32, ptr %223, align 4
  %225 = zext i32 %224 to i64
  %226 = getelementptr inbounds nuw i8, ptr %8, i64 229480
  %227 = load i64, ptr %226, align 8
  %228 = add i64 %227, %225
  store i64 %228, ptr %226, align 8
  %229 = getelementptr inbounds nuw i8, ptr %0, i64 64
  %230 = load i32, ptr %229, align 8
  %231 = zext i32 %230 to i64
  %232 = getelementptr inbounds nuw i8, ptr %8, i64 229488
  %233 = load i64, ptr %232, align 8
  %234 = add i64 %233, %231
  store i64 %234, ptr %232, align 8
  %235 = getelementptr inbounds nuw i8, ptr %8, i64 229520
  %236 = getelementptr inbounds nuw i8, ptr %8, i64 229536
  %237 = load <4 x i64>, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", align 32
  %238 = load <2 x i64>, ptr %235, align 8
  %239 = shufflevector <4 x i64> %237, <4 x i64> poison, <2 x i32> <i32 0, i32 1>
  %240 = add <2 x i64> %238, %239
  store <2 x i64> %240, ptr %235, align 8
  %241 = load <2 x i64>, ptr %236, align 8
  %242 = shufflevector <4 x i64> %237, <4 x i64> poison, <2 x i32> <i32 2, i32 3>
  %243 = add <2 x i64> %241, %242
  store <2 x i64> %243, ptr %236, align 8
  %244 = getelementptr inbounds nuw i8, ptr %8, i64 229552
  %245 = getelementptr inbounds nuw i8, ptr %8, i64 229568
  %246 = load <4 x i64>, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 32), align 32
  %247 = load <2 x i64>, ptr %244, align 8
  %248 = shufflevector <4 x i64> %246, <4 x i64> poison, <2 x i32> <i32 0, i32 1>
  %249 = add <2 x i64> %247, %248
  store <2 x i64> %249, ptr %244, align 8
  %250 = load <2 x i64>, ptr %245, align 8
  %251 = shufflevector <4 x i64> %246, <4 x i64> poison, <2 x i32> <i32 2, i32 3>
  %252 = add <2 x i64> %250, %251
  store <2 x i64> %252, ptr %245, align 8
  %253 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i64 64), align 32
  %254 = getelementptr inbounds nuw i8, ptr %8, i64 229584
  %255 = load i64, ptr %254, align 8
  %256 = add i64 %255, %253
  store i64 %256, ptr %254, align 8
  %257 = getelementptr inbounds nuw i8, ptr %0, i64 1
  %258 = load i8, ptr %257, align 1, !range !20, !noundef !21
  %259 = trunc nuw i8 %258 to i1
  br i1 %259, label %260, label %391

260:                                              ; preds = %162
  %261 = getelementptr inbounds nuw i8, ptr %8, i64 229408
  %262 = load i64, ptr %261, align 8
  %263 = add i64 %262, 1
  store i64 %263, ptr %261, align 8
  call void @llvm.lifetime.start.p0(i64 144, ptr nonnull %2) #30
  %264 = getelementptr inbounds nuw i8, ptr %2, i64 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(128) %264, i8 0, i64 128, i1 false)
  %265 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %266 = load <2 x i64>, ptr %265, align 8
  store <2 x i64> %266, ptr %2, align 16
  %267 = load i32, ptr %169, align 8
  %268 = getelementptr inbounds nuw i8, ptr %2, i64 16
  store i32 %267, ptr %268, align 16
  %269 = load i64, ptr @"?g_frameExecTicks@?A0xB9C01504@opf@@3_KA", align 8
  %270 = uitofp i64 %269 to double
  %271 = fmul double %270, 1.000000e+03
  %272 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %273 = sitofp i64 %272 to double
  %274 = fdiv double %271, %273
  %275 = fmul double %274, 1.000000e+03
  %276 = fcmp ogt double %275, 4.000000e+09
  %277 = fptoui double %275 to i32
  %278 = select i1 %276, i32 -1, i32 %277
  %279 = getelementptr inbounds nuw i8, ptr %2, i64 132
  store i32 %278, ptr %279, align 4
  %280 = load i64, ptr @"?g_frameExecCalls@?A0xB9C01504@opf@@3_KA", align 8
  %281 = trunc i64 %280 to i32
  %282 = getelementptr inbounds nuw i8, ptr %2, i64 136
  store i32 %281, ptr %282, align 8
  %283 = load i32, ptr @"?g_nTouched@?A0xB9C01504@opf@@3IA", align 4
  %284 = icmp eq i32 %283, 0
  br i1 %284, label %297, label %285

285:                                              ; preds = %260
  %286 = load i64, ptr @"?g_frameNo@?A0xB9C01504@opf@@3_KA", align 8
  %287 = getelementptr inbounds nuw i8, ptr %2, i64 24
  %288 = zext i32 %283 to i64
  %289 = getelementptr inbounds nuw i8, ptr %2, i64 44
  %290 = getelementptr inbounds nuw i8, ptr %2, i64 48
  %291 = getelementptr inbounds nuw i8, ptr %2, i64 68
  %292 = getelementptr inbounds nuw i8, ptr %2, i64 72
  %293 = getelementptr inbounds nuw i8, ptr %2, i64 92
  %294 = getelementptr inbounds nuw i8, ptr %2, i64 48
  %295 = getelementptr inbounds nuw i8, ptr %2, i64 72
  %296 = getelementptr inbounds nuw i8, ptr %2, i64 48
  br label %328

297:                                              ; preds = %381, %260
  %298 = getelementptr inbounds nuw i8, ptr %2, i64 96
  %299 = uitofp <4 x i64> %237 to <4 x double>
  %300 = fmul <4 x double> %299, splat (double 1.000000e+03)
  %301 = insertelement <4 x double> poison, double %273, i64 0
  %302 = shufflevector <4 x double> %301, <4 x double> poison, <4 x i32> zeroinitializer
  %303 = fdiv <4 x double> %300, %302
  %304 = fmul <4 x double> %303, splat (double 1.000000e+03)
  %305 = fcmp ogt <4 x double> %304, splat (double 4.000000e+09)
  %306 = fptoui <4 x double> %304 to <4 x i32>
  %307 = select <4 x i1> %305, <4 x i32> splat (i32 -1), <4 x i32> %306
  store <4 x i32> %307, ptr %298, align 16
  %308 = uitofp <4 x i64> %246 to <4 x double>
  %309 = getelementptr inbounds nuw i8, ptr %2, i64 112
  %310 = fmul <4 x double> %308, splat (double 1.000000e+03)
  %311 = fdiv <4 x double> %310, %302
  %312 = fmul <4 x double> %311, splat (double 1.000000e+03)
  %313 = fcmp ogt <4 x double> %312, splat (double 4.000000e+09)
  %314 = fptoui <4 x double> %312 to <4 x i32>
  %315 = select <4 x i1> %313, <4 x i32> splat (i32 -1), <4 x i32> %314
  store <4 x i32> %315, ptr %309, align 16
  %316 = uitofp i64 %253 to double
  %317 = fmul double %316, 1.000000e+03
  %318 = fdiv double %317, %273
  %319 = fmul double %318, 1.000000e+03
  %320 = fcmp ogt double %319, 4.000000e+09
  %321 = fptoui double %319 to i32
  %322 = select i1 %320, i32 -1, i32 %321
  %323 = getelementptr inbounds nuw i8, ptr %2, i64 128
  store i32 %322, ptr %323, align 16
  %324 = load volatile i64, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  %325 = load volatile i64, ptr @"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  fence syncscope("singlethread") seq_cst
  %326 = sub i64 %324, %325
  %327 = icmp ult i64 %326, 512
  br i1 %327, label %384, label %388

328:                                              ; preds = %285, %381
  %329 = phi i64 [ 0, %285 ], [ %382, %381 ]
  %330 = getelementptr inbounds nuw [2048 x ptr], ptr @"?g_touched@?A0xB9C01504@opf@@3PAPEAUEntry@?A0xB9C01504@1@A", i64 0, i64 %329
  %331 = load ptr, ptr %330, align 8
  %332 = getelementptr inbounds nuw i8, ptr %331, i64 48
  %333 = load i64, ptr %332, align 8
  %334 = icmp eq i64 %333, %286
  br i1 %334, label %335, label %381

335:                                              ; preds = %328
  %336 = getelementptr inbounds nuw i8, ptr %331, i64 40
  %337 = load ptr, ptr %287, align 8
  %338 = icmp eq ptr %337, null
  br i1 %338, label %365, label %339

339:                                              ; preds = %335
  %340 = load i64, ptr %336, align 8
  %341 = uitofp i64 %340 to double
  %342 = fmul double %341, 1.000000e+03
  %343 = fdiv double %342, %273
  %344 = fmul double %343, 1.000000e+03
  %345 = fcmp ogt double %344, 4.000000e+09
  %346 = fptoui double %344 to i32
  %347 = select i1 %345, i32 -1, i32 %346
  %348 = load i32, ptr %289, align 4
  %349 = icmp ugt i32 %347, %348
  br i1 %349, label %365, label %369

350:                                              ; preds = %365, %368, %375
  %351 = phi ptr [ %292, %375 ], [ %367, %368 ], [ %367, %365 ]
  %352 = getelementptr inbounds nuw i8, ptr %331, i64 16
  %353 = load i32, ptr %352, align 8
  %354 = load i64, ptr %336, align 8
  %355 = uitofp i64 %354 to double
  %356 = fmul double %355, 1.000000e+03
  %357 = fdiv double %356, %273
  %358 = fmul double %357, 1.000000e+03
  %359 = fcmp ogt double %358, 4.000000e+09
  %360 = fptoui double %358 to i32
  %361 = select i1 %359, i32 -1, i32 %360
  %362 = load <2 x ptr>, ptr %331, align 8
  store <2 x ptr> %362, ptr %351, align 8
  %363 = getelementptr inbounds nuw i8, ptr %351, i64 16
  store i32 %353, ptr %363, align 8
  %364 = getelementptr inbounds nuw i8, ptr %351, i64 20
  store i32 %361, ptr %364, align 4
  br label %381

365:                                              ; preds = %369, %335, %339
  %366 = phi i1 [ false, %369 ], [ true, %335 ], [ true, %339 ]
  %367 = phi ptr [ %290, %369 ], [ %287, %335 ], [ %287, %339 ]
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %295, ptr noundef nonnull align 16 dereferenceable(24) %294, i64 24, i1 false)
  br i1 %366, label %368, label %350, !llvm.loop !28

368:                                              ; preds = %365
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %296, ptr noundef nonnull align 8 dereferenceable(24) %287, i64 24, i1 false)
  br label %350

369:                                              ; preds = %339
  %370 = load ptr, ptr %290, align 16
  %371 = icmp eq ptr %370, null
  %372 = load i32, ptr %291, align 4
  %373 = icmp ugt i32 %347, %372
  %374 = select i1 %371, i1 true, i1 %373
  br i1 %374, label %365, label %375

375:                                              ; preds = %369
  %376 = load ptr, ptr %292, align 8
  %377 = icmp eq ptr %376, null
  %378 = load i32, ptr %293, align 4
  %379 = icmp ugt i32 %347, %378
  %380 = select i1 %377, i1 true, i1 %379
  br i1 %380, label %350, label %381

381:                                              ; preds = %375, %350, %328
  %382 = add nuw nsw i64 %329, 1
  %383 = icmp eq i64 %382, %288
  br i1 %383, label %297, label %328, !llvm.loop !29

384:                                              ; preds = %297
  %385 = and i64 %324, 511
  %386 = getelementptr inbounds nuw [512 x %"struct.opf::(anonymous namespace)::TRec"], ptr @"?g_tring@?A0xB9C01504@opf@@3PAUTRec@?A0xB9C01504@1@A", i64 0, i64 %385
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(144) %386, ptr noundef nonnull align 16 dereferenceable(144) %2, i64 144, i1 false)
  %387 = add i64 %324, 1
  fence syncscope("singlethread") seq_cst
  store volatile i64 %387, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  br label %390

388:                                              ; preds = %297
  %389 = atomicrmw add ptr @"?g_tdropped@?A0xB9C01504@opf@@3U?$atomic@I@std@@A", i32 1 seq_cst, align 4
  br label %390

390:                                              ; preds = %388, %384
  call void @llvm.lifetime.end.p0(i64 144, ptr nonnull %2) #30
  br label %391

391:                                              ; preds = %162, %390, %5
  %392 = load i8, ptr %0, align 8, !range !20
  %393 = trunc nuw i8 %392 to i1
  %394 = select i1 %10, i1 %393, i1 false
  br i1 %394, label %395, label %414

395:                                              ; preds = %391
  %396 = getelementptr inbounds nuw i8, ptr %8, i64 229424
  %397 = load i64, ptr %396, align 8
  %398 = getelementptr inbounds nuw i8, ptr %8, i64 229416
  %399 = load i64, ptr %398, align 8
  %400 = sub i64 %397, %399
  %401 = icmp ugt i64 %400, 1999999
  %402 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20
  %403 = trunc nuw i8 %402 to i1
  %404 = select i1 %401, i1 %403, i1 false
  br i1 %404, label %405, label %414

405:                                              ; preds = %395
  %406 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %407 = trunc i8 %406 to i1
  br i1 %407, label %408, label %414

408:                                              ; preds = %405
  %409 = load volatile i32, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  fence syncscope("singlethread") seq_cst
  %410 = icmp eq i32 %409, -1
  br i1 %410, label %411, label %414

411:                                              ; preds = %408
  %412 = load i32, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  %413 = xor i32 %412, 1
  store i32 %413, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  fence syncscope("singlethread") seq_cst
  store volatile i32 %412, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  br label %414

414:                                              ; preds = %411, %408, %405, %395, %391
  %415 = load i64, ptr @"?g_frameNo@?A0xB9C01504@opf@@3_KA", align 8
  %416 = add i64 %415, 1
  store i64 %416, ptr @"?g_frameNo@?A0xB9C01504@opf@@3_KA", align 8
  store i32 0, ptr @"?g_nTouched@?A0xB9C01504@opf@@3IA", align 4
  store i64 0, ptr @"?g_frameExecCalls@?A0xB9C01504@opf@@3_KA", align 8
  store i64 0, ptr @"?g_frameExecTicks@?A0xB9C01504@opf@@3_KA", align 8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 32 dereferenceable(72) @"?g_frameBucket@?A0xB9C01504@opf@@3PA_KA", i8 0, i64 72, i1 false)
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(368) @"?g_percFrame@?A0xB9C01504@opf@@3UPercAcc@?A0xB9C01504@1@A", i8 0, i64 368, i1 false)
  store i64 0, ptr @"?g_camTs@?A0xB9C01504@opf@@3_KA", align 8
  store i64 0, ptr @"?g_setupEnd@?A0xB9C01504@opf@@3_KA", align 8
  store i64 0, ptr @"?g_preTs@?A0xB9C01504@opf@@3_KA", align 8
  store i32 0, ptr @"?g_depth@?A0xB9C01504@opf@@3HA", align 4
  store i32 15, ptr @"?g_curGroup@?A0xB9C01504@opf@@3IA", align 4
  br label %417

417:                                              ; preds = %1, %414
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #11

; Function Attrs: mustprogress nofree norecurse nounwind sspstrong uwtable
define dso_local void @"?TickSplitWindowEnd@opf@@YAXXZ"() local_unnamed_addr #10 {
  %1 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %2 = trunc nuw i8 %1 to i1
  br i1 %2, label %3, label %12

3:                                                ; preds = %0
  %4 = load volatile i8, ptr @"?g_on@?A0xB9C01504@opf@@3U?$atomic@_N@std@@A", align 1
  %5 = trunc i8 %4 to i1
  br i1 %5, label %6, label %12

6:                                                ; preds = %3
  %7 = load volatile i32, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  fence syncscope("singlethread") seq_cst
  %8 = icmp eq i32 %7, -1
  br i1 %8, label %9, label %12

9:                                                ; preds = %6
  %10 = load i32, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  %11 = xor i32 %10, 1
  store i32 %11, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  fence syncscope("singlethread") seq_cst
  store volatile i32 %10, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  br label %12

12:                                               ; preds = %6, %0, %3, %9
  ret void
}

; Function Attrs: mustprogress sspstrong uwtable
define dso_local void @"?TickSplitDrain@opf@@YAXXZ"() local_unnamed_addr #5 personality ptr @__CxxFrameHandler3 {
  %1 = alloca [1024 x i8], align 16
  %2 = alloca %"class.std::basic_string.22", align 8
  %3 = alloca %"class.std::basic_string.22", align 8
  %4 = alloca [1024 x i8], align 16
  %5 = alloca %"class.std::allocator", align 1
  %6 = alloca %"class.std::basic_string", align 8
  %7 = alloca %"class.std::basic_string", align 8
  %8 = alloca [3072 x i8], align 16
  %9 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  %10 = trunc nuw i8 %9 to i1
  br i1 %10, label %11, label %1120

11:                                               ; preds = %0
  %12 = load volatile i32, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  fence syncscope("singlethread") seq_cst
  %13 = icmp sgt i32 %12, -1
  br i1 %13, label %18, label %14

14:                                               ; preds = %11
  %15 = load volatile i64, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  fence syncscope("singlethread") seq_cst
  %16 = load volatile i64, ptr @"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  %17 = icmp eq i64 %15, %16
  br i1 %17, label %1120, label %18

18:                                               ; preds = %11, %14
  %19 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %20 = icmp eq ptr %19, null
  br i1 %20, label %21, label %160

21:                                               ; preds = %18
  %22 = load i1, ptr @"?g_fileFailed@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %22, label %154, label %23

23:                                               ; preds = %21
  %24 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 16), align 8
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %154, label %26

26:                                               ; preds = %23
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %6) #30
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %7) #30
  %27 = add i64 %24, -4
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %5) #30, !noalias !30
  %28 = call noundef ptr @"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@AEBV01@_K1AEBV?$allocator@_W@1@@Z"(ptr noundef nonnull align 8 dereferenceable(32) %7, ptr noundef nonnull align 8 dereferenceable(32) @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 noundef 0, i64 noundef %27, ptr noundef nonnull align 1 dereferenceable(1) %5)
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %5) #30, !noalias !30
  invoke void @llvm.seh.scope.begin()
          to label %29 unwind label %96

29:                                               ; preds = %26
  %30 = getelementptr inbounds nuw i8, ptr %7, i64 16
  %31 = load i64, ptr %30, align 8, !noalias !33
  %32 = getelementptr inbounds nuw i8, ptr %7, i64 24
  %33 = load i64, ptr %32, align 8, !noalias !33
  %34 = sub i64 %33, %31
  %35 = icmp ult i64 %34, 6
  br i1 %35, label %43, label %36

36:                                               ; preds = %29
  %37 = add i64 %31, 6
  store i64 %37, ptr %30, align 8, !noalias !33
  %38 = icmp ugt i64 %33, 7
  %39 = load ptr, ptr %7, align 8, !noalias !33
  %40 = select i1 %38, ptr %39, ptr %7
  %41 = getelementptr inbounds nuw i16, ptr %40, i64 %31
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 2 dereferenceable(12) %41, ptr noundef nonnull align 2 dereferenceable(12) @"??_C@_1O@GLCFMFBP@?$AA?4?$AA1?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@", i64 12, i1 false), !noalias !33
  %42 = getelementptr inbounds nuw i16, ptr %40, i64 %37
  store i16 0, ptr %42, align 2, !noalias !33
  br label %45

43:                                               ; preds = %29
  %44 = invoke noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W_K@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEB_W0@Z@PEB_W_K@Z"(ptr noundef nonnull align 8 dereferenceable(32) %7, i64 noundef 6, i8 undef, ptr noundef nonnull @"??_C@_1O@GLCFMFBP@?$AA?4?$AA1?$AA?4?$AAc?$AAs?$AAv?$AA?$AA@", i64 noundef 6)
          to label %45 unwind label %96

45:                                               ; preds = %43, %36
  %46 = phi ptr [ %7, %36 ], [ %44, %43 ]
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %6, ptr noundef nonnull align 8 dereferenceable(32) %46, i64 32, i1 false)
  %47 = getelementptr inbounds nuw i8, ptr %46, i64 16
  store i64 0, ptr %47, align 8, !noalias !33
  %48 = getelementptr inbounds nuw i8, ptr %46, i64 24
  store i64 7, ptr %48, align 8, !noalias !33
  store i16 0, ptr %46, align 8, !noalias !33
  invoke void @llvm.seh.scope.end()
          to label %49 unwind label %96

49:                                               ; preds = %45
  tail call void @llvm.seh.scope.begin()
  %50 = load i64, ptr %32, align 8
  %51 = icmp ugt i64 %50, 7
  br i1 %51, label %52, label %71

52:                                               ; preds = %49
  %53 = load ptr, ptr %7, align 8
  %54 = shl i64 %50, 1
  %55 = add i64 %54, 2
  %56 = icmp ugt i64 %55, 4095
  br i1 %56, label %57, label %68

57:                                               ; preds = %52
  %58 = getelementptr inbounds i8, ptr %53, i64 -8
  %59 = load i64, ptr %58, align 8
  %60 = ptrtoint ptr %53 to i64
  %61 = add i64 %60, -8
  %62 = sub i64 %61, %59
  %63 = icmp ult i64 %62, 32
  br i1 %63, label %65, label %64

64:                                               ; preds = %57
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

65:                                               ; preds = %57
  %66 = add i64 %54, 41
  %67 = inttoptr i64 %59 to ptr
  br label %68

68:                                               ; preds = %65, %52
  %69 = phi i64 [ %66, %65 ], [ %55, %52 ]
  %70 = phi ptr [ %67, %65 ], [ %53, %52 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %70, i64 noundef %69) #30
  br label %71

71:                                               ; preds = %68, %49
  tail call void @llvm.seh.scope.end()
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %7) #30
  invoke void @llvm.seh.scope.begin()
          to label %72 unwind label %152

72:                                               ; preds = %71
  %73 = getelementptr inbounds nuw i8, ptr %6, i64 24
  %74 = load i64, ptr %73, align 8
  %75 = icmp ugt i64 %74, 7
  %76 = load ptr, ptr %6, align 8
  %77 = select i1 %75, ptr %76, ptr %6
  %78 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %79 = icmp ugt i64 %78, 7
  %80 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %81 = select i1 %79, ptr %80, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A"
  %82 = invoke i32 @MoveFileExW(ptr noundef %81, ptr noundef %77, i32 noundef 1)
          to label %83 unwind label %152

83:                                               ; preds = %72
  %84 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %85 = icmp ugt i64 %84, 7
  %86 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %87 = select i1 %85, ptr %86, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A"
  %88 = invoke ptr @_wfsopen(ptr noundef %87, ptr noundef nonnull @"??_C@_13CIFDLIMG@?$AAw?$AA?$AA@", i32 noundef 32)
          to label %89 unwind label %152

89:                                               ; preds = %83
  store ptr %88, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %90 = icmp eq ptr %88, null
  br i1 %90, label %91, label %98

91:                                               ; preds = %89
  store i1 true, ptr @"?g_fileFailed@?A0xB9C01504@opf@@3_NA", align 1
  %92 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %93 = icmp ugt i64 %92, 7
  %94 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %95 = select i1 %93, ptr %94, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A"
  invoke void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CB@HDKOBCJ@?$FLticksplit?$FN?5could?5not?5create?5?$CFls@", ptr noundef %95)
          to label %128 unwind label %152

96:                                               ; preds = %45, %43, %26
  %97 = cleanuppad within none []
  call void @"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %7) #30 [ "funclet"(token %97) ]
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %7) #30
  cleanupret from %97 unwind to caller

98:                                               ; preds = %89
  call void @llvm.lifetime.start.p0(i64 3072, ptr nonnull %8) #30
  %99 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %100 = invoke i32 @GetCurrentProcessId()
          to label %101 unwind label %152

101:                                              ; preds = %98
  %102 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %8, i64 noundef 3072, ptr noundef nonnull @"??_C@_0EMA@BFPHIDFE@?$CD?5OblivionPerfFix?9ticksplit?5v1?0?5@", i32 noundef %100, i64 noundef %99) #30
  %103 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %104 = icmp eq ptr %103, null
  %105 = icmp slt i32 %102, 1
  %106 = or i1 %105, %104
  br i1 %106, label %119, label %107

107:                                              ; preds = %101
  %108 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %109 = add nuw nsw i32 %108, %102
  %110 = icmp sgt i32 %109, 67108864
  br i1 %110, label %111, label %114

111:                                              ; preds = %107
  %112 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %112, label %119, label %113

113:                                              ; preds = %111
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  invoke void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
          to label %119 unwind label %152

114:                                              ; preds = %107
  %115 = zext nneg i32 %102 to i64
  %116 = call i64 @fwrite(ptr noundef nonnull readonly %8, i64 noundef 1, i64 noundef %115, ptr noundef nonnull %103)
  %117 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %118 = add nuw nsw i32 %117, %102
  store i32 %118, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %119

119:                                              ; preds = %114, %113, %111, %101
  %120 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %121 = invoke i32 @fflush(ptr noundef %120)
          to label %122 unwind label %152

122:                                              ; preds = %119
  %123 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %124 = icmp ugt i64 %123, 7
  %125 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %126 = select i1 %124, ptr %125, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A"
  invoke void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CK@JNAPDPCD@?$FLticksplit?$FN?5writing?5the?5tick?5spl@", ptr noundef %126)
          to label %127 unwind label %152

127:                                              ; preds = %122
  call void @llvm.lifetime.end.p0(i64 3072, ptr nonnull %8) #30
  br label %128

128:                                              ; preds = %127, %91
  invoke void @llvm.seh.scope.end()
          to label %129 unwind label %152

129:                                              ; preds = %128
  tail call void @llvm.seh.scope.begin()
  %130 = load i64, ptr %73, align 8
  %131 = icmp ugt i64 %130, 7
  br i1 %131, label %132, label %151

132:                                              ; preds = %129
  %133 = load ptr, ptr %6, align 8
  %134 = shl i64 %130, 1
  %135 = add i64 %134, 2
  %136 = icmp ugt i64 %135, 4095
  br i1 %136, label %137, label %148

137:                                              ; preds = %132
  %138 = getelementptr inbounds i8, ptr %133, i64 -8
  %139 = load i64, ptr %138, align 8
  %140 = ptrtoint ptr %133 to i64
  %141 = add i64 %140, -8
  %142 = sub i64 %141, %139
  %143 = icmp ult i64 %142, 32
  br i1 %143, label %145, label %144

144:                                              ; preds = %137
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

145:                                              ; preds = %137
  %146 = add i64 %134, 41
  %147 = inttoptr i64 %139 to ptr
  br label %148

148:                                              ; preds = %145, %132
  %149 = phi i64 [ %146, %145 ], [ %135, %132 ]
  %150 = phi ptr [ %147, %145 ], [ %133, %132 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %150, i64 noundef %149) #30
  br label %151

151:                                              ; preds = %148, %129
  tail call void @llvm.seh.scope.end()
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %6) #30
  br i1 %90, label %154, label %160

152:                                              ; preds = %128, %122, %119, %113, %98, %91, %83, %72, %71
  %153 = cleanuppad within none []
  call void @"??1?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %6) #30 [ "funclet"(token %153) ]
  cleanupret from %153 unwind to caller

154:                                              ; preds = %21, %23, %151
  %155 = load volatile i64, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  fence syncscope("singlethread") seq_cst
  %156 = atomicrmw xchg ptr @"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", i64 %155 seq_cst, align 8
  br i1 %13, label %157, label %1120

157:                                              ; preds = %154
  %158 = zext nneg i32 %12 to i64
  %159 = getelementptr inbounds nuw [2 x %"struct.opf::(anonymous namespace)::Window"], ptr @"?g_win@?A0xB9C01504@opf@@3PAUWindow@?A0xB9C01504@1@A", i64 0, i64 %158
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(229976) %159, i8 0, i64 229976, i1 false)
  fence syncscope("singlethread") seq_cst
  store volatile i32 -1, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  br label %1120

160:                                              ; preds = %18, %151
  %161 = load volatile i64, ptr @"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  %162 = load volatile i64, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  fence syncscope("singlethread") seq_cst
  %163 = icmp eq i64 %161, %162
  br i1 %163, label %164, label %165

164:                                              ; preds = %432, %160
  br i1 %13, label %435, label %1117

165:                                              ; preds = %160, %432
  %166 = phi i64 [ %220, %432 ], [ %161, %160 ]
  %167 = and i64 %166, 511
  %168 = getelementptr inbounds nuw [512 x %"struct.opf::(anonymous namespace)::TRec"], ptr @"?g_tring@?A0xB9C01504@opf@@3PAUTRec@?A0xB9C01504@1@A", i64 0, i64 %167
  %169 = load i64, ptr %168, align 16
  %170 = getelementptr inbounds nuw i8, ptr %168, i64 8
  %171 = load i64, ptr %170, align 8
  %172 = getelementptr inbounds nuw i8, ptr %168, i64 16
  %173 = load i32, ptr %172, align 16
  %174 = getelementptr inbounds nuw i8, ptr %168, i64 24
  %175 = load ptr, ptr %174, align 8
  %176 = getelementptr inbounds nuw i8, ptr %168, i64 32
  %177 = load ptr, ptr %176, align 16
  %178 = getelementptr inbounds nuw i8, ptr %168, i64 40
  %179 = load i32, ptr %178, align 8
  %180 = getelementptr inbounds nuw i8, ptr %168, i64 44
  %181 = load i32, ptr %180, align 4
  %182 = getelementptr inbounds nuw i8, ptr %168, i64 48
  %183 = load ptr, ptr %182, align 16
  %184 = getelementptr inbounds nuw i8, ptr %168, i64 56
  %185 = load ptr, ptr %184, align 8
  %186 = getelementptr inbounds nuw i8, ptr %168, i64 64
  %187 = load i32, ptr %186, align 16
  %188 = getelementptr inbounds nuw i8, ptr %168, i64 68
  %189 = load i32, ptr %188, align 4
  %190 = getelementptr inbounds nuw i8, ptr %168, i64 72
  %191 = load ptr, ptr %190, align 8
  %192 = getelementptr inbounds nuw i8, ptr %168, i64 80
  %193 = load ptr, ptr %192, align 16
  %194 = getelementptr inbounds nuw i8, ptr %168, i64 88
  %195 = load i32, ptr %194, align 8
  %196 = getelementptr inbounds nuw i8, ptr %168, i64 92
  %197 = load i32, ptr %196, align 4
  %198 = getelementptr inbounds nuw i8, ptr %168, i64 96
  %199 = load i32, ptr %198, align 16
  %200 = getelementptr inbounds nuw i8, ptr %168, i64 100
  %201 = load i32, ptr %200, align 4
  %202 = getelementptr inbounds nuw i8, ptr %168, i64 104
  %203 = load i32, ptr %202, align 8
  %204 = getelementptr inbounds nuw i8, ptr %168, i64 108
  %205 = load i32, ptr %204, align 4
  %206 = getelementptr inbounds nuw i8, ptr %168, i64 112
  %207 = load i32, ptr %206, align 16
  %208 = getelementptr inbounds nuw i8, ptr %168, i64 116
  %209 = load i32, ptr %208, align 4
  %210 = getelementptr inbounds nuw i8, ptr %168, i64 120
  %211 = load i32, ptr %210, align 8
  %212 = getelementptr inbounds nuw i8, ptr %168, i64 124
  %213 = load i32, ptr %212, align 4
  %214 = getelementptr inbounds nuw i8, ptr %168, i64 128
  %215 = load i32, ptr %214, align 16
  %216 = getelementptr inbounds nuw i8, ptr %168, i64 132
  %217 = load i32, ptr %216, align 4
  %218 = getelementptr inbounds nuw i8, ptr %168, i64 136
  %219 = load i32, ptr %218, align 8
  %220 = add i64 %166, 1
  fence syncscope("singlethread") seq_cst
  store volatile i64 %220, ptr @"?g_ttail@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  call void @llvm.lifetime.start.p0(i64 1024, ptr nonnull %4) #30
  %221 = uitofp i32 %217 to double
  %222 = fdiv double %221, 1.000000e+03
  %223 = uitofp i32 %173 to double
  %224 = fdiv double %223, 1.000000e+03
  %225 = uitofp i64 %171 to double
  %226 = fdiv double %225, 1.000000e+03
  %227 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %4, i64 noundef 1024, ptr noundef nonnull @"??_C@_0BJ@PPABGLFN@T?0?$CFllu?0?$CF?43f?0?$CF?43f?0?$CFu?0?$CF?43f?$AA@", i64 noundef %169, double noundef %226, double noundef %224, i32 noundef %219, double noundef %222) #30
  %228 = icmp eq ptr %175, null
  br i1 %228, label %260, label %229

229:                                              ; preds = %165
  %230 = and i32 %179, 255
  %231 = uitofp i32 %181 to double
  %232 = fdiv double %231, 1.000000e+03
  %233 = icmp eq i32 %230, 16
  %234 = call fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %177, i1 noundef zeroext %233)
  %235 = getelementptr inbounds nuw i8, ptr %234, i64 24
  %236 = load i64, ptr %235, align 8
  %237 = icmp ugt i64 %236, 15
  %238 = load ptr, ptr %234, align 8
  %239 = select i1 %237, ptr %238, ptr %234
  %240 = call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %241 = load ptr, ptr %240, align 8
  %242 = icmp ult ptr %175, %241
  br i1 %242, label %254, label %243

243:                                              ; preds = %229
  %244 = getelementptr inbounds nuw i8, ptr %240, i64 60
  %245 = load i32, ptr %244, align 4
  %246 = zext i32 %245 to i64
  %247 = getelementptr inbounds nuw i8, ptr %241, i64 %246
  %248 = icmp ult ptr %175, %247
  br i1 %248, label %249, label %254

249:                                              ; preds = %243
  %250 = ptrtoint ptr %175 to i64
  %251 = ptrtoint ptr %241 to i64
  %252 = sub i64 %250, %251
  %253 = trunc i64 %252 to i32
  br label %254

254:                                              ; preds = %249, %243, %229
  %255 = phi i32 [ %253, %249 ], [ 0, %243 ], [ 0, %229 ]
  %256 = sext i32 %227 to i64
  %257 = sub nsw i64 1024, %256
  %258 = getelementptr inbounds i8, ptr %4, i64 %256
  %259 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %258, i64 noundef %257, ptr noundef nonnull @"??_C@_0BB@GOELHNLD@?0?$CFu?00x?$CFX?0?$CFs?0?$CF?43f?$AA@", i32 noundef %230, i32 noundef %255, ptr noundef %239, double noundef %232) #30
  br label %265

260:                                              ; preds = %165
  %261 = sext i32 %227 to i64
  %262 = sub nsw i64 1024, %261
  %263 = getelementptr inbounds i8, ptr %4, i64 %261
  %264 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %263, i64 noundef %262, ptr noundef nonnull @"??_C@_04NPGOAOEL@?0?0?0?0?$AA@") #30
  br label %265

265:                                              ; preds = %260, %254
  %266 = phi i32 [ %259, %254 ], [ %264, %260 ]
  %267 = add nsw i32 %266, %227
  %268 = icmp eq ptr %183, null
  br i1 %268, label %300, label %269

269:                                              ; preds = %265
  %270 = and i32 %187, 255
  %271 = uitofp i32 %189 to double
  %272 = fdiv double %271, 1.000000e+03
  %273 = icmp eq i32 %270, 16
  %274 = call fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %185, i1 noundef zeroext %273)
  %275 = getelementptr inbounds nuw i8, ptr %274, i64 24
  %276 = load i64, ptr %275, align 8
  %277 = icmp ugt i64 %276, 15
  %278 = load ptr, ptr %274, align 8
  %279 = select i1 %277, ptr %278, ptr %274
  %280 = call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %281 = load ptr, ptr %280, align 8
  %282 = icmp ult ptr %183, %281
  br i1 %282, label %294, label %283

283:                                              ; preds = %269
  %284 = getelementptr inbounds nuw i8, ptr %280, i64 60
  %285 = load i32, ptr %284, align 4
  %286 = zext i32 %285 to i64
  %287 = getelementptr inbounds nuw i8, ptr %281, i64 %286
  %288 = icmp ult ptr %183, %287
  br i1 %288, label %289, label %294

289:                                              ; preds = %283
  %290 = ptrtoint ptr %183 to i64
  %291 = ptrtoint ptr %281 to i64
  %292 = sub i64 %290, %291
  %293 = trunc i64 %292 to i32
  br label %294

294:                                              ; preds = %289, %283, %269
  %295 = phi i32 [ %293, %289 ], [ 0, %283 ], [ 0, %269 ]
  %296 = sext i32 %267 to i64
  %297 = sub nsw i64 1024, %296
  %298 = getelementptr inbounds i8, ptr %4, i64 %296
  %299 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %298, i64 noundef %297, ptr noundef nonnull @"??_C@_0BB@GOELHNLD@?0?$CFu?00x?$CFX?0?$CFs?0?$CF?43f?$AA@", i32 noundef %270, i32 noundef %295, ptr noundef %279, double noundef %272) #30
  br label %305

300:                                              ; preds = %265
  %301 = sext i32 %267 to i64
  %302 = sub nsw i64 1024, %301
  %303 = getelementptr inbounds i8, ptr %4, i64 %301
  %304 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %303, i64 noundef %302, ptr noundef nonnull @"??_C@_04NPGOAOEL@?0?0?0?0?$AA@") #30
  br label %305

305:                                              ; preds = %300, %294
  %306 = phi i32 [ %299, %294 ], [ %304, %300 ]
  %307 = add nsw i32 %306, %267
  %308 = icmp eq ptr %191, null
  br i1 %308, label %340, label %309

309:                                              ; preds = %305
  %310 = and i32 %195, 255
  %311 = uitofp i32 %197 to double
  %312 = fdiv double %311, 1.000000e+03
  %313 = icmp eq i32 %310, 16
  %314 = call fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %193, i1 noundef zeroext %313)
  %315 = getelementptr inbounds nuw i8, ptr %314, i64 24
  %316 = load i64, ptr %315, align 8
  %317 = icmp ugt i64 %316, 15
  %318 = load ptr, ptr %314, align 8
  %319 = select i1 %317, ptr %318, ptr %314
  %320 = call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %321 = load ptr, ptr %320, align 8
  %322 = icmp ult ptr %191, %321
  br i1 %322, label %334, label %323

323:                                              ; preds = %309
  %324 = getelementptr inbounds nuw i8, ptr %320, i64 60
  %325 = load i32, ptr %324, align 4
  %326 = zext i32 %325 to i64
  %327 = getelementptr inbounds nuw i8, ptr %321, i64 %326
  %328 = icmp ult ptr %191, %327
  br i1 %328, label %329, label %334

329:                                              ; preds = %323
  %330 = ptrtoint ptr %191 to i64
  %331 = ptrtoint ptr %321 to i64
  %332 = sub i64 %330, %331
  %333 = trunc i64 %332 to i32
  br label %334

334:                                              ; preds = %329, %323, %309
  %335 = phi i32 [ %333, %329 ], [ 0, %323 ], [ 0, %309 ]
  %336 = sext i32 %307 to i64
  %337 = sub nsw i64 1024, %336
  %338 = getelementptr inbounds i8, ptr %4, i64 %336
  %339 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %338, i64 noundef %337, ptr noundef nonnull @"??_C@_0BB@GOELHNLD@?0?$CFu?00x?$CFX?0?$CFs?0?$CF?43f?$AA@", i32 noundef %310, i32 noundef %335, ptr noundef %319, double noundef %312) #30
  br label %345

340:                                              ; preds = %305
  %341 = sext i32 %307 to i64
  %342 = sub nsw i64 1024, %341
  %343 = getelementptr inbounds i8, ptr %4, i64 %341
  %344 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %343, i64 noundef %342, ptr noundef nonnull @"??_C@_04NPGOAOEL@?0?0?0?0?$AA@") #30
  br label %345

345:                                              ; preds = %340, %334
  %346 = phi i32 [ %339, %334 ], [ %344, %340 ]
  %347 = add nsw i32 %346, %307
  %348 = uitofp i32 %199 to double
  %349 = fdiv double %348, 1.000000e+03
  %350 = sext i32 %347 to i64
  %351 = sub nsw i64 1024, %350
  %352 = getelementptr inbounds i8, ptr %4, i64 %350
  %353 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %352, i64 noundef %351, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %349) #30
  %354 = add nsw i32 %353, %347
  %355 = uitofp i32 %201 to double
  %356 = fdiv double %355, 1.000000e+03
  %357 = sext i32 %354 to i64
  %358 = sub nsw i64 1024, %357
  %359 = getelementptr inbounds i8, ptr %4, i64 %357
  %360 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %359, i64 noundef %358, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %356) #30
  %361 = add nsw i32 %360, %354
  %362 = uitofp i32 %203 to double
  %363 = fdiv double %362, 1.000000e+03
  %364 = sext i32 %361 to i64
  %365 = sub nsw i64 1024, %364
  %366 = getelementptr inbounds i8, ptr %4, i64 %364
  %367 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %366, i64 noundef %365, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %363) #30
  %368 = add nsw i32 %367, %361
  %369 = uitofp i32 %205 to double
  %370 = fdiv double %369, 1.000000e+03
  %371 = sext i32 %368 to i64
  %372 = sub nsw i64 1024, %371
  %373 = getelementptr inbounds i8, ptr %4, i64 %371
  %374 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %373, i64 noundef %372, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %370) #30
  %375 = add nsw i32 %374, %368
  %376 = uitofp i32 %207 to double
  %377 = fdiv double %376, 1.000000e+03
  %378 = sext i32 %375 to i64
  %379 = sub nsw i64 1024, %378
  %380 = getelementptr inbounds i8, ptr %4, i64 %378
  %381 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %380, i64 noundef %379, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %377) #30
  %382 = add nsw i32 %381, %375
  %383 = uitofp i32 %209 to double
  %384 = fdiv double %383, 1.000000e+03
  %385 = sext i32 %382 to i64
  %386 = sub nsw i64 1024, %385
  %387 = getelementptr inbounds i8, ptr %4, i64 %385
  %388 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %387, i64 noundef %386, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %384) #30
  %389 = add nsw i32 %388, %382
  %390 = uitofp i32 %211 to double
  %391 = fdiv double %390, 1.000000e+03
  %392 = sext i32 %389 to i64
  %393 = sub nsw i64 1024, %392
  %394 = getelementptr inbounds i8, ptr %4, i64 %392
  %395 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %394, i64 noundef %393, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %391) #30
  %396 = add nsw i32 %395, %389
  %397 = uitofp i32 %213 to double
  %398 = fdiv double %397, 1.000000e+03
  %399 = sext i32 %396 to i64
  %400 = sub nsw i64 1024, %399
  %401 = getelementptr inbounds i8, ptr %4, i64 %399
  %402 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %401, i64 noundef %400, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %398) #30
  %403 = add nsw i32 %402, %396
  %404 = uitofp i32 %215 to double
  %405 = fdiv double %404, 1.000000e+03
  %406 = sext i32 %403 to i64
  %407 = sub nsw i64 1024, %406
  %408 = getelementptr inbounds i8, ptr %4, i64 %406
  %409 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %408, i64 noundef %407, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %405) #30
  %410 = add nsw i32 %409, %403
  %411 = sext i32 %410 to i64
  %412 = sub nsw i64 1024, %411
  %413 = getelementptr inbounds i8, ptr %4, i64 %411
  %414 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %413, i64 noundef %412, ptr noundef nonnull @"??_C@_01EEMJAFIK@?6?$AA@") #30
  %415 = add nsw i32 %414, %410
  %416 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %417 = icmp eq ptr %416, null
  %418 = icmp slt i32 %415, 1
  %419 = or i1 %418, %417
  br i1 %419, label %432, label %420

420:                                              ; preds = %345
  %421 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %422 = add nuw nsw i32 %421, %415
  %423 = icmp sgt i32 %422, 67108864
  br i1 %423, label %424, label %427

424:                                              ; preds = %420
  %425 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %425, label %432, label %426

426:                                              ; preds = %424
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
  br label %432

427:                                              ; preds = %420
  %428 = zext nneg i32 %415 to i64
  %429 = call i64 @fwrite(ptr noundef nonnull readonly %4, i64 noundef 1, i64 noundef %428, ptr noundef nonnull %416)
  %430 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %431 = add nuw nsw i32 %430, %415
  store i32 %431, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %432

432:                                              ; preds = %345, %424, %426, %427
  call void @llvm.lifetime.end.p0(i64 1024, ptr nonnull %4) #30
  %433 = load volatile i64, ptr @"?g_thead@?A0xB9C01504@opf@@3U?$atomic@_K@std@@A", align 8
  fence syncscope("singlethread") seq_cst
  %434 = icmp eq i64 %220, %433
  br i1 %434, label %164, label %165, !llvm.loop !36

435:                                              ; preds = %164
  %436 = zext nneg i32 %12 to i64
  %437 = getelementptr inbounds nuw [2 x %"struct.opf::(anonymous namespace)::Window"], ptr @"?g_win@?A0xB9C01504@opf@@3PAUWindow@?A0xB9C01504@1@A", i64 0, i64 %436
  call void @llvm.lifetime.start.p0(i64 1024, ptr nonnull %1) #30
  %438 = getelementptr inbounds nuw i8, ptr %437, i64 229424
  %439 = load i64, ptr %438, align 8
  %440 = uitofp i64 %439 to double
  %441 = fdiv double %440, 1.000000e+03
  %442 = getelementptr inbounds nuw i8, ptr %437, i64 229504
  %443 = load i64, ptr %442, align 8
  %444 = uitofp i64 %443 to double
  %445 = fdiv double %444, 1.000000e+03
  %446 = getelementptr inbounds nuw i8, ptr %437, i64 229496
  %447 = load i64, ptr %446, align 8
  %448 = uitofp i64 %447 to double
  %449 = fdiv double %448, 1.000000e+03
  %450 = getelementptr inbounds nuw i8, ptr %437, i64 229512
  %451 = load i64, ptr %450, align 8
  %452 = uitofp i64 %451 to double
  %453 = fdiv double %452, 1.000000e+03
  %454 = getelementptr inbounds nuw i8, ptr %437, i64 229408
  %455 = load i64, ptr %454, align 8
  %456 = getelementptr inbounds nuw i8, ptr %437, i64 229400
  %457 = load i64, ptr %456, align 8
  %458 = getelementptr inbounds nuw i8, ptr %437, i64 229416
  %459 = load i64, ptr %458, align 8
  %460 = sub i64 %439, %459
  %461 = uitofp i64 %460 to double
  %462 = fdiv double %461, 1.000000e+06
  %463 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %1, i64 noundef 1024, ptr noundef nonnull @"??_C@_0CF@KMOIDJIM@W?0?$CF?43f?0?$CF?43f?0?$CFllu?0?$CFllu?0?$CF?43f?0?$CF?43f?0@", double noundef %441, double noundef %462, i64 noundef %457, i64 noundef %455, double noundef %453, double noundef %449, double noundef %445) #30
  %464 = getelementptr inbounds nuw i8, ptr %437, i64 229432
  %465 = load i64, ptr %464, align 8
  %466 = uitofp i64 %465 to double
  %467 = fdiv double %466, 1.000000e+03
  %468 = sext i32 %463 to i64
  %469 = sub nsw i64 1024, %468
  %470 = getelementptr inbounds i8, ptr %1, i64 %468
  %471 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %470, i64 noundef %469, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %467) #30
  %472 = add nsw i32 %471, %463
  %473 = getelementptr inbounds nuw i8, ptr %437, i64 229440
  %474 = load i64, ptr %473, align 8
  %475 = uitofp i64 %474 to double
  %476 = fdiv double %475, 1.000000e+03
  %477 = sext i32 %472 to i64
  %478 = sub nsw i64 1024, %477
  %479 = getelementptr inbounds i8, ptr %1, i64 %477
  %480 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %479, i64 noundef %478, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %476) #30
  %481 = add nsw i32 %480, %472
  %482 = getelementptr inbounds nuw i8, ptr %437, i64 229448
  %483 = load i64, ptr %482, align 8
  %484 = uitofp i64 %483 to double
  %485 = fdiv double %484, 1.000000e+03
  %486 = sext i32 %481 to i64
  %487 = sub nsw i64 1024, %486
  %488 = getelementptr inbounds i8, ptr %1, i64 %486
  %489 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %488, i64 noundef %487, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %485) #30
  %490 = add nsw i32 %489, %481
  %491 = getelementptr inbounds nuw i8, ptr %437, i64 229456
  %492 = load i64, ptr %491, align 8
  %493 = uitofp i64 %492 to double
  %494 = fdiv double %493, 1.000000e+03
  %495 = sext i32 %490 to i64
  %496 = sub nsw i64 1024, %495
  %497 = getelementptr inbounds i8, ptr %1, i64 %495
  %498 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %497, i64 noundef %496, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %494) #30
  %499 = add nsw i32 %498, %490
  %500 = getelementptr inbounds nuw i8, ptr %437, i64 229464
  %501 = load i64, ptr %500, align 8
  %502 = uitofp i64 %501 to double
  %503 = fdiv double %502, 1.000000e+03
  %504 = sext i32 %499 to i64
  %505 = sub nsw i64 1024, %504
  %506 = getelementptr inbounds i8, ptr %1, i64 %504
  %507 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %506, i64 noundef %505, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %503) #30
  %508 = add nsw i32 %507, %499
  %509 = getelementptr inbounds nuw i8, ptr %437, i64 229472
  %510 = load i64, ptr %509, align 8
  %511 = uitofp i64 %510 to double
  %512 = fdiv double %511, 1.000000e+03
  %513 = sext i32 %508 to i64
  %514 = sub nsw i64 1024, %513
  %515 = getelementptr inbounds i8, ptr %1, i64 %513
  %516 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %515, i64 noundef %514, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %512) #30
  %517 = add nsw i32 %516, %508
  %518 = getelementptr inbounds nuw i8, ptr %437, i64 229480
  %519 = load i64, ptr %518, align 8
  %520 = uitofp i64 %519 to double
  %521 = fdiv double %520, 1.000000e+03
  %522 = sext i32 %517 to i64
  %523 = sub nsw i64 1024, %522
  %524 = getelementptr inbounds i8, ptr %1, i64 %522
  %525 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %524, i64 noundef %523, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %521) #30
  %526 = add nsw i32 %525, %517
  %527 = getelementptr inbounds nuw i8, ptr %437, i64 229488
  %528 = load i64, ptr %527, align 8
  %529 = uitofp i64 %528 to double
  %530 = fdiv double %529, 1.000000e+03
  %531 = sext i32 %526 to i64
  %532 = sub nsw i64 1024, %531
  %533 = getelementptr inbounds i8, ptr %1, i64 %531
  %534 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %533, i64 noundef %532, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %530) #30
  %535 = add nsw i32 %534, %526
  %536 = getelementptr inbounds nuw i8, ptr %437, i64 229376
  %537 = load i32, ptr %536, align 8
  %538 = getelementptr inbounds nuw i8, ptr %437, i64 229392
  %539 = load i64, ptr %538, align 8
  %540 = uitofp i64 %539 to double
  %541 = fmul double %540, 1.000000e+03
  %542 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %543 = sitofp i64 %542 to double
  %544 = fdiv double %541, %543
  %545 = getelementptr inbounds nuw i8, ptr %437, i64 229384
  %546 = load i64, ptr %545, align 8
  %547 = getelementptr inbounds nuw i8, ptr %437, i64 229600
  %548 = load i64, ptr %547, align 8
  %549 = uitofp i64 %548 to double
  %550 = fmul double %549, 1.000000e+03
  %551 = fdiv double %550, %543
  %552 = getelementptr inbounds nuw i8, ptr %437, i64 229592
  %553 = load i64, ptr %552, align 8
  %554 = sext i32 %535 to i64
  %555 = sub nsw i64 1024, %554
  %556 = getelementptr inbounds i8, ptr %1, i64 %554
  %557 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %556, i64 noundef %555, ptr noundef nonnull @"??_C@_0BI@EJEDBKLJ@?0?$CFllu?0?$CF?43f?0?$CFllu?0?$CF?43f?0?$CFu?$AA@", i64 noundef %553, double noundef %551, i64 noundef %546, double noundef %544, i32 noundef %537) #30
  %558 = add nsw i32 %557, %535
  %559 = getelementptr inbounds nuw i8, ptr %437, i64 229520
  %560 = load i64, ptr %559, align 8
  %561 = uitofp i64 %560 to double
  %562 = fmul double %561, 1.000000e+03
  %563 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %564 = sitofp i64 %563 to double
  %565 = fdiv double %562, %564
  %566 = sext i32 %558 to i64
  %567 = sub nsw i64 1024, %566
  %568 = getelementptr inbounds i8, ptr %1, i64 %566
  %569 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %568, i64 noundef %567, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %565) #30
  %570 = add nsw i32 %569, %558
  %571 = getelementptr inbounds nuw i8, ptr %437, i64 229528
  %572 = load i64, ptr %571, align 8
  %573 = uitofp i64 %572 to double
  %574 = fmul double %573, 1.000000e+03
  %575 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %576 = sitofp i64 %575 to double
  %577 = fdiv double %574, %576
  %578 = sext i32 %570 to i64
  %579 = sub nsw i64 1024, %578
  %580 = getelementptr inbounds i8, ptr %1, i64 %578
  %581 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %580, i64 noundef %579, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %577) #30
  %582 = add nsw i32 %581, %570
  %583 = getelementptr inbounds nuw i8, ptr %437, i64 229536
  %584 = load i64, ptr %583, align 8
  %585 = uitofp i64 %584 to double
  %586 = fmul double %585, 1.000000e+03
  %587 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %588 = sitofp i64 %587 to double
  %589 = fdiv double %586, %588
  %590 = sext i32 %582 to i64
  %591 = sub nsw i64 1024, %590
  %592 = getelementptr inbounds i8, ptr %1, i64 %590
  %593 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %592, i64 noundef %591, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %589) #30
  %594 = add nsw i32 %593, %582
  %595 = getelementptr inbounds nuw i8, ptr %437, i64 229544
  %596 = load i64, ptr %595, align 8
  %597 = uitofp i64 %596 to double
  %598 = fmul double %597, 1.000000e+03
  %599 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %600 = sitofp i64 %599 to double
  %601 = fdiv double %598, %600
  %602 = sext i32 %594 to i64
  %603 = sub nsw i64 1024, %602
  %604 = getelementptr inbounds i8, ptr %1, i64 %602
  %605 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %604, i64 noundef %603, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %601) #30
  %606 = add nsw i32 %605, %594
  %607 = getelementptr inbounds nuw i8, ptr %437, i64 229552
  %608 = load i64, ptr %607, align 8
  %609 = uitofp i64 %608 to double
  %610 = fmul double %609, 1.000000e+03
  %611 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %612 = sitofp i64 %611 to double
  %613 = fdiv double %610, %612
  %614 = sext i32 %606 to i64
  %615 = sub nsw i64 1024, %614
  %616 = getelementptr inbounds i8, ptr %1, i64 %614
  %617 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %616, i64 noundef %615, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %613) #30
  %618 = add nsw i32 %617, %606
  %619 = getelementptr inbounds nuw i8, ptr %437, i64 229560
  %620 = load i64, ptr %619, align 8
  %621 = uitofp i64 %620 to double
  %622 = fmul double %621, 1.000000e+03
  %623 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %624 = sitofp i64 %623 to double
  %625 = fdiv double %622, %624
  %626 = sext i32 %618 to i64
  %627 = sub nsw i64 1024, %626
  %628 = getelementptr inbounds i8, ptr %1, i64 %626
  %629 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %628, i64 noundef %627, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %625) #30
  %630 = add nsw i32 %629, %618
  %631 = getelementptr inbounds nuw i8, ptr %437, i64 229568
  %632 = load i64, ptr %631, align 8
  %633 = uitofp i64 %632 to double
  %634 = fmul double %633, 1.000000e+03
  %635 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %636 = sitofp i64 %635 to double
  %637 = fdiv double %634, %636
  %638 = sext i32 %630 to i64
  %639 = sub nsw i64 1024, %638
  %640 = getelementptr inbounds i8, ptr %1, i64 %638
  %641 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %640, i64 noundef %639, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %637) #30
  %642 = add nsw i32 %641, %630
  %643 = getelementptr inbounds nuw i8, ptr %437, i64 229576
  %644 = load i64, ptr %643, align 8
  %645 = uitofp i64 %644 to double
  %646 = fmul double %645, 1.000000e+03
  %647 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %648 = sitofp i64 %647 to double
  %649 = fdiv double %646, %648
  %650 = sext i32 %642 to i64
  %651 = sub nsw i64 1024, %650
  %652 = getelementptr inbounds i8, ptr %1, i64 %650
  %653 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %652, i64 noundef %651, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %649) #30
  %654 = add nsw i32 %653, %642
  %655 = getelementptr inbounds nuw i8, ptr %437, i64 229584
  %656 = load i64, ptr %655, align 8
  %657 = uitofp i64 %656 to double
  %658 = fmul double %657, 1.000000e+03
  %659 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %660 = sitofp i64 %659 to double
  %661 = fdiv double %658, %660
  %662 = sext i32 %654 to i64
  %663 = sub nsw i64 1024, %662
  %664 = getelementptr inbounds i8, ptr %1, i64 %662
  %665 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %664, i64 noundef %663, ptr noundef nonnull @"??_C@_05GCBFHEIA@?0?$CF?43f?$AA@", double noundef %661) #30
  %666 = add nsw i32 %665, %654
  %667 = sext i32 %666 to i64
  %668 = sub nsw i64 1024, %667
  %669 = getelementptr inbounds i8, ptr %1, i64 %667
  %670 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %669, i64 noundef %668, ptr noundef nonnull @"??_C@_01EEMJAFIK@?6?$AA@") #30
  %671 = add nsw i32 %670, %666
  %672 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %673 = icmp eq ptr %672, null
  %674 = icmp slt i32 %671, 1
  %675 = or i1 %674, %673
  br i1 %675, label %688, label %676

676:                                              ; preds = %435
  %677 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %678 = add nuw nsw i32 %677, %671
  %679 = icmp sgt i32 %678, 67108864
  br i1 %679, label %680, label %683

680:                                              ; preds = %676
  %681 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %681, label %688, label %682

682:                                              ; preds = %680
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
  br label %688

683:                                              ; preds = %676
  %684 = zext nneg i32 %671 to i64
  %685 = call i64 @fwrite(ptr noundef nonnull readonly %1, i64 noundef 1, i64 noundef %684, ptr noundef nonnull %672)
  %686 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %687 = add nuw nsw i32 %686, %671
  store i32 %687, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %688

688:                                              ; preds = %683, %682, %680, %435
  %689 = getelementptr inbounds nuw i8, ptr %437, i64 229608
  %690 = getelementptr inbounds nuw i8, ptr %437, i64 229848
  %691 = load i64, ptr %690, align 8
  %692 = icmp eq i64 %691, 0
  br i1 %692, label %826, label %775

693:                                              ; preds = %811
  %694 = load i64, ptr %690, align 8
  %695 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %1, i64 noundef 1024, ptr noundef nonnull @"??_C@_0M@LECLBMHC@Q?0?$CF?43f?0?$CFllu?$AA@", double noundef %441, i64 noundef %694) #30
  %696 = getelementptr inbounds nuw i8, ptr %437, i64 229856
  %697 = load i64, ptr %696, align 8
  %698 = sext i32 %695 to i64
  %699 = sub nsw i64 1024, %698
  %700 = getelementptr inbounds i8, ptr %1, i64 %698
  %701 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %700, i64 noundef %699, ptr noundef nonnull @"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@", i64 noundef %697) #30
  %702 = add nsw i32 %701, %695
  %703 = getelementptr inbounds nuw i8, ptr %437, i64 229864
  %704 = load i64, ptr %703, align 8
  %705 = sext i32 %702 to i64
  %706 = sub nsw i64 1024, %705
  %707 = getelementptr inbounds i8, ptr %1, i64 %705
  %708 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %707, i64 noundef %706, ptr noundef nonnull @"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@", i64 noundef %704) #30
  %709 = add nsw i32 %708, %702
  %710 = getelementptr inbounds nuw i8, ptr %437, i64 229872
  %711 = load i64, ptr %710, align 8
  %712 = sext i32 %709 to i64
  %713 = sub nsw i64 1024, %712
  %714 = getelementptr inbounds i8, ptr %1, i64 %712
  %715 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %714, i64 noundef %713, ptr noundef nonnull @"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@", i64 noundef %711) #30
  %716 = add nsw i32 %715, %709
  %717 = getelementptr inbounds nuw i8, ptr %437, i64 229880
  %718 = load i64, ptr %717, align 8
  %719 = sext i32 %716 to i64
  %720 = sub nsw i64 1024, %719
  %721 = getelementptr inbounds i8, ptr %1, i64 %719
  %722 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %721, i64 noundef %720, ptr noundef nonnull @"??_C@_05FFAHMMCJ@?0?$CFllu?$AA@", i64 noundef %718) #30
  %723 = add nsw i32 %722, %716
  %724 = getelementptr inbounds nuw i8, ptr %437, i64 229896
  %725 = load i64, ptr %724, align 8
  %726 = getelementptr inbounds nuw i8, ptr %437, i64 229888
  %727 = load i64, ptr %726, align 8
  %728 = sext i32 %723 to i64
  %729 = sub nsw i64 1024, %728
  %730 = getelementptr inbounds i8, ptr %1, i64 %728
  %731 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %730, i64 noundef %729, ptr noundef nonnull @"??_C@_0L@CJPDDBCK@?0?$CFllu?0?$CFllu?$AA@", i64 noundef %727, i64 noundef %725) #30
  %732 = add nsw i32 %731, %723
  %733 = getelementptr inbounds nuw i8, ptr %437, i64 229952
  %734 = getelementptr inbounds nuw i8, ptr %437, i64 229928
  %735 = getelementptr inbounds nuw i8, ptr %437, i64 229904
  %736 = load i64, ptr %733, align 8
  %737 = load i64, ptr %734, align 8
  %738 = load i64, ptr %735, align 8
  %739 = sext i32 %732 to i64
  %740 = sub nsw i64 1024, %739
  %741 = getelementptr inbounds i8, ptr %1, i64 %739
  %742 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %741, i64 noundef %740, ptr noundef nonnull @"??_C@_0BA@CLBIGIHG@?0?$CFllu?0?$CFllu?0?$CFllu?$AA@", i64 noundef %738, i64 noundef %737, i64 noundef %736) #30
  %743 = add nsw i32 %742, %732
  %744 = getelementptr inbounds nuw i8, ptr %437, i64 229960
  %745 = load i64, ptr %744, align 8
  %746 = getelementptr inbounds nuw i8, ptr %437, i64 229936
  %747 = load i64, ptr %746, align 8
  %748 = getelementptr inbounds nuw i8, ptr %437, i64 229912
  %749 = load i64, ptr %748, align 8
  %750 = sext i32 %743 to i64
  %751 = sub nsw i64 1024, %750
  %752 = getelementptr inbounds i8, ptr %1, i64 %750
  %753 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %752, i64 noundef %751, ptr noundef nonnull @"??_C@_0BA@CLBIGIHG@?0?$CFllu?0?$CFllu?0?$CFllu?$AA@", i64 noundef %749, i64 noundef %747, i64 noundef %745) #30
  %754 = add nsw i32 %753, %743
  %755 = getelementptr inbounds nuw i8, ptr %437, i64 229968
  %756 = load i64, ptr %755, align 8
  %757 = getelementptr inbounds nuw i8, ptr %437, i64 229944
  %758 = load i64, ptr %757, align 8
  %759 = getelementptr inbounds nuw i8, ptr %437, i64 229920
  %760 = load i64, ptr %759, align 8
  %761 = sext i32 %754 to i64
  %762 = sub nsw i64 1024, %761
  %763 = getelementptr inbounds i8, ptr %1, i64 %761
  %764 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %763, i64 noundef %762, ptr noundef nonnull @"??_C@_0BA@CLBIGIHG@?0?$CFllu?0?$CFllu?0?$CFllu?$AA@", i64 noundef %760, i64 noundef %758, i64 noundef %756) #30
  %765 = add nsw i32 %764, %754
  %766 = sext i32 %765 to i64
  %767 = sub nsw i64 1024, %766
  %768 = getelementptr inbounds i8, ptr %1, i64 %766
  %769 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull %768, i64 noundef %767, ptr noundef nonnull @"??_C@_01EEMJAFIK@?6?$AA@") #30
  %770 = add nsw i32 %769, %765
  %771 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %772 = icmp eq ptr %771, null
  %773 = icmp slt i32 %770, 1
  %774 = or i1 %773, %772
  br i1 %774, label %826, label %814

775:                                              ; preds = %688, %811
  %776 = phi i64 [ %812, %811 ], [ 0, %688 ]
  %777 = getelementptr inbounds nuw [10 x %"struct.opf::(anonymous namespace)::PercStat"], ptr %689, i64 0, i64 %776
  %778 = getelementptr inbounds nuw i8, ptr %777, i64 16
  %779 = load i64, ptr %778, align 8
  %780 = uitofp i64 %779 to double
  %781 = fmul double %780, 1.000000e+03
  %782 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %783 = sitofp i64 %782 to double
  %784 = fdiv double %781, %783
  %785 = getelementptr inbounds nuw i8, ptr %777, i64 8
  %786 = load i64, ptr %785, align 8
  %787 = uitofp i64 %786 to double
  %788 = fmul double %787, 1.000000e+03
  %789 = fdiv double %788, %783
  %790 = load i64, ptr %777, align 8
  %791 = getelementptr inbounds nuw [10 x ptr], ptr @"?kPercNames@?A0xB9C01504@opf@@3QBQEBDB", i64 0, i64 %776
  %792 = load ptr, ptr %791, align 8
  %793 = load i64, ptr %690, align 8
  %794 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %1, i64 noundef 1024, ptr noundef nonnull @"??_C@_0BP@ECEGIOMC@P?0?$CF?43f?0?$CFllu?0?$CFs?0?$CFllu?0?$CF?46f?0?$CF?46f?6?$AA@", double noundef %441, i64 noundef %793, ptr noundef %792, i64 noundef %790, double noundef %789, double noundef %784) #30
  %795 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %796 = icmp eq ptr %795, null
  %797 = icmp slt i32 %794, 1
  %798 = or i1 %797, %796
  br i1 %798, label %811, label %799

799:                                              ; preds = %775
  %800 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %801 = add nuw nsw i32 %800, %794
  %802 = icmp sgt i32 %801, 67108864
  br i1 %802, label %803, label %806

803:                                              ; preds = %799
  %804 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %804, label %811, label %805

805:                                              ; preds = %803
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
  br label %811

806:                                              ; preds = %799
  %807 = zext nneg i32 %794 to i64
  %808 = call i64 @fwrite(ptr noundef nonnull readonly %1, i64 noundef 1, i64 noundef %807, ptr noundef nonnull %795)
  %809 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %810 = add nuw nsw i32 %809, %794
  store i32 %810, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %811

811:                                              ; preds = %806, %805, %803, %775
  %812 = add nuw nsw i64 %776, 1
  %813 = icmp eq i64 %812, 10
  br i1 %813, label %693, label %775, !llvm.loop !37

814:                                              ; preds = %693
  %815 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %816 = add nuw nsw i32 %815, %770
  %817 = icmp sgt i32 %816, 67108864
  br i1 %817, label %818, label %821

818:                                              ; preds = %814
  %819 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %819, label %826, label %820

820:                                              ; preds = %818
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
  br label %826

821:                                              ; preds = %814
  %822 = zext nneg i32 %770 to i64
  %823 = call i64 @fwrite(ptr noundef nonnull readonly %1, i64 noundef 1, i64 noundef %822, ptr noundef nonnull %771)
  %824 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %825 = add nuw nsw i32 %824, %770
  store i32 %825, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %826

826:                                              ; preds = %821, %820, %818, %693, %688
  %827 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %828 = getelementptr inbounds nuw i8, ptr %2, i64 24
  %829 = getelementptr inbounds nuw i8, ptr %3, i64 16
  %830 = getelementptr inbounds nuw i8, ptr %3, i64 24
  br label %831

831:                                              ; preds = %1053, %826
  %832 = phi i64 [ 0, %826 ], [ %1054, %1053 ]
  %833 = icmp samesign ult i64 %832, 4096
  br i1 %833, label %834, label %1057

834:                                              ; preds = %831
  %835 = getelementptr inbounds nuw [4096 x %"struct.opf::(anonymous namespace)::Entry"], ptr %437, i64 0, i64 %832
  %836 = load ptr, ptr %835, align 8
  %837 = icmp eq ptr %836, null
  br i1 %837, label %1053, label %838

838:                                              ; preds = %834
  %839 = getelementptr inbounds nuw i8, ptr %835, i64 20
  %840 = load i32, ptr %839, align 4
  %841 = icmp eq i32 %840, 0
  br i1 %841, label %1053, label %842

842:                                              ; preds = %838
  %843 = getelementptr inbounds nuw i8, ptr %835, i64 16
  %844 = load i32, ptr %843, align 8
  %845 = and i32 %844, 255
  %846 = lshr i32 %844, 8
  %847 = and i32 %846, 255
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #30
  %848 = icmp eq i32 %845, 16
  %849 = getelementptr inbounds nuw i8, ptr %835, i64 8
  %850 = load ptr, ptr %849, align 8
  %851 = call fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %850, i1 noundef zeroext %848)
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %852 = getelementptr inbounds nuw i8, ptr %851, i64 16
  %853 = load i64, ptr %852, align 8
  %854 = getelementptr inbounds nuw i8, ptr %851, i64 24
  %855 = load i64, ptr %854, align 8
  %856 = icmp ugt i64 %855, 15
  %857 = load ptr, ptr %851, align 8
  %858 = select i1 %856, ptr %857, ptr %851
  %859 = icmp slt i64 %853, 0
  br i1 %859, label %860, label %861

860:                                              ; preds = %842
  call void @"?_Xlen_string@std@@YAXXZ"() #32
  unreachable

861:                                              ; preds = %842
  %862 = icmp samesign ult i64 %853, 16
  br i1 %862, label %863, label %864

863:                                              ; preds = %861
  store i64 %853, ptr %827, align 8
  store i64 15, ptr %828, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %2, ptr noundef nonnull align 1 dereferenceable(16) %858, i64 16, i1 false)
  br label %882

864:                                              ; preds = %861
  %865 = or i64 %853, 15
  %866 = call i64 @llvm.umax.i64(i64 %865, i64 22)
  %867 = icmp samesign ugt i64 %865, 4094
  br i1 %867, label %868, label %876

868:                                              ; preds = %864
  %869 = add nuw i64 %866, 40
  %870 = call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %869) #33
  %871 = ptrtoint ptr %870 to i64
  %872 = add i64 %871, 39
  %873 = and i64 %872, -32
  %874 = inttoptr i64 %873 to ptr
  %875 = getelementptr inbounds i8, ptr %874, i64 -8
  store i64 %871, ptr %875, align 8
  br label %879

876:                                              ; preds = %864
  %877 = add nuw nsw i64 %866, 1
  %878 = call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %877) #33
  br label %879

879:                                              ; preds = %876, %868
  %880 = phi ptr [ %874, %868 ], [ %878, %876 ]
  store ptr %880, ptr %2, align 8
  store i64 %853, ptr %827, align 8
  store i64 %866, ptr %828, align 8
  %881 = add nuw i64 %853, 1
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(1) %880, ptr noundef nonnull align 1 dereferenceable(1) %858, i64 %881, i1 false)
  br label %882

882:                                              ; preds = %879, %863
  invoke void @llvm.seh.scope.begin()
          to label %883 unwind label %1055

883:                                              ; preds = %882
  %884 = icmp eq i32 %845, 18
  br i1 %884, label %885, label %975

885:                                              ; preds = %883
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #30
  %886 = load ptr, ptr %835, align 8
  %887 = invoke fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %886, i1 noundef zeroext false)
          to label %888 unwind label %1055

888:                                              ; preds = %885
  call void @llvm.experimental.noalias.scope.decl(metadata !38)
  %889 = getelementptr inbounds nuw i8, ptr %887, i64 16
  %890 = load i64, ptr %889, align 8, !noalias !38
  %891 = and i64 %890, -2
  %892 = icmp eq i64 %891, 9223372036854775806
  br i1 %892, label %893, label %895

893:                                              ; preds = %888
  invoke void @"?_Xlen_string@std@@YAXXZ"() #32
          to label %894 unwind label %1055

894:                                              ; preds = %893
  unreachable

895:                                              ; preds = %888
  %896 = getelementptr inbounds nuw i8, ptr %887, i64 24
  %897 = load i64, ptr %896, align 8, !noalias !38
  %898 = load ptr, ptr %887, align 8, !noalias !38
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %3, i8 0, i64 16, i1 false), !alias.scope !38
  %899 = add nsw i64 %890, 2
  %900 = icmp ugt i64 %899, 15
  br i1 %900, label %901, label %923

901:                                              ; preds = %895
  %902 = icmp slt i64 %890, -2
  br i1 %902, label %907, label %903

903:                                              ; preds = %901
  %904 = or i64 %899, 15
  %905 = call i64 @llvm.umax.i64(i64 %904, i64 22)
  %906 = icmp samesign ugt i64 %904, 4094
  br i1 %906, label %907, label %917

907:                                              ; preds = %903, %901
  %908 = phi i64 [ %905, %903 ], [ 9223372036854775807, %901 ]
  %909 = add nuw i64 %908, 40
  %910 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %909) #33
          to label %911 unwind label %1055

911:                                              ; preds = %907
  %912 = ptrtoint ptr %910 to i64
  %913 = add i64 %912, 39
  %914 = and i64 %913, -32
  %915 = inttoptr i64 %914 to ptr
  %916 = getelementptr inbounds i8, ptr %915, i64 -8
  store i64 %912, ptr %916, align 8, !noalias !38
  br label %920

917:                                              ; preds = %903
  %918 = add nuw nsw i64 %905, 1
  %919 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %918) #33
          to label %920 unwind label %1055

920:                                              ; preds = %917, %911
  %921 = phi i64 [ %908, %911 ], [ %905, %917 ]
  %922 = phi ptr [ %915, %911 ], [ %919, %917 ]
  store ptr %922, ptr %3, align 8, !alias.scope !38
  br label %923

923:                                              ; preds = %920, %895
  %924 = phi i64 [ %921, %920 ], [ 15, %895 ]
  %925 = phi ptr [ %922, %920 ], [ %3, %895 ]
  %926 = icmp ugt i64 %897, 15
  %927 = select i1 %926, ptr %898, ptr %887
  store i64 %899, ptr %829, align 8, !alias.scope !38
  store i64 %924, ptr %830, align 8, !alias.scope !38
  store i16 14906, ptr %925, align 1
  %928 = getelementptr inbounds nuw i8, ptr %925, i64 2
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 1 %928, ptr align 1 %927, i64 %890, i1 false)
  %929 = getelementptr inbounds nuw i8, ptr %925, i64 %899
  store i8 0, ptr %929, align 1
  invoke void @llvm.seh.scope.begin()
          to label %930 unwind label %972

930:                                              ; preds = %923
  %931 = load i64, ptr %829, align 8
  %932 = load i64, ptr %830, align 8
  %933 = icmp ugt i64 %932, 15
  %934 = load ptr, ptr %3, align 8
  %935 = select i1 %933, ptr %934, ptr %3
  %936 = load i64, ptr %827, align 8
  %937 = load i64, ptr %828, align 8
  %938 = sub i64 %937, %936
  %939 = icmp ugt i64 %931, %938
  br i1 %939, label %947, label %940

940:                                              ; preds = %930
  %941 = add i64 %936, %931
  store i64 %941, ptr %827, align 8
  %942 = icmp ugt i64 %937, 15
  %943 = load ptr, ptr %2, align 8
  %944 = select i1 %942, ptr %943, ptr %2
  %945 = getelementptr inbounds nuw i8, ptr %944, i64 %936
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %945, ptr align 1 %935, i64 %931, i1 false)
  %946 = getelementptr inbounds nuw i8, ptr %944, i64 %941
  store i8 0, ptr %946, align 1
  br label %949

947:                                              ; preds = %930
  %948 = invoke noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAAAEAV34@QEBD_K@Z@PEBD_K@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEBD0@Z@PEBD_K@Z"(ptr noundef nonnull align 8 dereferenceable(32) %2, i64 noundef %931, i8 undef, ptr noundef %935, i64 noundef %931)
          to label %949 unwind label %972

949:                                              ; preds = %947, %940
  invoke void @llvm.seh.scope.end()
          to label %950 unwind label %972

950:                                              ; preds = %949
  tail call void @llvm.seh.scope.begin()
  %951 = load i64, ptr %830, align 8
  %952 = icmp ugt i64 %951, 15
  br i1 %952, label %953, label %971

953:                                              ; preds = %950
  %954 = load ptr, ptr %3, align 8
  %955 = add i64 %951, 1
  %956 = icmp ugt i64 %955, 4095
  br i1 %956, label %957, label %968

957:                                              ; preds = %953
  %958 = getelementptr inbounds i8, ptr %954, i64 -8
  %959 = load i64, ptr %958, align 8
  %960 = ptrtoint ptr %954 to i64
  %961 = add i64 %960, -8
  %962 = sub i64 %961, %959
  %963 = icmp ult i64 %962, 32
  br i1 %963, label %965, label %964

964:                                              ; preds = %957
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

965:                                              ; preds = %957
  %966 = add i64 %951, 40
  %967 = inttoptr i64 %959 to ptr
  br label %968

968:                                              ; preds = %965, %953
  %969 = phi i64 [ %966, %965 ], [ %955, %953 ]
  %970 = phi ptr [ %967, %965 ], [ %954, %953 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %970, i64 noundef %969) #30
  br label %971

971:                                              ; preds = %968, %950
  tail call void @llvm.seh.scope.end()
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #30
  br label %975

972:                                              ; preds = %949, %947, %923
  %973 = cleanuppad within none []
  invoke void @llvm.seh.scope.end() [ "funclet"(token %973) ]
          to label %974 unwind label %1055

974:                                              ; preds = %972
  call void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %3) #30 [ "funclet"(token %973) ]
  cleanupret from %973 unwind label %1055

975:                                              ; preds = %971, %883
  %976 = getelementptr inbounds nuw i8, ptr %835, i64 32
  %977 = load i64, ptr %976, align 8
  %978 = uitofp i64 %977 to double
  %979 = fmul double %978, 1.000000e+03
  %980 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %981 = sitofp i64 %980 to double
  %982 = fdiv double %979, %981
  %983 = getelementptr inbounds nuw i8, ptr %835, i64 24
  %984 = load i64, ptr %983, align 8
  %985 = uitofp i64 %984 to double
  %986 = fmul double %985, 1.000000e+03
  %987 = fdiv double %986, %981
  %988 = load i32, ptr %839, align 4
  %989 = load i64, ptr %828, align 8
  %990 = icmp ugt i64 %989, 15
  %991 = load ptr, ptr %2, align 8
  %992 = select i1 %990, ptr %991, ptr %2
  %993 = load ptr, ptr %835, align 8
  %994 = invoke noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
          to label %995 unwind label %1055

995:                                              ; preds = %975
  %996 = load ptr, ptr %994, align 8
  %997 = icmp ult ptr %993, %996
  br i1 %997, label %1009, label %998

998:                                              ; preds = %995
  %999 = getelementptr inbounds nuw i8, ptr %994, i64 60
  %1000 = load i32, ptr %999, align 4
  %1001 = zext i32 %1000 to i64
  %1002 = getelementptr inbounds nuw i8, ptr %996, i64 %1001
  %1003 = icmp ult ptr %993, %1002
  br i1 %1003, label %1004, label %1009

1004:                                             ; preds = %998
  %1005 = ptrtoint ptr %993 to i64
  %1006 = ptrtoint ptr %996 to i64
  %1007 = sub i64 %1005, %1006
  %1008 = trunc i64 %1007 to i32
  br label %1009

1009:                                             ; preds = %1004, %998, %995
  %1010 = phi i32 [ %1008, %1004 ], [ 0, %998 ], [ 0, %995 ]
  %1011 = icmp eq i32 %847, 255
  %1012 = select i1 %1011, i32 -1, i32 %847
  %1013 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %1, i64 noundef 1024, ptr noundef nonnull @"??_C@_0CD@CCJMPANC@E?0?$CF?43f?0?$CFu?0?$CFd?00x?$CFX?0?$CFs?0?$CFu?0?$CF?44f?0?$CF?44@", double noundef %441, i32 noundef %845, i32 noundef %1012, i32 noundef %1010, ptr noundef %992, i32 noundef %988, double noundef %987, double noundef %982) #30
  %1014 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %1015 = icmp eq ptr %1014, null
  %1016 = icmp slt i32 %1013, 1
  %1017 = or i1 %1016, %1015
  br i1 %1017, label %1030, label %1018

1018:                                             ; preds = %1009
  %1019 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %1020 = add nuw nsw i32 %1019, %1013
  %1021 = icmp sgt i32 %1020, 67108864
  br i1 %1021, label %1022, label %1025

1022:                                             ; preds = %1018
  %1023 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %1023, label %1030, label %1024

1024:                                             ; preds = %1022
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  invoke void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
          to label %1030 unwind label %1055

1025:                                             ; preds = %1018
  %1026 = zext nneg i32 %1013 to i64
  %1027 = call i64 @fwrite(ptr noundef nonnull readonly %1, i64 noundef 1, i64 noundef %1026, ptr noundef nonnull %1014)
  %1028 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %1029 = add nuw nsw i32 %1028, %1013
  store i32 %1029, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %1030

1030:                                             ; preds = %1025, %1024, %1022, %1009
  invoke void @llvm.seh.scope.end()
          to label %1031 unwind label %1055

1031:                                             ; preds = %1030
  tail call void @llvm.seh.scope.begin()
  %1032 = load i64, ptr %828, align 8
  %1033 = icmp ugt i64 %1032, 15
  br i1 %1033, label %1034, label %1052

1034:                                             ; preds = %1031
  %1035 = load ptr, ptr %2, align 8
  %1036 = add i64 %1032, 1
  %1037 = icmp ugt i64 %1036, 4095
  br i1 %1037, label %1038, label %1049

1038:                                             ; preds = %1034
  %1039 = getelementptr inbounds i8, ptr %1035, i64 -8
  %1040 = load i64, ptr %1039, align 8
  %1041 = ptrtoint ptr %1035 to i64
  %1042 = add i64 %1041, -8
  %1043 = sub i64 %1042, %1040
  %1044 = icmp ult i64 %1043, 32
  br i1 %1044, label %1046, label %1045

1045:                                             ; preds = %1038
  call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

1046:                                             ; preds = %1038
  %1047 = add i64 %1032, 40
  %1048 = inttoptr i64 %1040 to ptr
  br label %1049

1049:                                             ; preds = %1046, %1034
  %1050 = phi i64 [ %1047, %1046 ], [ %1036, %1034 ]
  %1051 = phi ptr [ %1048, %1046 ], [ %1035, %1034 ]
  call void @"??3@YAXPEAX_K@Z"(ptr noundef %1051, i64 noundef %1050) #30
  br label %1052

1052:                                             ; preds = %1049, %1031
  tail call void @llvm.seh.scope.end()
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #30
  br label %1053

1053:                                             ; preds = %1052, %838, %834
  %1054 = add nuw nsw i64 %832, 1
  br label %831, !llvm.loop !41

1055:                                             ; preds = %1030, %1024, %975, %974, %972, %917, %907, %893, %885, %882
  %1056 = cleanuppad within none []
  call void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %2) #30 [ "funclet"(token %1056) ]
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #30
  cleanupret from %1056 unwind to caller

1057:                                             ; preds = %831, %1113
  %1058 = phi i64 [ %1114, %1113 ], [ 0, %831 ]
  %1059 = getelementptr inbounds nuw [64 x %"struct.opf::(anonymous namespace)::OffKind"], ptr @"?g_off@?A0xB9C01504@opf@@3PAUOffKind@?A0xB9C01504@1@A", i64 0, i64 %1058
  %1060 = load volatile i64, ptr %1059, align 8
  fence syncscope("singlethread") seq_cst
  %1061 = inttoptr i64 %1060 to ptr
  %1062 = icmp eq i64 %1060, 0
  br i1 %1062, label %1113, label %1063

1063:                                             ; preds = %1057
  %1064 = getelementptr inbounds nuw i8, ptr %1059, i64 8
  %1065 = load volatile i64, ptr %1064, align 8
  %1066 = getelementptr inbounds nuw i8, ptr %1059, i64 16
  %1067 = load volatile i64, ptr %1066, align 8
  %1068 = getelementptr inbounds nuw [64 x i64], ptr @"?g_offLastCalls@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %1058
  %1069 = load i64, ptr %1068, align 8
  %1070 = icmp eq i64 %1065, %1069
  br i1 %1070, label %1113, label %1071

1071:                                             ; preds = %1063
  %1072 = getelementptr inbounds nuw [64 x i64], ptr @"?g_offLastTicks@?A0xB9C01504@opf@@3PA_KA", i64 0, i64 %1058
  %1073 = load i64, ptr %1072, align 8
  %1074 = sub i64 %1067, %1073
  %1075 = uitofp i64 %1074 to double
  %1076 = fmul double %1075, 1.000000e+03
  %1077 = load i64, ptr @"?g_freq@?A0xB9C01504@opf@@3T_LARGE_INTEGER@@A", align 8
  %1078 = sitofp i64 %1077 to double
  %1079 = fdiv double %1076, %1078
  %1080 = sub i64 %1065, %1069
  %1081 = call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %1082 = load ptr, ptr %1081, align 8
  %1083 = icmp ugt ptr %1082, %1061
  br i1 %1083, label %1094, label %1084

1084:                                             ; preds = %1071
  %1085 = getelementptr inbounds nuw i8, ptr %1081, i64 60
  %1086 = load i32, ptr %1085, align 4
  %1087 = zext i32 %1086 to i64
  %1088 = getelementptr inbounds nuw i8, ptr %1082, i64 %1087
  %1089 = icmp ugt ptr %1088, %1061
  br i1 %1089, label %1090, label %1094

1090:                                             ; preds = %1084
  %1091 = ptrtoint ptr %1082 to i64
  %1092 = sub i64 %1060, %1091
  %1093 = trunc i64 %1092 to i32
  br label %1094

1094:                                             ; preds = %1090, %1084, %1071
  %1095 = phi i32 [ %1093, %1090 ], [ 0, %1084 ], [ 0, %1071 ]
  %1096 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %1, i64 noundef 1024, ptr noundef nonnull @"??_C@_0BH@PLKFBJEJ@O?0?$CF?43f?00x?$CFX?0?$CFllu?0?$CF?44f?6?$AA@", double noundef %441, i32 noundef %1095, i64 noundef %1080, double noundef %1079) #30
  store i64 %1065, ptr %1068, align 8
  store i64 %1067, ptr %1072, align 8
  %1097 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %1098 = icmp eq ptr %1097, null
  %1099 = icmp slt i32 %1096, 1
  %1100 = or i1 %1099, %1098
  br i1 %1100, label %1113, label %1101

1101:                                             ; preds = %1094
  %1102 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %1103 = add nuw nsw i32 %1102, %1096
  %1104 = icmp sgt i32 %1103, 67108864
  br i1 %1104, label %1105, label %1108

1105:                                             ; preds = %1101
  %1106 = load i1, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %1106, label %1113, label %1107

1107:                                             ; preds = %1105
  store i1 true, ptr @"?g_capLogged@?A0xB9C01504@opf@@3_NA", align 1
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0EG@LKJAIAFM@?$FLticksplit?$FN?5the?5csv?5reached?5its?5@", i32 noundef 64)
  br label %1113

1108:                                             ; preds = %1101
  %1109 = zext nneg i32 %1096 to i64
  %1110 = call i64 @fwrite(ptr noundef nonnull readonly %1, i64 noundef 1, i64 noundef %1109, ptr noundef nonnull %1097)
  %1111 = load i32, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  %1112 = add nuw nsw i32 %1111, %1096
  store i32 %1112, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  br label %1113

1113:                                             ; preds = %1108, %1107, %1105, %1094, %1063, %1057
  %1114 = add nuw nsw i64 %1058, 1
  %1115 = icmp eq i64 %1114, 64
  br i1 %1115, label %1116, label %1057, !llvm.loop !42

1116:                                             ; preds = %1113
  call void @llvm.lifetime.end.p0(i64 1024, ptr nonnull %1) #30
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(229976) %437, i8 0, i64 229976, i1 false)
  fence syncscope("singlethread") seq_cst
  store volatile i32 -1, ptr @"?g_pending@?A0xB9C01504@opf@@3U?$atomic@H@std@@A", align 4
  br label %1117

1117:                                             ; preds = %1116, %164
  %1118 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %1119 = call i32 @fflush(ptr noundef %1118)
  br label %1120

1120:                                             ; preds = %1117, %14, %157, %154, %0
  ret void
}

; Function Attrs: nofree nounwind
declare dso_local noundef i32 @fflush(ptr noundef captures(none)) local_unnamed_addr #12

; Function Attrs: mustprogress nofree norecurse nosync nounwind sspstrong willreturn memory(read, argmem: write, inaccessiblemem: none) uwtable
define dso_local noundef zeroext i1 @"?TickSplitInfo@opf@@YA_NPEAUTickSplitInfoOut@1@@Z"(ptr noundef writeonly captures(address_is_null) %0) local_unnamed_addr #13 {
  %2 = icmp ne ptr %0, null
  br i1 %2, label %3, label %31

3:                                                ; preds = %1
  %4 = load i8, ptr @"?g_installed@?A0xB9C01504@opf@@3_NA", align 1, !range !20, !noundef !21
  store i8 %4, ptr %0, align 8
  %5 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.0", align 8
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 8
  store ptr %5, ptr %6, align 8
  %7 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.1", align 8
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store ptr %7, ptr %8, align 8
  %9 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.2", align 8
  %10 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store ptr %9, ptr %10, align 8
  %11 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.3", align 8
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 32
  store ptr %11, ptr %12, align 8
  %13 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.4", align 8
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 40
  store ptr %13, ptr %14, align 8
  %15 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.5", align 8
  %16 = getelementptr inbounds nuw i8, ptr %0, i64 48
  store ptr %15, ptr %16, align 8
  %17 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.6", align 8
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 56
  store ptr %17, ptr %18, align 8
  %19 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.7", align 8
  %20 = getelementptr inbounds nuw i8, ptr %0, i64 64
  store ptr %19, ptr %20, align 8
  %21 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.11", align 8
  %22 = getelementptr inbounds nuw i8, ptr %0, i64 72
  store ptr %21, ptr %22, align 8
  %23 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.8", align 8
  %24 = getelementptr inbounds nuw i8, ptr %0, i64 80
  store ptr %23, ptr %24, align 8
  %25 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.9", align 8
  %26 = getelementptr inbounds nuw i8, ptr %0, i64 88
  store ptr %25, ptr %26, align 8
  %27 = load ptr, ptr @"?st@?A0xB9C01504@opf@@3USites@?A0xB9C01504@1@A.10", align 8
  %28 = getelementptr inbounds nuw i8, ptr %0, i64 96
  store ptr %27, ptr %28, align 8
  %29 = getelementptr inbounds nuw i8, ptr %0, i64 104
  store ptr @"?ExecHook@?A0xB9C01504@opf@@YAXPEAXMHHPEBX@Z", ptr %29, align 8
  %30 = getelementptr inbounds nuw i8, ptr %0, i64 112
  store ptr @"?TickableHook@?A0xB9C01504@opf@@YAXPEAXM@Z", ptr %30, align 8
  br label %31

31:                                               ; preds = %1, %3
  ret i1 %2
}

; Function Attrs: mustprogress sspstrong uwtable
define dso_local void @"?TickSplitTestSetup@opf@@YAXP6A_KXZPEB_W@Z"(ptr noundef %0, ptr noundef %1) local_unnamed_addr #5 {
  store ptr %0, ptr @"?g_testClock@?A0xB9C01504@opf@@3P6A_KXZEA", align 8
  %3 = icmp eq ptr %1, null
  br i1 %3, label %22, label %4

4:                                                ; preds = %2
  %5 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %6 = icmp eq ptr %5, null
  br i1 %6, label %9, label %7

7:                                                ; preds = %4
  %8 = tail call i32 @fclose(ptr noundef nonnull %5)
  store ptr null, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  br label %9

9:                                                ; preds = %7, %4
  %10 = tail call noundef i64 @wcslen(ptr noundef nonnull %1) #31
  %11 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 24), align 8
  %12 = icmp ugt i64 %10, %11
  br i1 %12, label %19, label %13

13:                                               ; preds = %9
  %14 = icmp ugt i64 %11, 7
  %15 = load ptr, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", align 8
  %16 = select i1 %14, ptr %15, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A"
  store i64 %10, ptr getelementptr inbounds nuw (i8, ptr @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 16), align 8
  %17 = shl i64 %10, 1
  tail call void @llvm.memmove.p0.p0.i64(ptr align 2 %16, ptr nonnull align 2 %1, i64 %17, i1 false)
  %18 = getelementptr inbounds nuw i16, ptr %16, i64 %10
  store i16 0, ptr %18, align 2
  br label %21

19:                                               ; preds = %9
  %20 = tail call noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_for@V<lambda_1>@?0??assign@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??assign@01@QEAAAEAV01@QEB_W0@Z@PEB_W@Z"(ptr noundef nonnull align 8 dereferenceable(32) @"?g_path@?A0xB9C01504@opf@@3V?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@A", i64 noundef %10, i8 undef, ptr noundef nonnull %1)
  br label %21

21:                                               ; preds = %13, %19
  store i32 0, ptr @"?g_fileBytes@?A0xB9C01504@opf@@3JA", align 4
  store i1 false, ptr @"?g_fileFailed@?A0xB9C01504@opf@@3_NA", align 1
  br label %22

22:                                               ; preds = %21, %2
  ret void
}

; Function Attrs: nofree nounwind
declare dso_local noundef i32 @fclose(ptr noundef captures(none)) local_unnamed_addr #12

; Function Attrs: mustprogress nofree nounwind sspstrong uwtable
define dso_local void @"?TickSplitTestClose@opf@@YAXXZ"() local_unnamed_addr #14 {
  %1 = load ptr, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  %2 = icmp eq ptr %1, null
  br i1 %2, label %5, label %3

3:                                                ; preds = %0
  %4 = tail call i32 @fclose(ptr noundef nonnull %1)
  store ptr null, ptr @"?g_file@?A0xB9C01504@opf@@3PEAU_iobuf@@EA", align 8
  br label %5

5:                                                ; preds = %3, %0
  ret void
}

; Function Attrs: nobuiltin nounwind
declare dso_local void @"??3@YAXPEAX_K@Z"(ptr noundef, i64 noundef) local_unnamed_addr #15

; Function Attrs: noreturn
declare dso_local void @_invoke_watson(ptr noundef, ptr noundef, ptr noundef, i32 noundef, i64 noundef) local_unnamed_addr #16

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 {
  %2 = load ptr, ptr %0, align 8
  %3 = icmp eq ptr %2, null
  br i1 %3, label %24, label %4

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %6 = load ptr, ptr %5, align 8
  %7 = ptrtoint ptr %6 to i64
  %8 = ptrtoint ptr %2 to i64
  %9 = sub i64 %7, %8
  %10 = icmp ugt i64 %9, 4095
  br i1 %10, label %11, label %21

11:                                               ; preds = %4
  %12 = getelementptr inbounds i8, ptr %2, i64 -8
  %13 = load i64, ptr %12, align 8
  %14 = add i64 %8, -8
  %15 = sub i64 %14, %13
  %16 = icmp ult i64 %15, 32
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

18:                                               ; preds = %11
  %19 = add i64 %9, 39
  %20 = inttoptr i64 %13 to ptr
  br label %21

21:                                               ; preds = %18, %4
  %22 = phi i64 [ %19, %18 ], [ %9, %4 ]
  %23 = phi ptr [ %20, %18 ], [ %2, %4 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %23, i64 noundef %22) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %0, i8 0, i64 24, i1 false)
  br label %24

24:                                               ; preds = %1, %21
  ret void
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(16) %0) unnamed_addr #0 comdat align 2 {
  %2 = load ptr, ptr %0, align 8
  %3 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %4 = load ptr, ptr %3, align 8
  store ptr null, ptr %4, align 8
  %5 = load ptr, ptr %2, align 8
  %6 = icmp eq ptr %5, null
  br i1 %6, label %12, label %7

7:                                                ; preds = %1, %7
  %8 = phi ptr [ %9, %7 ], [ %5, %1 ]
  %9 = load ptr, ptr %8, align 8
  %10 = getelementptr inbounds nuw i8, ptr %8, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %10) #30
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %8, i64 noundef 56) #30
  %11 = icmp eq ptr %9, null
  br i1 %11, label %12, label %7, !llvm.loop !18

12:                                               ; preds = %7, %1
  %13 = load ptr, ptr %0, align 8
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %13, i64 noundef 56) #30
  ret void
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef %0) local_unnamed_addr #0 comdat personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %39

2:                                                ; preds = %1
  invoke void @llvm.seh.scope.end()
          to label %3 unwind label %39

3:                                                ; preds = %2
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  invoke void @llvm.seh.scope.begin()
          to label %5 unwind label %33

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %7 = load i64, ptr %6, align 8
  %8 = icmp ugt i64 %7, 15
  br i1 %8, label %9, label %27

9:                                                ; preds = %5
  %10 = load ptr, ptr %4, align 8
  %11 = add i64 %7, 1
  %12 = icmp ugt i64 %11, 4095
  br i1 %12, label %13, label %24

13:                                               ; preds = %9
  %14 = getelementptr inbounds i8, ptr %10, i64 -8
  %15 = load i64, ptr %14, align 8
  %16 = ptrtoint ptr %10 to i64
  %17 = add i64 %16, -8
  %18 = sub i64 %17, %15
  %19 = icmp ult i64 %18, 32
  br i1 %19, label %21, label %20

20:                                               ; preds = %13
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

21:                                               ; preds = %13
  %22 = add i64 %7, 40
  %23 = inttoptr i64 %15 to ptr
  br label %24

24:                                               ; preds = %21, %9
  %25 = phi i64 [ %22, %21 ], [ %11, %9 ]
  %26 = phi ptr [ %23, %21 ], [ %10, %9 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %26, i64 noundef %25) #30
  br label %27

27:                                               ; preds = %24, %5
  %28 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 0, ptr %28, align 8
  store i64 15, ptr %6, align 8
  store i8 0, ptr %4, align 1
  invoke void @llvm.seh.scope.end()
          to label %29 unwind label %33

29:                                               ; preds = %27
  invoke void @llvm.seh.scope.begin()
          to label %30 unwind label %31

30:                                               ; preds = %29
  invoke void @llvm.seh.scope.end()
          to label %42 unwind label %31

31:                                               ; preds = %30, %29
  %32 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %32 unwind to caller

33:                                               ; preds = %27, %3
  %34 = cleanuppad within none []
  invoke void @llvm.seh.scope.begin()
          to label %35 unwind label %36

35:                                               ; preds = %33
  invoke void @llvm.seh.scope.end()
          to label %38 unwind label %36

36:                                               ; preds = %35, %33
  %37 = cleanuppad within %34 []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %37 unwind to caller

38:                                               ; preds = %35
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %34 unwind to caller

39:                                               ; preds = %2, %1
  %40 = cleanuppad within none []
  %41 = getelementptr inbounds nuw i8, ptr %0, i64 8
  call void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %41) #30 [ "funclet"(token %40) ]
  cleanupret from %40 unwind to caller

42:                                               ; preds = %30
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  ret void
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %0) unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %31

2:                                                ; preds = %1
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %4 = load i64, ptr %3, align 8
  %5 = icmp ugt i64 %4, 15
  br i1 %5, label %6, label %24

6:                                                ; preds = %2
  %7 = load ptr, ptr %0, align 8
  %8 = add i64 %4, 1
  %9 = icmp ugt i64 %8, 4095
  br i1 %9, label %10, label %21

10:                                               ; preds = %6
  %11 = getelementptr inbounds i8, ptr %7, i64 -8
  %12 = load i64, ptr %11, align 8
  %13 = ptrtoint ptr %7 to i64
  %14 = add i64 %13, -8
  %15 = sub i64 %14, %12
  %16 = icmp ult i64 %15, 32
  br i1 %16, label %18, label %17

17:                                               ; preds = %10
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

18:                                               ; preds = %10
  %19 = add i64 %4, 40
  %20 = inttoptr i64 %12 to ptr
  br label %21

21:                                               ; preds = %18, %6
  %22 = phi i64 [ %19, %18 ], [ %8, %6 ]
  %23 = phi ptr [ %20, %18 ], [ %7, %6 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %23, i64 noundef %22) #30
  br label %24

24:                                               ; preds = %2, %21
  %25 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 0, ptr %25, align 8
  store i64 15, ptr %3, align 8
  store i8 0, ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %26 unwind label %31

26:                                               ; preds = %24
  invoke void @llvm.seh.scope.begin()
          to label %27 unwind label %28

27:                                               ; preds = %26
  invoke void @llvm.seh.scope.end()
          to label %30 unwind label %28

28:                                               ; preds = %27, %26
  %29 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %29 unwind to caller

30:                                               ; preds = %27
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  ret void

31:                                               ; preds = %24, %1
  %32 = cleanuppad within none []
  invoke void @llvm.seh.scope.begin()
          to label %33 unwind label %34

33:                                               ; preds = %31
  invoke void @llvm.seh.scope.end()
          to label %36 unwind label %34

34:                                               ; preds = %33, %31
  %35 = cleanuppad within %32 []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %35 unwind to caller

36:                                               ; preds = %33
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %32 unwind to caller
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W_K@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEB_W0@Z@PEB_W_K@Z"(ptr noundef nonnull align 8 dereferenceable(32) %0, i64 noundef %1, i8 %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 comdat align 2 {
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %7 = load i64, ptr %6, align 8
  %8 = sub i64 9223372036854775806, %7
  %9 = icmp ult i64 %8, %1
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @"?_Xlen_string@std@@YAXXZ"() #32
  unreachable

11:                                               ; preds = %5
  %12 = add i64 %7, %1
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %14 = load i64, ptr %13, align 8
  %15 = or i64 %12, 7
  %16 = icmp ugt i64 %15, 9223372036854775806
  br i1 %16, label %34, label %17

17:                                               ; preds = %11
  %18 = lshr i64 %14, 1
  %19 = sub nsw i64 9223372036854775806, %18
  %20 = icmp ugt i64 %14, %19
  br i1 %20, label %34, label %21

21:                                               ; preds = %17
  %22 = add i64 %18, %14
  %23 = tail call i64 @llvm.umax.i64(i64 %15, i64 %22)
  %24 = add i64 %23, 1
  %25 = icmp slt i64 %24, 0
  br i1 %25, label %26, label %27

26:                                               ; preds = %21
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

27:                                               ; preds = %21
  %28 = shl nuw i64 %24, 1
  %29 = icmp eq i64 %24, 0
  br i1 %29, label %45, label %30

30:                                               ; preds = %27
  %31 = icmp samesign ugt i64 %24, 2047
  br i1 %31, label %32, label %43

32:                                               ; preds = %30
  %33 = icmp samesign ult i64 %24, 9223372036854775789
  br i1 %33, label %35, label %34

34:                                               ; preds = %11, %17, %32
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

35:                                               ; preds = %32
  %36 = add nuw i64 %28, 39
  %37 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %36) #33
  %38 = ptrtoint ptr %37 to i64
  %39 = add i64 %38, 39
  %40 = and i64 %39, -32
  %41 = inttoptr i64 %40 to ptr
  %42 = getelementptr inbounds i8, ptr %41, i64 -8
  store i64 %38, ptr %42, align 8
  br label %45

43:                                               ; preds = %30
  %44 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %28) #33
  br label %45

45:                                               ; preds = %27, %35, %43
  %46 = phi ptr [ %41, %35 ], [ %44, %43 ], [ null, %27 ]
  store i64 %12, ptr %6, align 8
  store i64 %23, ptr %13, align 8
  %47 = icmp ugt i64 %14, 7
  br i1 %47, label %48, label %71

48:                                               ; preds = %45
  %49 = load ptr, ptr %0, align 8
  %50 = shl i64 %7, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 2 %46, ptr align 2 %49, i64 %50, i1 false)
  %51 = getelementptr i16, ptr %46, i64 %7
  %52 = shl i64 %4, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 2 %51, ptr align 2 %3, i64 %52, i1 false)
  %53 = getelementptr i16, ptr %51, i64 %4
  store i16 0, ptr %53, align 2
  %54 = shl i64 %14, 1
  %55 = add i64 %54, 2
  %56 = icmp ugt i64 %55, 4095
  br i1 %56, label %57, label %68

57:                                               ; preds = %48
  %58 = getelementptr inbounds i8, ptr %49, i64 -8
  %59 = load i64, ptr %58, align 8
  %60 = ptrtoint ptr %49 to i64
  %61 = add i64 %60, -8
  %62 = sub i64 %61, %59
  %63 = icmp ult i64 %62, 32
  br i1 %63, label %65, label %64

64:                                               ; preds = %57
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

65:                                               ; preds = %57
  %66 = add i64 %54, 41
  %67 = inttoptr i64 %59 to ptr
  br label %68

68:                                               ; preds = %48, %65
  %69 = phi i64 [ %66, %65 ], [ %55, %48 ]
  %70 = phi ptr [ %67, %65 ], [ %49, %48 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %70, i64 noundef %69) #30
  br label %76

71:                                               ; preds = %45
  %72 = shl i64 %7, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 2 %46, ptr nonnull align 8 %0, i64 %72, i1 false)
  %73 = getelementptr i16, ptr %46, i64 %7
  %74 = shl i64 %4, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 2 %73, ptr align 2 %3, i64 %74, i1 false)
  %75 = getelementptr i16, ptr %73, i64 %4
  store i16 0, ptr %75, align 2
  br label %76

76:                                               ; preds = %71, %68
  store ptr %46, ptr %0, align 8
  ret ptr %0
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr writeonly captures(none), ptr readonly captures(none), i64, i1 immarg) #9

; Function Attrs: inlinehint mustprogress noreturn sspstrong uwtable
define linkonce_odr dso_local void @"?_Xlen_string@std@@YAXXZ"() local_unnamed_addr #17 comdat {
  tail call void @"?_Xlength_error@std@@YAXPEBD@Z"(ptr noundef nonnull @"??_C@_0BA@JFNIOLAK@string?5too?5long?$AA@") #32
  unreachable
}

; Function Attrs: noreturn
declare dso_local void @"?_Xlength_error@std@@YAXPEBD@Z"(ptr noundef) local_unnamed_addr #16

; Function Attrs: inlinehint mustprogress noreturn sspstrong uwtable
define linkonce_odr dso_local void @"?_Throw_bad_array_new_length@std@@YAXXZ"() local_unnamed_addr #17 comdat {
  %1 = alloca %"class.std::bad_array_new_length", align 8
  %2 = call noundef ptr @"??0bad_array_new_length@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %1) #30
  call void @_CxxThrowException(ptr nonnull %1, ptr nonnull @"_TI3?AVbad_array_new_length@std@@") #32
  unreachable
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0bad_array_new_length@std@@QEAA@XZ"(ptr noundef nonnull returned align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 0, ptr %3, align 8
  store ptr @"??_C@_0BF@KINCDENJ@bad?5array?5new?5length?$AA@", ptr %2, align 8
  invoke void @llvm.seh.scope.begin()
          to label %4 unwind label %5

4:                                                ; preds = %1
  store ptr @"??_7bad_alloc@std@@6B@", ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %7 unwind label %5

5:                                                ; preds = %4, %1
  %6 = cleanuppad within none []
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  call void @__std_exception_destroy(ptr noundef nonnull %2) #30 [ "funclet"(token %6) ]
  cleanupret from %6 unwind to caller

7:                                                ; preds = %4
  invoke void @llvm.seh.scope.begin()
          to label %8 unwind label %10

8:                                                ; preds = %7
  store ptr @"??_7bad_array_new_length@std@@6B@", ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %9 unwind label %10

9:                                                ; preds = %8
  ret ptr %0

10:                                               ; preds = %8, %7
  %11 = cleanuppad within none []
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  call void @__std_exception_destroy(ptr noundef nonnull %2) #30 [ "funclet"(token %11) ]
  cleanupret from %11 unwind to caller
}

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0bad_array_new_length@std@@QEAA@AEBV01@@Z"(ptr noundef nonnull returned align 8 dereferenceable(24) %0, ptr noundef nonnull align 8 dereferenceable(24) %1) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  %4 = getelementptr inbounds nuw i8, ptr %1, i64 8
  tail call void @__std_exception_copy(ptr noundef nonnull %4, ptr noundef nonnull %3) #30
  invoke void @llvm.seh.scope.begin()
          to label %5 unwind label %6

5:                                                ; preds = %2
  store ptr @"??_7bad_alloc@std@@6B@", ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %8 unwind label %6

6:                                                ; preds = %5, %2
  %7 = cleanuppad within none []
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  call void @__std_exception_destroy(ptr noundef nonnull %3) #30 [ "funclet"(token %7) ]
  cleanupret from %7 unwind to caller

8:                                                ; preds = %5
  invoke void @llvm.seh.scope.begin()
          to label %9 unwind label %11

9:                                                ; preds = %8
  store ptr @"??_7bad_array_new_length@std@@6B@", ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %10 unwind label %11

10:                                               ; preds = %9
  ret ptr %0

11:                                               ; preds = %9, %8
  %12 = cleanuppad within none []
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  call void @__std_exception_destroy(ptr noundef nonnull %3) #30 [ "funclet"(token %12) ]
  cleanupret from %12 unwind to caller
}

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0bad_alloc@std@@QEAA@AEBV01@@Z"(ptr noundef nonnull returned align 8 dereferenceable(24) %0, ptr noundef nonnull align 8 dereferenceable(24) %1) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  %4 = getelementptr inbounds nuw i8, ptr %1, i64 8
  tail call void @__std_exception_copy(ptr noundef nonnull %4, ptr noundef nonnull %3) #30
  invoke void @llvm.seh.scope.begin()
          to label %5 unwind label %7

5:                                                ; preds = %2
  store ptr @"??_7bad_alloc@std@@6B@", ptr %0, align 8
  invoke void @llvm.seh.scope.end()
          to label %6 unwind label %7

6:                                                ; preds = %5
  ret ptr %0

7:                                                ; preds = %5, %2
  %8 = cleanuppad within none []
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  call void @__std_exception_destroy(ptr noundef nonnull %3) #30 [ "funclet"(token %8) ]
  cleanupret from %8 unwind to caller
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0exception@std@@QEAA@AEBV01@@Z"(ptr noundef nonnull returned align 8 dereferenceable(24) %0, ptr noundef nonnull align 8 dereferenceable(24) %1) unnamed_addr #0 comdat align 2 {
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %3, i8 0, i64 16, i1 false)
  %4 = getelementptr inbounds nuw i8, ptr %1, i64 8
  tail call void @__std_exception_copy(ptr noundef nonnull %4, ptr noundef nonnull %3) #30
  ret ptr %0
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1exception@std@@UEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 {
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @__std_exception_destroy(ptr noundef nonnull %2) #30
  ret void
}

declare dso_local void @_CxxThrowException(ptr, ptr) local_unnamed_addr

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??_Gbad_array_new_length@std@@UEAAPEAXI@Z"(ptr noundef nonnull align 8 dereferenceable(24) %0, i32 noundef %1) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %9

3:                                                ; preds = %2
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @__std_exception_destroy(ptr noundef nonnull %4) #30
  invoke void @llvm.seh.scope.end()
          to label %5 unwind label %9

5:                                                ; preds = %3
  %6 = icmp eq i32 %1, 0
  br i1 %6, label %8, label %7

7:                                                ; preds = %5
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35
  br label %8

8:                                                ; preds = %7, %5
  ret ptr %0

9:                                                ; preds = %3, %2
  %10 = cleanuppad within none []
  %11 = icmp eq i32 %1, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %9
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35 [ "funclet"(token %10) ]
  br label %13

13:                                               ; preds = %12, %9
  cleanupret from %10 unwind to caller
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"?what@exception@std@@UEBAPEBDXZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %3 = load ptr, ptr %2, align 8
  %4 = icmp eq ptr %3, null
  %5 = select i1 %4, ptr @"??_C@_0BC@EOODALEL@Unknown?5exception?$AA@", ptr %3
  ret ptr %5
}

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??_Gbad_alloc@std@@UEAAPEAXI@Z"(ptr noundef nonnull align 8 dereferenceable(24) %0, i32 noundef %1) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %9

3:                                                ; preds = %2
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @__std_exception_destroy(ptr noundef nonnull %4) #30
  invoke void @llvm.seh.scope.end()
          to label %5 unwind label %9

5:                                                ; preds = %3
  %6 = icmp eq i32 %1, 0
  br i1 %6, label %8, label %7

7:                                                ; preds = %5
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35
  br label %8

8:                                                ; preds = %7, %5
  ret ptr %0

9:                                                ; preds = %3, %2
  %10 = cleanuppad within none []
  %11 = icmp eq i32 %1, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %9
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35 [ "funclet"(token %10) ]
  br label %13

13:                                               ; preds = %12, %9
  cleanupret from %10 unwind to caller
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??_Gexception@std@@UEAAPEAXI@Z"(ptr noundef nonnull align 8 dereferenceable(24) %0, i32 noundef %1) unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %9

3:                                                ; preds = %2
  store ptr @"??_7exception@std@@6B@", ptr %0, align 8
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @__std_exception_destroy(ptr noundef nonnull %4) #30
  invoke void @llvm.seh.scope.end()
          to label %5 unwind label %9

5:                                                ; preds = %3
  %6 = icmp eq i32 %1, 0
  br i1 %6, label %8, label %7

7:                                                ; preds = %5
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35
  br label %8

8:                                                ; preds = %7, %5
  ret ptr %0

9:                                                ; preds = %3, %2
  %10 = cleanuppad within none []
  %11 = icmp eq i32 %1, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %9
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %0, i64 noundef 24) #35 [ "funclet"(token %10) ]
  br label %13

13:                                               ; preds = %12, %9
  cleanupret from %10 unwind to caller
}

declare dso_local void @__std_exception_destroy(ptr noundef) local_unnamed_addr #6

declare dso_local void @__std_exception_copy(ptr noundef, ptr noundef) local_unnamed_addr #6

; Function Attrs: nobuiltin allocsize(0)
declare dso_local noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef) local_unnamed_addr #18

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare dso_local i64 @wcslen(ptr noundef captures(none)) local_unnamed_addr #19

declare dso_local void @"?FindAll@opf@@YA?AV?$vector@PEAEV?$allocator@PEAE@std@@@std@@AEBUSection@1@AEBUPattern@1@@Z"(ptr dead_on_unwind writable sret(%"class.std::vector") align 8, ptr noundef nonnull align 8 dereferenceable(16), ptr noundef nonnull align 8 dereferenceable(48)) local_unnamed_addr #6

declare dso_local void @"?ParsePattern@opf@@YA?AUPattern@1@V?$basic_string_view@DU?$char_traits@D@std@@@std@@@Z"(ptr dead_on_unwind writable sret(%"struct.opf::Pattern") align 8, ptr noundef) local_unnamed_addr #6

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1Pattern@opf@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(48) %0) unnamed_addr #3 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %57

2:                                                ; preds = %1
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %53

3:                                                ; preds = %2
  invoke void @llvm.seh.scope.end()
          to label %4 unwind label %53

4:                                                ; preds = %3
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %6 = load ptr, ptr %5, align 8
  %7 = icmp eq ptr %6, null
  br i1 %7, label %28, label %8

8:                                                ; preds = %4
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %10 = load ptr, ptr %9, align 8
  %11 = ptrtoint ptr %10 to i64
  %12 = ptrtoint ptr %6 to i64
  %13 = sub i64 %11, %12
  %14 = icmp ugt i64 %13, 4095
  br i1 %14, label %15, label %25

15:                                               ; preds = %8
  %16 = getelementptr inbounds i8, ptr %6, i64 -8
  %17 = load i64, ptr %16, align 8
  %18 = add i64 %12, -8
  %19 = sub i64 %18, %17
  %20 = icmp ult i64 %19, 32
  br i1 %20, label %22, label %21

21:                                               ; preds = %15
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

22:                                               ; preds = %15
  %23 = add i64 %13, 39
  %24 = inttoptr i64 %17 to ptr
  br label %25

25:                                               ; preds = %22, %8
  %26 = phi i64 [ %23, %22 ], [ %13, %8 ]
  %27 = phi ptr [ %24, %22 ], [ %6, %8 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %27, i64 noundef %26) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %5, i8 0, i64 24, i1 false)
  br label %28

28:                                               ; preds = %4, %25
  invoke void @llvm.seh.scope.end()
          to label %29 unwind label %57

29:                                               ; preds = %28
  %30 = load ptr, ptr %0, align 8
  %31 = icmp eq ptr %30, null
  br i1 %31, label %52, label %32

32:                                               ; preds = %29
  %33 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %34 = load ptr, ptr %33, align 8
  %35 = ptrtoint ptr %34 to i64
  %36 = ptrtoint ptr %30 to i64
  %37 = sub i64 %35, %36
  %38 = icmp ugt i64 %37, 4095
  br i1 %38, label %39, label %49

39:                                               ; preds = %32
  %40 = getelementptr inbounds i8, ptr %30, i64 -8
  %41 = load i64, ptr %40, align 8
  %42 = add i64 %36, -8
  %43 = sub i64 %42, %41
  %44 = icmp ult i64 %43, 32
  br i1 %44, label %46, label %45

45:                                               ; preds = %39
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

46:                                               ; preds = %39
  %47 = add i64 %37, 39
  %48 = inttoptr i64 %41 to ptr
  br label %49

49:                                               ; preds = %46, %32
  %50 = phi i64 [ %47, %46 ], [ %37, %32 ]
  %51 = phi ptr [ %48, %46 ], [ %30, %32 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %51, i64 noundef %50) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %0, i8 0, i64 24, i1 false)
  br label %52

52:                                               ; preds = %29, %49
  ret void

53:                                               ; preds = %3, %2
  %54 = cleanuppad within none []
  invoke void @llvm.seh.scope.end() [ "funclet"(token %54) ]
          to label %55 unwind label %57

55:                                               ; preds = %53
  %56 = getelementptr inbounds nuw i8, ptr %0, i64 24
  call void @"??1?$vector@EV?$allocator@E@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %56) #30 [ "funclet"(token %54) ]
  cleanupret from %54 unwind label %57

57:                                               ; preds = %28, %55, %53, %1
  %58 = cleanuppad within none []
  call void @"??1?$vector@EV?$allocator@E@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) #30 [ "funclet"(token %58) ]
  cleanupret from %58 unwind to caller
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$vector@PEAEV?$allocator@PEAE@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 {
  %2 = load ptr, ptr %0, align 8
  %3 = icmp eq ptr %2, null
  br i1 %3, label %24, label %4

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %6 = load ptr, ptr %5, align 8
  %7 = ptrtoint ptr %6 to i64
  %8 = ptrtoint ptr %2 to i64
  %9 = sub i64 %7, %8
  %10 = icmp ugt i64 %9, 4095
  br i1 %10, label %11, label %21

11:                                               ; preds = %4
  %12 = getelementptr inbounds i8, ptr %2, i64 -8
  %13 = load i64, ptr %12, align 8
  %14 = add i64 %8, -8
  %15 = sub i64 %14, %13
  %16 = icmp ult i64 %15, 32
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

18:                                               ; preds = %11
  %19 = add i64 %9, 39
  %20 = inttoptr i64 %13 to ptr
  br label %21

21:                                               ; preds = %18, %4
  %22 = phi i64 [ %19, %18 ], [ %9, %4 ]
  %23 = phi ptr [ %20, %18 ], [ %2, %4 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %23, i64 noundef %22) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %0, i8 0, i64 24, i1 false)
  br label %24

24:                                               ; preds = %1, %21
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare dso_local i64 @strlen(ptr noundef captures(none)) local_unnamed_addr #19

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$vector@EV?$allocator@E@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %0) unnamed_addr #0 comdat align 2 {
  %2 = load ptr, ptr %0, align 8
  %3 = icmp eq ptr %2, null
  br i1 %3, label %24, label %4

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %6 = load ptr, ptr %5, align 8
  %7 = ptrtoint ptr %6 to i64
  %8 = ptrtoint ptr %2 to i64
  %9 = sub i64 %7, %8
  %10 = icmp ugt i64 %9, 4095
  br i1 %10, label %11, label %21

11:                                               ; preds = %4
  %12 = getelementptr inbounds i8, ptr %2, i64 -8
  %13 = load i64, ptr %12, align 8
  %14 = add i64 %8, -8
  %15 = sub i64 %14, %13
  %16 = icmp ult i64 %15, 32
  br i1 %16, label %18, label %17

17:                                               ; preds = %11
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

18:                                               ; preds = %11
  %19 = add i64 %9, 39
  %20 = inttoptr i64 %13 to ptr
  br label %21

21:                                               ; preds = %18, %4
  %22 = phi i64 [ %19, %18 ], [ %9, %4 ]
  %23 = phi ptr [ %20, %18 ], [ %2, %4 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %23, i64 noundef %22) #30
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %0, i8 0, i64 24, i1 false)
  br label %24

24:                                               ; preds = %1, %21
  ret void
}

declare dso_local noundef zeroext i1 @"?LedgerIsGameThread@opf@@YA_NXZ"() local_unnamed_addr #6

; Function Attrs: mustprogress nofree norecurse nosync nounwind sspstrong memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc void @"?Add@?A0xB9C01504@opf@@YAXPEBX0I_K@Z"(ptr noundef %0, ptr noundef %1, i32 noundef %2, i64 noundef %3) unnamed_addr #20 {
  %5 = load i32, ptr @"?g_active@?A0xB9C01504@opf@@3HA", align 4
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds nuw [2 x %"struct.opf::(anonymous namespace)::Window"], ptr @"?g_win@?A0xB9C01504@opf@@3PAUWindow@?A0xB9C01504@1@A", i64 0, i64 %6
  %8 = getelementptr inbounds nuw i8, ptr %7, i64 229592
  %9 = load <2 x i64>, ptr %8, align 8
  %10 = insertelement <2 x i64> <i64 1, i64 poison>, i64 %3, i64 1
  %11 = add <2 x i64> %9, %10
  store <2 x i64> %11, ptr %8, align 8
  %12 = load i64, ptr @"?g_frameExecTicks@?A0xB9C01504@opf@@3_KA", align 8
  %13 = add i64 %12, %3
  store i64 %13, ptr @"?g_frameExecTicks@?A0xB9C01504@opf@@3_KA", align 8
  %14 = load i64, ptr @"?g_frameExecCalls@?A0xB9C01504@opf@@3_KA", align 8
  %15 = add i64 %14, 1
  store i64 %15, ptr @"?g_frameExecCalls@?A0xB9C01504@opf@@3_KA", align 8
  %16 = ptrtoint ptr %0 to i64
  %17 = lshr i64 %16, 3
  %18 = mul i64 %17, -7046029254386353131
  %19 = ptrtoint ptr %1 to i64
  %20 = lshr i64 %19, 3
  %21 = mul i64 %20, -4417276706812531889
  %22 = xor i64 %21, %18
  %23 = lshr i64 %22, 52
  br label %24

24:                                               ; preds = %48, %4
  %25 = phi i32 [ 0, %4 ], [ %49, %48 ]
  %26 = phi i64 [ %23, %4 ], [ %51, %48 ]
  %27 = getelementptr inbounds nuw [4096 x %"struct.opf::(anonymous namespace)::Entry"], ptr %7, i64 0, i64 %26
  %28 = load ptr, ptr %27, align 8
  %29 = icmp eq ptr %28, %0
  br i1 %29, label %30, label %38

30:                                               ; preds = %24
  %31 = getelementptr inbounds nuw i8, ptr %27, i64 8
  %32 = load ptr, ptr %31, align 8
  %33 = icmp eq ptr %32, %1
  br i1 %33, label %34, label %38

34:                                               ; preds = %30
  %35 = getelementptr inbounds nuw i8, ptr %27, i64 16
  %36 = load i32, ptr %35, align 8
  %37 = icmp eq i32 %36, %2
  br i1 %37, label %57, label %38

38:                                               ; preds = %34, %30, %24
  %39 = icmp eq ptr %28, null
  br i1 %39, label %40, label %48

40:                                               ; preds = %38
  %41 = getelementptr inbounds nuw i8, ptr %7, i64 229376
  %42 = load i32, ptr %41, align 8
  %43 = icmp ugt i32 %42, 3071
  br i1 %43, label %53, label %44

44:                                               ; preds = %40
  store ptr %0, ptr %27, align 8
  %45 = getelementptr inbounds nuw i8, ptr %27, i64 8
  store ptr %1, ptr %45, align 8
  %46 = getelementptr inbounds nuw i8, ptr %27, i64 16
  store i32 %2, ptr %46, align 8
  %47 = add nuw nsw i32 %42, 1
  store i32 %47, ptr %41, align 8
  br label %57

48:                                               ; preds = %38
  %49 = add nuw nsw i32 %25, 1
  %50 = add nuw nsw i64 %26, 1
  %51 = and i64 %50, 4095
  %52 = icmp eq i32 %49, 64
  br i1 %52, label %53, label %24, !llvm.loop !43

53:                                               ; preds = %48, %40
  %54 = getelementptr inbounds nuw i8, ptr %7, i64 229384
  %55 = load <2 x i64>, ptr %54, align 8
  %56 = add <2 x i64> %55, %10
  store <2 x i64> %56, ptr %54, align 8
  br label %88

57:                                               ; preds = %34, %44
  %58 = getelementptr inbounds nuw i8, ptr %27, i64 20
  %59 = load i32, ptr %58, align 4
  %60 = add i32 %59, 1
  store i32 %60, ptr %58, align 4
  %61 = getelementptr inbounds nuw i8, ptr %27, i64 24
  %62 = load i64, ptr %61, align 8
  %63 = add i64 %62, %3
  store i64 %63, ptr %61, align 8
  %64 = getelementptr inbounds nuw i8, ptr %27, i64 32
  %65 = load i64, ptr %64, align 8
  %66 = icmp ugt i64 %3, %65
  br i1 %66, label %67, label %68

67:                                               ; preds = %57
  store i64 %3, ptr %64, align 8
  br label %68

68:                                               ; preds = %67, %57
  %69 = getelementptr inbounds nuw i8, ptr %27, i64 48
  %70 = load i64, ptr %69, align 8
  %71 = load i64, ptr @"?g_frameNo@?A0xB9C01504@opf@@3_KA", align 8
  %72 = icmp eq i64 %70, %71
  br i1 %72, label %73, label %76

73:                                               ; preds = %68
  %74 = getelementptr inbounds nuw i8, ptr %27, i64 40
  %75 = load i64, ptr %74, align 8
  br label %84

76:                                               ; preds = %68
  store i64 %71, ptr %69, align 8
  %77 = getelementptr inbounds nuw i8, ptr %27, i64 40
  store i64 0, ptr %77, align 8
  %78 = load i32, ptr @"?g_nTouched@?A0xB9C01504@opf@@3IA", align 4
  %79 = icmp ult i32 %78, 2048
  br i1 %79, label %80, label %84

80:                                               ; preds = %76
  %81 = zext nneg i32 %78 to i64
  %82 = add nuw nsw i32 %78, 1
  store i32 %82, ptr @"?g_nTouched@?A0xB9C01504@opf@@3IA", align 4
  %83 = getelementptr inbounds nuw [2048 x ptr], ptr @"?g_touched@?A0xB9C01504@opf@@3PAPEAUEntry@?A0xB9C01504@1@A", i64 0, i64 %81
  store ptr %27, ptr %83, align 8
  br label %84

84:                                               ; preds = %73, %76, %80
  %85 = phi i64 [ %75, %73 ], [ 0, %76 ], [ 0, %80 ]
  %86 = getelementptr inbounds nuw i8, ptr %27, i64 40
  %87 = add i64 %85, %3
  store i64 %87, ptr %86, align 8
  br label %88

88:                                               ; preds = %84, %53
  ret void
}

; Function Attrs: mustprogress nounwind willreturn memory(write)
declare dso_local void @llvm.seh.try.begin() #21

declare dso_local i32 @__C_specific_handler(...)

; Function Attrs: nofree nosync nounwind memory(none)
declare i32 @llvm.eh.exceptioncode(token) #8

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef zeroext i1 @"?Contains@Section@opf@@QEBA_NPEBX@Z"(ptr noundef nonnull align 8 dereferenceable(16) %0, ptr noundef %1) local_unnamed_addr #0 comdat align 2 {
  %3 = load ptr, ptr %0, align 8
  %4 = icmp uge ptr %1, %3
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %6 = load ptr, ptr %5, align 8
  %7 = icmp ult ptr %1, %6
  %8 = select i1 %4, i1 %7, i1 false
  ret i1 %8
}

declare dso_local noundef ptr @"?RipTarget@opf@@YAPEAEPEBE_K1@Z"(ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #6

declare dllimport i32 @QueryPerformanceCounter(ptr noundef) local_unnamed_addr #6

declare dllimport i32 @MoveFileExW(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #6

declare dso_local ptr @_wfsopen(ptr noundef, ptr noundef, i32 noundef) local_unnamed_addr #6

; Function Attrs: inlinehint mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local i32 @snprintf(ptr noundef %0, i64 noundef %1, ptr noundef %2, ...) local_unnamed_addr #3 comdat {
  %4 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #30
  call void @llvm.va_start.p0(ptr nonnull %4)
  %5 = load ptr, ptr %4, align 8
  %6 = call ptr @__local_stdio_printf_options()
  %7 = load i64, ptr %6, align 8
  %8 = or i64 %7, 2
  %9 = call i32 @__stdio_common_vsprintf(i64 noundef %8, ptr noundef %0, i64 noundef %1, ptr noundef %2, ptr noundef null, ptr noundef %5) #30
  %10 = call i32 @llvm.smax.i32(i32 %9, i32 -1)
  call void @llvm.va_end.p0(ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #30
  ret i32 %10
}

declare dllimport i32 @GetCurrentProcessId() local_unnamed_addr #6

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAA@AEBV01@_K1AEBV?$allocator@_W@1@@Z"(ptr noundef nonnull returned align 8 dereferenceable(32) %0, ptr noundef nonnull align 8 dereferenceable(32) %1, i64 noundef %2, i64 noundef %3, ptr noundef nonnull align 1 dereferenceable(1) %4) unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %0, i8 0, i64 32, i1 false)
  invoke void @llvm.seh.scope.begin()
          to label %6 unwind label %62

6:                                                ; preds = %5
  %7 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %8 = load i64, ptr %7, align 8
  %9 = icmp ult i64 %8, %2
  br i1 %9, label %10, label %12

10:                                               ; preds = %6
  invoke void @"?_Xran@?$_String_val@U?$_Simple_types@_W@std@@@std@@SAXXZ"() #32
          to label %11 unwind label %62

11:                                               ; preds = %10
  unreachable

12:                                               ; preds = %6
  %13 = sub nuw i64 %8, %2
  %14 = tail call noundef i64 @llvm.umin.i64(i64 %13, i64 %3)
  %15 = getelementptr inbounds nuw i8, ptr %1, i64 24
  %16 = load i64, ptr %15, align 8
  %17 = icmp ugt i64 %16, 7
  %18 = load ptr, ptr %1, align 8
  %19 = select i1 %17, ptr %18, ptr %1
  %20 = getelementptr inbounds nuw i16, ptr %19, i64 %2
  %21 = icmp ugt i64 %14, 9223372036854775806
  br i1 %21, label %22, label %24

22:                                               ; preds = %12
  invoke void @"?_Xlen_string@std@@YAXXZ"() #32
          to label %23 unwind label %62

23:                                               ; preds = %22
  unreachable

24:                                               ; preds = %12
  %25 = icmp samesign ult i64 %14, 8
  br i1 %25, label %26, label %31

26:                                               ; preds = %24
  %27 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %14, ptr %27, align 8
  %28 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 7, ptr %28, align 8
  %29 = shl nuw nsw i64 %14, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(32) %0, ptr align 2 %20, i64 %29, i1 false)
  %30 = getelementptr inbounds nuw [8 x i16], ptr %0, i64 0, i64 %14
  store i16 0, ptr %30, align 2
  br label %60

31:                                               ; preds = %24
  %32 = or i64 %14, 7
  %33 = icmp samesign ugt i64 %32, 9223372036854775806
  br i1 %33, label %40, label %34

34:                                               ; preds = %31
  %35 = tail call i64 @llvm.umax.i64(i64 %32, i64 10)
  %36 = shl nuw i64 %35, 1
  %37 = icmp samesign ugt i64 %32, 2046
  br i1 %37, label %38, label %51

38:                                               ; preds = %34
  %39 = icmp samesign ult i64 %32, 9223372036854775788
  br i1 %39, label %42, label %40

40:                                               ; preds = %38, %31
  invoke void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
          to label %41 unwind label %62

41:                                               ; preds = %40
  unreachable

42:                                               ; preds = %38
  %43 = add i64 %36, 41
  %44 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %43) #33
          to label %45 unwind label %62

45:                                               ; preds = %42
  %46 = ptrtoint ptr %44 to i64
  %47 = add i64 %46, 39
  %48 = and i64 %47, -32
  %49 = inttoptr i64 %48 to ptr
  %50 = getelementptr inbounds i8, ptr %49, i64 -8
  store i64 %46, ptr %50, align 8
  br label %54

51:                                               ; preds = %34
  %52 = add nuw nsw i64 %36, 2
  %53 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %52) #33
          to label %54 unwind label %62

54:                                               ; preds = %51, %45
  %55 = phi ptr [ %49, %45 ], [ %53, %51 ]
  store ptr %55, ptr %0, align 8
  %56 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %14, ptr %56, align 8
  %57 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 %35, ptr %57, align 8
  %58 = shl nuw i64 %14, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 2 %55, ptr align 2 %20, i64 %58, i1 false)
  %59 = getelementptr inbounds nuw i16, ptr %55, i64 %14
  store i16 0, ptr %59, align 2
  br label %60

60:                                               ; preds = %54, %26
  invoke void @llvm.seh.scope.end()
          to label %61 unwind label %62

61:                                               ; preds = %60
  ret ptr %0

62:                                               ; preds = %51, %42, %40, %22, %10, %60, %5
  %63 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %63 unwind to caller
}

; Function Attrs: mustprogress noreturn sspstrong uwtable
define linkonce_odr dso_local void @"?_Xran@?$_String_val@U?$_Simple_types@_W@std@@@std@@SAXXZ"() local_unnamed_addr #22 comdat align 2 {
  tail call void @"?_Xout_of_range@std@@YAXPEBD@Z"(ptr noundef nonnull @"??_C@_0BI@CFPLBAOH@invalid?5string?5position?$AA@") #32
  unreachable
}

; Function Attrs: noreturn
declare dso_local void @"?_Xout_of_range@std@@YAXPEBD@Z"(ptr noundef) local_unnamed_addr #16

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #23

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #23

declare dso_local i32 @__stdio_common_vsprintf(i64 noundef, ptr noundef, i64 noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #6

; Function Attrs: mustprogress noinline nounwind sspstrong uwtable
define linkonce_odr dso_local ptr @__local_stdio_printf_options() local_unnamed_addr #24 comdat {
  ret ptr @"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA"
}

; Function Attrs: nofree nounwind
declare dso_local noundef i64 @fwrite(ptr noundef readonly captures(none), i64 noundef, i64 noundef, ptr noundef captures(none)) local_unnamed_addr #12

; Function Attrs: mustprogress sspstrong uwtable
define internal fastcc noundef nonnull align 8 dereferenceable(32) ptr @"?NameOf@?A0xB9C01504@opf@@YAAEBV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@PEBX_N@Z"(ptr noundef %0, i1 noundef zeroext %1) unnamed_addr #5 personality ptr @__C_specific_handler {
  %3 = alloca i1, align 1
  %4 = alloca i64, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca ptr, align 8
  %9 = alloca ptr, align 8
  %10 = alloca i32, align 4
  %11 = alloca ptr, align 8
  %12 = alloca i16, align 2
  %13 = alloca i64, align 8
  %14 = alloca i64, align 8
  %15 = alloca i16, align 2
  %16 = alloca i64, align 8
  %17 = alloca i8, align 1
  %18 = alloca i1, align 1
  %19 = alloca ptr, align 8
  %20 = alloca ptr, align 8
  %21 = alloca ptr, align 8
  %22 = alloca i1, align 1
  %23 = alloca ptr, align 8
  %24 = alloca i64, align 8
  %25 = alloca i32, align 4
  %26 = alloca i32, align 4
  %27 = alloca i32, align 4
  %28 = alloca ptr, align 8
  %29 = alloca i32, align 4
  %30 = alloca ptr, align 8
  %31 = alloca %struct._MEMORY_BASIC_INFORMATION, align 8
  %32 = alloca ptr, align 8
  %33 = alloca [160 x i8], align 16
  %34 = alloca i32, align 4
  %35 = alloca i32, align 4
  %36 = alloca %"struct.std::pair.44", align 8
  store ptr %0, ptr %32, align 8
  %37 = ptrtoint ptr %0 to i64
  %38 = and i64 %37, 255
  %39 = xor i64 %38, -3750763034362895579
  %40 = mul i64 %39, 1099511628211
  %41 = lshr i64 %37, 8
  %42 = and i64 %41, 255
  %43 = xor i64 %40, %42
  %44 = mul i64 %43, 1099511628211
  %45 = lshr i64 %37, 16
  %46 = and i64 %45, 255
  %47 = xor i64 %44, %46
  %48 = mul i64 %47, 1099511628211
  %49 = lshr i64 %37, 24
  %50 = and i64 %49, 255
  %51 = xor i64 %48, %50
  %52 = mul i64 %51, 1099511628211
  %53 = lshr i64 %37, 32
  %54 = and i64 %53, 255
  %55 = xor i64 %52, %54
  %56 = mul i64 %55, 1099511628211
  %57 = lshr i64 %37, 40
  %58 = and i64 %57, 255
  %59 = xor i64 %56, %58
  %60 = mul i64 %59, 1099511628211
  %61 = lshr i64 %37, 48
  %62 = and i64 %61, 255
  %63 = xor i64 %60, %62
  %64 = mul i64 %63, 1099511628211
  %65 = lshr i64 %37, 56
  %66 = xor i64 %64, %65
  %67 = mul i64 %66, 1099511628211
  %68 = load i64, ptr getelementptr inbounds nuw (i8, ptr @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A", i64 48), align 8, !noalias !44
  %69 = and i64 %67, %68
  %70 = load ptr, ptr getelementptr inbounds nuw (i8, ptr @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A", i64 24), align 8, !noalias !44
  %71 = shl i64 %69, 4
  %72 = getelementptr inbounds nuw i8, ptr %70, i64 %71
  %73 = getelementptr inbounds nuw i8, ptr %72, i64 8
  %74 = load ptr, ptr %73, align 8, !noalias !44
  %75 = load ptr, ptr getelementptr inbounds nuw (i8, ptr @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A", i64 8), align 8, !noalias !44
  %76 = icmp eq ptr %74, %75
  br i1 %76, label %94, label %77

77:                                               ; preds = %2
  %78 = load ptr, ptr %72, align 8, !noalias !44
  %79 = getelementptr inbounds nuw i8, ptr %74, i64 16
  %80 = load ptr, ptr %79, align 8, !noalias !44
  %81 = icmp eq ptr %0, %80
  br i1 %81, label %91, label %82

82:                                               ; preds = %77, %85
  %83 = phi ptr [ %87, %85 ], [ %74, %77 ]
  %84 = icmp eq ptr %83, %78
  br i1 %84, label %94, label %85

85:                                               ; preds = %82
  %86 = getelementptr inbounds nuw i8, ptr %83, i64 8
  %87 = load ptr, ptr %86, align 8, !noalias !44
  %88 = getelementptr inbounds nuw i8, ptr %87, i64 16
  %89 = load ptr, ptr %88, align 8, !noalias !44
  %90 = icmp eq ptr %0, %89
  br i1 %90, label %91, label %82, !llvm.loop !49

91:                                               ; preds = %85, %77
  %92 = phi ptr [ %74, %77 ], [ %87, %85 ]
  %93 = icmp eq ptr %92, %75
  br i1 %93, label %94, label %414

94:                                               ; preds = %82, %2, %91
  call void @llvm.lifetime.start.p0(i64 160, ptr nonnull %33) #30
  %95 = tail call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %96 = icmp eq ptr %0, null
  br i1 %96, label %97, label %98

97:                                               ; preds = %94
  store i16 45, ptr %33, align 16
  br label %412

98:                                               ; preds = %94
  br i1 %1, label %99, label %115

99:                                               ; preds = %98
  %100 = load ptr, ptr %95, align 8
  %101 = icmp ult ptr %0, %100
  br i1 %101, label %113, label %102

102:                                              ; preds = %99
  %103 = getelementptr inbounds nuw i8, ptr %95, i64 60
  %104 = load i32, ptr %103, align 4
  %105 = zext i32 %104 to i64
  %106 = getelementptr inbounds nuw i8, ptr %100, i64 %105
  %107 = icmp ult ptr %0, %106
  br i1 %107, label %108, label %113

108:                                              ; preds = %102
  %109 = ptrtoint ptr %100 to i64
  %110 = sub i64 %37, %109
  %111 = trunc i64 %110 to i32
  %112 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %33, i64 noundef 160, ptr noundef nonnull @"??_C@_0M@OAJNJFNP@vt?3exe?$CL0x?$CFX?$AA@", i32 noundef %111) #30
  br label %412

113:                                              ; preds = %102, %99
  %114 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %33, i64 noundef 160, ptr noundef nonnull @"??_C@_05BBDLBDLH@vt?3?$CFp?$AA@", ptr noundef nonnull %0) #30
  br label %412

115:                                              ; preds = %98
  %116 = load i1, ptr @"?g_poolSearched@?A0xB9C01504@opf@@3_NA", align 1
  br i1 %116, label %265, label %117

117:                                              ; preds = %115
  store i1 true, ptr @"?g_poolSearched@?A0xB9C01504@opf@@3_NA", align 1
  %118 = tail call noundef nonnull align 8 dereferenceable(64) ptr @"?Game@opf@@YAAEBUGameModule@1@XZ"()
  %119 = getelementptr inbounds nuw i8, ptr %118, i64 40
  %120 = load ptr, ptr %119, align 8
  %121 = getelementptr inbounds nuw i8, ptr %118, i64 48
  %122 = load ptr, ptr %121, align 8
  %123 = icmp ult ptr %120, %122
  br i1 %123, label %124, label %264

124:                                              ; preds = %117
  %125 = getelementptr inbounds nuw i8, ptr %31, i64 24
  %126 = getelementptr inbounds nuw i8, ptr %31, i64 36
  %127 = getelementptr inbounds nuw i8, ptr %31, i64 32
  br label %128

128:                                              ; preds = %254, %124
  %129 = phi ptr [ %120, %124 ], [ %136, %254 ]
  call void @llvm.lifetime.start.p0(i64 48, ptr nonnull %31) #30
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(48) %31, i8 0, i64 48, i1 false)
  %130 = call i64 @VirtualQuery(ptr noundef %129, ptr noundef nonnull %31, i64 noundef 48)
  %131 = icmp eq i64 %130, 0
  br i1 %131, label %132, label %133

132:                                              ; preds = %128
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %31) #30
  br label %264

133:                                              ; preds = %128
  %134 = load ptr, ptr %31, align 8
  %135 = load i64, ptr %125, align 8
  %136 = getelementptr inbounds nuw i8, ptr %134, i64 %135
  %137 = load i32, ptr %126, align 4
  %138 = load i32, ptr %127, align 8
  %139 = icmp eq i32 %138, 4096
  %140 = and i32 %137, 256
  %141 = icmp eq i32 %140, 0
  %142 = select i1 %139, i1 %141, i1 false
  br i1 %142, label %143, label %254

143:                                              ; preds = %133
  %144 = trunc i32 %137 to i8
  switch i8 %144, label %254 [
    i8 4, label %145
    i8 2, label %145
    i8 8, label %145
  ]

145:                                              ; preds = %143, %143, %143
  %146 = load ptr, ptr %119, align 8
  %147 = getelementptr inbounds nuw i8, ptr %146, i64 8
  %148 = icmp ult ptr %129, %147
  %149 = select i1 %148, ptr %147, ptr %129
  %150 = getelementptr inbounds nuw i8, ptr %149, i64 16
  %151 = icmp ugt ptr %150, %136
  br i1 %151, label %254, label %152

152:                                              ; preds = %145, %250
  %153 = phi ptr [ %252, %250 ], [ %150, %145 ]
  %154 = phi ptr [ %251, %250 ], [ %149, %145 ]
  %155 = load ptr, ptr %121, align 8
  %156 = icmp ugt ptr %153, %155
  br i1 %156, label %254, label %157

157:                                              ; preds = %152
  %158 = load i64, ptr %154, align 8
  %159 = trunc i64 %158 to i32
  %160 = add i32 %159, -8192
  %161 = icmp ult i32 %160, -8191
  %162 = icmp ult i64 %158, 4294967296
  %163 = or i1 %162, %161
  br i1 %163, label %250, label %164

164:                                              ; preds = %157
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %22)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %27)
  store ptr %154, ptr %23, align 8
  invoke void @llvm.seh.try.begin()
          to label %165 unwind label %237

165:                                              ; preds = %164
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %24)
  %166 = load volatile ptr, ptr %23, align 8
  %167 = load volatile i64, ptr %166, align 8
  store volatile i64 %167, ptr %24, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %25)
  %168 = load volatile i64, ptr %24, align 8
  %169 = trunc i64 %168 to i32
  store volatile i32 %169, ptr %25, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %26)
  %170 = load volatile i64, ptr %24, align 8
  %171 = lshr i64 %170, 32
  %172 = trunc nuw i64 %171 to i32
  store volatile i32 %172, ptr %26, align 4
  %173 = load volatile i32, ptr %25, align 4
  %174 = icmp eq i32 %173, 0
  br i1 %174, label %188, label %175

175:                                              ; preds = %165
  %176 = load volatile i32, ptr %25, align 4
  %177 = icmp ugt i32 %176, 8191
  br i1 %177, label %188, label %178

178:                                              ; preds = %175
  %179 = load volatile i32, ptr %26, align 4
  %180 = icmp eq i32 %179, 0
  br i1 %180, label %188, label %181

181:                                              ; preds = %178
  %182 = load volatile i32, ptr %26, align 4
  %183 = icmp ugt i32 %182, 262143
  br i1 %183, label %188, label %184

184:                                              ; preds = %181
  %185 = load volatile i32, ptr %26, align 4
  %186 = and i32 %185, 1
  %187 = icmp eq i32 %186, 0
  br i1 %187, label %190, label %188

188:                                              ; preds = %184, %181, %178, %175, %165
  store volatile i1 false, ptr %22, align 1
  store volatile i32 1, ptr %27, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  %189 = load volatile i32, ptr %27, align 4
  br label %249

190:                                              ; preds = %184
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %28)
  %191 = load volatile ptr, ptr %23, align 8
  %192 = getelementptr inbounds nuw i8, ptr %191, i64 8
  store volatile ptr %192, ptr %28, align 8
  %193 = load volatile ptr, ptr %28, align 8
  %194 = load volatile i32, ptr %25, align 4
  %195 = add i32 %194, 1
  %196 = zext i32 %195 to i64
  %197 = getelementptr inbounds nuw i64, ptr %193, i64 %196
  %198 = load volatile i64, ptr %197, align 8
  %199 = icmp eq i64 %198, 0
  br i1 %199, label %201, label %200

200:                                              ; preds = %190
  store volatile i1 false, ptr %22, align 1
  store volatile i32 1, ptr %27, align 4
  br label %243

201:                                              ; preds = %190
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %29)
  store volatile i32 0, ptr %29, align 4
  %202 = load volatile i32, ptr %29, align 4
  %203 = load volatile i32, ptr %25, align 4
  %204 = icmp ugt i32 %202, %203
  br i1 %204, label %219, label %205

205:                                              ; preds = %201, %213
  %206 = load volatile ptr, ptr %28, align 8
  %207 = load volatile i32, ptr %29, align 4
  %208 = zext i32 %207 to i64
  %209 = getelementptr inbounds nuw i64, ptr %206, i64 %208
  %210 = load volatile i64, ptr %209, align 8
  %211 = icmp ult i64 %210, 65537
  br i1 %211, label %212, label %213

212:                                              ; preds = %205
  store volatile i1 false, ptr %22, align 1
  br label %219

213:                                              ; preds = %205
  %214 = load volatile i32, ptr %29, align 4
  %215 = add i32 %214, 1
  store volatile i32 %215, ptr %29, align 4
  %216 = load volatile i32, ptr %29, align 4
  %217 = load volatile i32, ptr %25, align 4
  %218 = icmp ugt i32 %216, %217
  br i1 %218, label %219, label %205, !llvm.loop !50

219:                                              ; preds = %213, %212, %201
  %220 = phi i32 [ 1, %212 ], [ 3, %201 ], [ 3, %213 ]
  store volatile i32 %220, ptr %27, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %29)
  %221 = load volatile i32, ptr %27, align 4
  %222 = icmp eq i32 %221, 3
  br i1 %222, label %223, label %243

223:                                              ; preds = %219
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %30)
  %224 = load volatile ptr, ptr %28, align 8
  %225 = load volatile i64, ptr %224, align 8
  %226 = inttoptr i64 %225 to ptr
  store volatile ptr %226, ptr %30, align 8
  %227 = load volatile ptr, ptr %30, align 8
  %228 = load volatile i16, ptr %227, align 2
  %229 = and i16 %228, -64
  %230 = icmp eq i16 %229, 256
  br i1 %230, label %233, label %231

231:                                              ; preds = %223
  store volatile i1 false, ptr %22, align 1
  store volatile i32 1, ptr %27, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %28)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  %232 = load volatile i32, ptr %27, align 4
  br label %249

233:                                              ; preds = %223
  %234 = load volatile ptr, ptr %30, align 8
  %235 = getelementptr inbounds nuw i8, ptr %234, i64 2
  %236 = invoke i32 @memcmp(ptr noundef nonnull %235, ptr noundef nonnull @"??_C@_04OHJIHAFH@None?$AA@", i64 noundef 4) #34
          to label %245 unwind label %237

237:                                              ; preds = %233, %164
  %238 = catchswitch within none [label %239] unwind to caller

239:                                              ; preds = %237
  %240 = catchpad within %238 [ptr null]
  catchret from %240 to label %241

241:                                              ; preds = %239
  %242 = call i32 @llvm.eh.exceptioncode(token %240)
  br label %249

243:                                              ; preds = %219, %200
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %28)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  %244 = load volatile i32, ptr %27, align 4
  br label %249

245:                                              ; preds = %233
  %246 = freeze i32 %236
  %247 = icmp eq i32 %246, 0
  store volatile i1 %247, ptr %22, align 1
  store volatile i32 1, ptr %27, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %30)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %28)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %26)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %25)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %24)
  %248 = load volatile i32, ptr %27, align 4
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %22)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %27)
  br i1 %247, label %257, label %250

249:                                              ; preds = %243, %241, %231, %188
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %22)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %23)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %27)
  br label %250

250:                                              ; preds = %249, %245, %157
  %251 = getelementptr inbounds nuw i8, ptr %154, i64 8
  %252 = getelementptr inbounds nuw i8, ptr %154, i64 24
  %253 = icmp ugt ptr %252, %136
  br i1 %253, label %254, label %152, !llvm.loop !51

254:                                              ; preds = %250, %152, %145, %143, %133
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %31) #30
  %255 = load ptr, ptr %121, align 8
  %256 = icmp ult ptr %136, %255
  br i1 %256, label %128, label %264, !llvm.loop !52

257:                                              ; preds = %245
  %258 = getelementptr inbounds i8, ptr %154, i64 -8
  call void @llvm.lifetime.end.p0(i64 48, ptr nonnull %31) #30
  store ptr %258, ptr @"?g_pool@?A0xB9C01504@opf@@3PEBEEB", align 8
  %259 = load ptr, ptr %95, align 8
  %260 = ptrtoint ptr %258 to i64
  %261 = ptrtoint ptr %259 to i64
  %262 = sub i64 %260, %261
  %263 = trunc i64 %262 to i32
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0CD@KKPKGCCK@?$FLticksplit?$FN?5FName?5pool?5at?5exe?$CL0x@", i32 noundef %263)
  br label %265

264:                                              ; preds = %254, %117, %132
  store ptr null, ptr @"?g_pool@?A0xB9C01504@opf@@3PEBEEB", align 8
  call void (ptr, ...) @"?Log@opf@@YAXPEBDZZ"(ptr noundef nonnull @"??_C@_0DP@HKEOIGNE@?$FLticksplit?$FN?5FName?5pool?5not?5found@")
  br label %265

265:                                              ; preds = %257, %264, %115
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %34) #30
  store i32 0, ptr %34, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %35) #30
  store i32 0, ptr %35, align 4
  %266 = load ptr, ptr %32, align 8
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %18)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %21)
  store ptr %35, ptr %19, align 8
  store ptr %34, ptr %20, align 8
  store ptr %266, ptr %21, align 8
  invoke void @llvm.seh.try.begin()
          to label %273 unwind label %267

267:                                              ; preds = %265
  %268 = catchswitch within none [label %269] unwind to caller

269:                                              ; preds = %267
  %270 = catchpad within %268 [ptr null]
  catchret from %270 to label %271

271:                                              ; preds = %269
  %272 = call i32 @llvm.eh.exceptioncode(token %270)
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %18)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %21)
  br label %408

273:                                              ; preds = %265
  %274 = load volatile ptr, ptr %21, align 8
  %275 = getelementptr inbounds nuw i8, ptr %274, i64 24
  %276 = load volatile i32, ptr %275, align 4
  %277 = load volatile ptr, ptr %20, align 8
  store volatile i32 %276, ptr %277, align 4
  %278 = load volatile ptr, ptr %21, align 8
  %279 = getelementptr inbounds nuw i8, ptr %278, i64 28
  %280 = load volatile i32, ptr %279, align 4
  %281 = load volatile ptr, ptr %19, align 8
  store volatile i32 %280, ptr %281, align 4
  store volatile i1 true, ptr %18, align 1
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %18)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %19)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %20)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %21)
  %282 = load i32, ptr %35, align 4
  %283 = load i32, ptr %34, align 4
  %284 = load ptr, ptr @"?g_pool@?A0xB9C01504@opf@@3PEBEEB", align 8
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %3)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %6)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %10)
  store i64 160, ptr %4, align 8
  store ptr %33, ptr %5, align 8
  store i32 %282, ptr %6, align 4
  store i32 %283, ptr %7, align 4
  store ptr %284, ptr %8, align 8
  %285 = icmp eq ptr %284, null
  br i1 %285, label %403, label %286

286:                                              ; preds = %273
  invoke void @llvm.seh.try.begin()
          to label %287 unwind label %397

287:                                              ; preds = %286
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)
  %288 = load volatile ptr, ptr %8, align 8
  %289 = getelementptr inbounds nuw i8, ptr %288, i64 16
  %290 = load volatile i32, ptr %7, align 4
  %291 = lshr i32 %290, 13
  %292 = and i32 %291, 524280
  %293 = zext nneg i32 %292 to i64
  %294 = getelementptr inbounds nuw i8, ptr %289, i64 %293
  %295 = load volatile ptr, ptr %294, align 8
  store volatile ptr %295, ptr %9, align 8
  %296 = load volatile ptr, ptr %9, align 8
  %297 = icmp eq ptr %296, null
  br i1 %297, label %298, label %300

298:                                              ; preds = %287
  store volatile i1 false, ptr %3, align 1
  store volatile i32 1, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  %299 = load volatile i32, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10)
  br label %408

300:                                              ; preds = %287
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %11)
  %301 = load volatile ptr, ptr %9, align 8
  %302 = load volatile i32, ptr %7, align 4
  %303 = shl i32 %302, 1
  %304 = and i32 %303, 131070
  %305 = zext nneg i32 %304 to i64
  %306 = getelementptr inbounds nuw i8, ptr %301, i64 %305
  store volatile ptr %306, ptr %11, align 8
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %12)
  %307 = load volatile ptr, ptr %11, align 8
  %308 = load volatile i16, ptr %307, align 2
  store volatile i16 %308, ptr %12, align 2
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %13)
  %309 = load volatile i16, ptr %12, align 2
  %310 = lshr i16 %309, 6
  %311 = zext nneg i16 %310 to i64
  store volatile i64 %311, ptr %13, align 8
  %312 = load volatile i64, ptr %13, align 8
  %313 = icmp eq i64 %312, 0
  br i1 %313, label %406, label %314

314:                                              ; preds = %300
  %315 = load volatile i64, ptr %13, align 8
  %316 = load volatile i64, ptr %4, align 8
  %317 = add i64 %316, -12
  %318 = icmp ult i64 %315, %317
  br i1 %318, label %319, label %406

319:                                              ; preds = %314
  %320 = load volatile i16, ptr %12, align 2
  %321 = and i16 %320, 1
  %322 = icmp eq i16 %321, 0
  br i1 %322, label %352, label %323

323:                                              ; preds = %319
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %14)
  store volatile i64 0, ptr %14, align 8
  %324 = load volatile i64, ptr %14, align 8
  %325 = load volatile i64, ptr %13, align 8
  %326 = icmp ult i64 %324, %325
  br i1 %326, label %328, label %327

327:                                              ; preds = %342, %323
  store volatile i32 3, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %14)
  br label %380

328:                                              ; preds = %323, %342
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %15)
  %329 = load volatile ptr, ptr %11, align 8
  %330 = getelementptr inbounds nuw i8, ptr %329, i64 2
  %331 = load volatile i64, ptr %14, align 8
  %332 = getelementptr inbounds nuw i16, ptr %330, i64 %331
  %333 = load volatile i16, ptr %332, align 2
  store volatile i16 %333, ptr %15, align 2
  %334 = load volatile i16, ptr %15, align 2
  %335 = icmp ult i16 %334, 128
  br i1 %335, label %336, label %342

336:                                              ; preds = %328
  %337 = load volatile i16, ptr %15, align 2
  %338 = icmp ugt i16 %337, 31
  br i1 %338, label %339, label %342

339:                                              ; preds = %336
  %340 = load volatile i16, ptr %15, align 2
  %341 = trunc i16 %340 to i8
  br label %342

342:                                              ; preds = %339, %336, %328
  %343 = phi i8 [ %341, %339 ], [ 63, %336 ], [ 63, %328 ]
  %344 = load volatile ptr, ptr %5, align 8
  %345 = load volatile i64, ptr %14, align 8
  %346 = getelementptr inbounds nuw i8, ptr %344, i64 %345
  store volatile i8 %343, ptr %346, align 1
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %15)
  %347 = load volatile i64, ptr %14, align 8
  %348 = add i64 %347, 1
  store volatile i64 %348, ptr %14, align 8
  %349 = load volatile i64, ptr %14, align 8
  %350 = load volatile i64, ptr %13, align 8
  %351 = icmp ult i64 %349, %350
  br i1 %351, label %328, label %327, !llvm.loop !53

352:                                              ; preds = %319
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %16)
  store volatile i64 0, ptr %16, align 8
  %353 = load volatile i64, ptr %16, align 8
  %354 = load volatile i64, ptr %13, align 8
  %355 = icmp ult i64 %353, %354
  br i1 %355, label %357, label %356

356:                                              ; preds = %370, %352
  store volatile i32 6, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %16)
  br label %380

357:                                              ; preds = %352, %370
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %17)
  %358 = load volatile ptr, ptr %11, align 8
  %359 = getelementptr inbounds nuw i8, ptr %358, i64 2
  %360 = load volatile i64, ptr %16, align 8
  %361 = getelementptr inbounds nuw i8, ptr %359, i64 %360
  %362 = load volatile i8, ptr %361, align 1
  store volatile i8 %362, ptr %17, align 1
  %363 = load volatile i8, ptr %17, align 1
  %364 = icmp sgt i8 %363, 31
  br i1 %364, label %365, label %370

365:                                              ; preds = %357
  %366 = load volatile i8, ptr %17, align 1
  %367 = icmp eq i8 %366, 44
  br i1 %367, label %370, label %368

368:                                              ; preds = %365
  %369 = load volatile i8, ptr %17, align 1
  br label %370

370:                                              ; preds = %368, %365, %357
  %371 = phi i8 [ %369, %368 ], [ 63, %365 ], [ 63, %357 ]
  %372 = load volatile ptr, ptr %5, align 8
  %373 = load volatile i64, ptr %16, align 8
  %374 = getelementptr inbounds nuw i8, ptr %372, i64 %373
  store volatile i8 %371, ptr %374, align 1
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %17)
  %375 = load volatile i64, ptr %16, align 8
  %376 = add i64 %375, 1
  store volatile i64 %376, ptr %16, align 8
  %377 = load volatile i64, ptr %16, align 8
  %378 = load volatile i64, ptr %13, align 8
  %379 = icmp ult i64 %377, %378
  br i1 %379, label %357, label %356, !llvm.loop !54

380:                                              ; preds = %356, %327
  %381 = load volatile i32, ptr %10, align 4
  %382 = load volatile ptr, ptr %5, align 8
  %383 = load volatile i64, ptr %13, align 8
  %384 = getelementptr inbounds nuw i8, ptr %382, i64 %383
  store volatile i8 0, ptr %384, align 1
  %385 = load volatile i32, ptr %6, align 4
  %386 = icmp eq i32 %385, 0
  br i1 %386, label %404, label %387

387:                                              ; preds = %380
  %388 = load volatile i32, ptr %6, align 4
  %389 = add i32 %388, -1
  %390 = load volatile i64, ptr %4, align 8
  %391 = load volatile i64, ptr %13, align 8
  %392 = sub i64 %390, %391
  %393 = load volatile ptr, ptr %5, align 8
  %394 = load volatile i64, ptr %13, align 8
  %395 = getelementptr inbounds nuw i8, ptr %393, i64 %394
  %396 = invoke i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef %395, i64 noundef %392, ptr noundef nonnull @"??_C@_03CBBLDGKP@_?$CFu?$AA@", i32 noundef %389) #36
          to label %404 unwind label %397

397:                                              ; preds = %387, %286
  %398 = catchswitch within none [label %399] unwind to caller

399:                                              ; preds = %397
  %400 = catchpad within %398 [ptr null]
  catchret from %400 to label %401

401:                                              ; preds = %399
  %402 = call i32 @llvm.eh.exceptioncode(token %400)
  br label %403

403:                                              ; preds = %401, %273
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10)
  br label %408

404:                                              ; preds = %387, %380
  store volatile i1 true, ptr %3, align 1
  store volatile i32 1, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %12)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  %405 = load volatile i32, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10)
  br label %411

406:                                              ; preds = %300, %314
  store volatile i1 false, ptr %3, align 1
  store volatile i32 1, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %13)
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %12)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %11)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)
  %407 = load volatile i32, ptr %10, align 4
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %3)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %6)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %8)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %10)
  br label %408

408:                                              ; preds = %406, %298, %403, %271
  %409 = load ptr, ptr %32, align 8
  %410 = call i32 (ptr, i64, ptr, ...) @snprintf(ptr noundef nonnull dereferenceable(1) %33, i64 noundef 160, ptr noundef nonnull @"??_C@_06JHKGMGPP@cls?3?$CFp?$AA@", ptr noundef %409) #30
  br label %411

411:                                              ; preds = %404, %408
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %35) #30
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %34) #30
  br label %412

412:                                              ; preds = %108, %113, %411, %97
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %36) #30
  call void @"??$emplace@AEAPEBXAEAY0KA@D@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AU?$pair@V?$_List_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@_N@1@AEAPEBXAEAY0KA@D@Z"(ptr noundef nonnull align 8 dereferenceable(64) @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A", ptr dead_on_unwind nonnull writable sret(%"struct.std::pair.44") align 8 %36, ptr noundef nonnull align 8 dereferenceable(8) %32, ptr noundef nonnull align 1 dereferenceable(160) %33)
  %413 = load ptr, ptr %36, align 8
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %36) #30
  call void @llvm.lifetime.end.p0(i64 160, ptr nonnull %33) #30
  br label %414

414:                                              ; preds = %91, %412
  %415 = phi ptr [ %413, %412 ], [ %92, %91 ]
  %416 = getelementptr inbounds nuw i8, ptr %415, i64 24
  ret ptr %416
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local void @"??$emplace@AEAPEBXAEAY0KA@D@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AU?$pair@V?$_List_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@_N@1@AEAPEBXAEAY0KA@D@Z"(ptr noundef nonnull align 8 dereferenceable(64) %0, ptr dead_on_unwind noalias writable sret(%"struct.std::pair.44") align 8 %1, ptr noundef nonnull align 8 dereferenceable(8) %2, ptr noundef nonnull align 1 dereferenceable(160) %3) local_unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  %5 = alloca %"struct.std::_List_node_emplace_op2", align 8
  %6 = load i8, ptr %2, align 8
  %7 = zext i8 %6 to i64
  %8 = xor i64 %7, -3750763034362895579
  %9 = mul i64 %8, 1099511628211
  %10 = getelementptr inbounds nuw i8, ptr %2, i64 1
  %11 = load i8, ptr %10, align 1
  %12 = zext i8 %11 to i64
  %13 = xor i64 %9, %12
  %14 = mul i64 %13, 1099511628211
  %15 = getelementptr inbounds nuw i8, ptr %2, i64 2
  %16 = load i8, ptr %15, align 2
  %17 = zext i8 %16 to i64
  %18 = xor i64 %14, %17
  %19 = mul i64 %18, 1099511628211
  %20 = getelementptr inbounds nuw i8, ptr %2, i64 3
  %21 = load i8, ptr %20, align 1
  %22 = zext i8 %21 to i64
  %23 = xor i64 %19, %22
  %24 = mul i64 %23, 1099511628211
  %25 = getelementptr inbounds nuw i8, ptr %2, i64 4
  %26 = load i8, ptr %25, align 4
  %27 = zext i8 %26 to i64
  %28 = xor i64 %24, %27
  %29 = mul i64 %28, 1099511628211
  %30 = getelementptr inbounds nuw i8, ptr %2, i64 5
  %31 = load i8, ptr %30, align 1
  %32 = zext i8 %31 to i64
  %33 = xor i64 %29, %32
  %34 = mul i64 %33, 1099511628211
  %35 = getelementptr inbounds nuw i8, ptr %2, i64 6
  %36 = load i8, ptr %35, align 2
  %37 = zext i8 %36 to i64
  %38 = xor i64 %34, %37
  %39 = mul i64 %38, 1099511628211
  %40 = getelementptr inbounds nuw i8, ptr %2, i64 7
  %41 = load i8, ptr %40, align 1
  %42 = zext i8 %41 to i64
  %43 = xor i64 %39, %42
  %44 = mul i64 %43, 1099511628211
  %45 = getelementptr inbounds nuw i8, ptr %0, i64 48
  %46 = load i64, ptr %45, align 8, !noalias !55
  %47 = and i64 %44, %46
  %48 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %49 = load ptr, ptr %48, align 8, !noalias !55
  %50 = shl i64 %47, 4
  %51 = getelementptr inbounds nuw i8, ptr %49, i64 %50
  %52 = getelementptr inbounds nuw i8, ptr %51, i64 8
  %53 = load ptr, ptr %52, align 8, !noalias !55
  %54 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %55 = load ptr, ptr %54, align 8, !noalias !55
  %56 = icmp eq ptr %53, %55
  br i1 %56, label %76, label %57

57:                                               ; preds = %4
  %58 = load ptr, ptr %51, align 8, !noalias !55
  %59 = load ptr, ptr %2, align 8, !noalias !55
  %60 = getelementptr inbounds nuw i8, ptr %53, i64 16
  %61 = load ptr, ptr %60, align 8, !noalias !55
  %62 = icmp eq ptr %59, %61
  br i1 %62, label %72, label %63

63:                                               ; preds = %57, %66
  %64 = phi ptr [ %68, %66 ], [ %53, %57 ]
  %65 = icmp eq ptr %64, %58
  br i1 %65, label %76, label %66

66:                                               ; preds = %63
  %67 = getelementptr inbounds nuw i8, ptr %64, i64 8
  %68 = load ptr, ptr %67, align 8, !noalias !55
  %69 = getelementptr inbounds nuw i8, ptr %68, i64 16
  %70 = load ptr, ptr %69, align 8, !noalias !55
  %71 = icmp eq ptr %59, %70
  br i1 %71, label %72, label %63, !llvm.loop !49

72:                                               ; preds = %66, %57
  %73 = phi ptr [ %53, %57 ], [ %68, %66 ]
  %74 = ptrtoint ptr %73 to i64
  store i64 %74, ptr %1, align 8
  %75 = getelementptr inbounds nuw i8, ptr %1, i64 8
  store i8 0, ptr %75, align 8
  br label %199

76:                                               ; preds = %63, %4
  %77 = phi ptr [ %55, %4 ], [ %64, %63 ]
  %78 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %79 = load i64, ptr %78, align 8
  %80 = icmp eq i64 %79, 329406144173384850
  br i1 %80, label %81, label %82

81:                                               ; preds = %76
  tail call void @"?_Xlength_error@std@@YAXPEBD@Z"(ptr noundef nonnull @"??_C@_0BL@GOIGLPKN@unordered_map?1set?5too?5long?$AA@") #32
  unreachable

82:                                               ; preds = %76
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #30
  store ptr %54, ptr %5, align 8
  %83 = getelementptr inbounds nuw i8, ptr %5, i64 8
  invoke void @llvm.seh.scope.begin()
          to label %84 unwind label %96

84:                                               ; preds = %82
  %85 = invoke noalias noundef nonnull dereferenceable(56) ptr @"??2@YAPEAX_K@Z"(i64 noundef 56) #33
          to label %86 unwind label %96

86:                                               ; preds = %84
  store ptr %85, ptr %83, align 8
  %87 = getelementptr inbounds nuw i8, ptr %85, i64 16
  %88 = load ptr, ptr %2, align 8
  store ptr %88, ptr %87, align 8
  %89 = getelementptr inbounds nuw i8, ptr %85, i64 24
  %90 = invoke noundef ptr @"??0?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@QEBD@Z"(ptr noundef nonnull align 8 dereferenceable(32) %89, ptr noundef nonnull align 1 dereferenceable(160) %3)
          to label %91 unwind label %96

91:                                               ; preds = %86
  invoke void @llvm.seh.scope.begin()
          to label %92 unwind label %93

92:                                               ; preds = %91
  invoke void @llvm.seh.scope.end()
          to label %95 unwind label %93

93:                                               ; preds = %92, %91
  %94 = cleanuppad within none []
  call void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %89) #30 [ "funclet"(token %94) ]
  cleanupret from %94 unwind label %96

95:                                               ; preds = %92
  invoke void @llvm.seh.scope.end()
          to label %102 unwind label %96

96:                                               ; preds = %95, %93, %86, %84, %82
  %97 = phi ptr [ %85, %95 ], [ %85, %93 ], [ %85, %86 ], [ null, %84 ], [ null, %82 ]
  %98 = cleanuppad within none []
  %99 = icmp eq ptr %97, null
  br i1 %99, label %101, label %100

100:                                              ; preds = %96
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %97, i64 noundef 56) #30 [ "funclet"(token %98) ]
  br label %101

101:                                              ; preds = %100, %96
  cleanupret from %98 unwind to caller

102:                                              ; preds = %95
  invoke void @llvm.seh.scope.begin()
          to label %103 unwind label %197

103:                                              ; preds = %102
  %104 = load i64, ptr %78, align 8
  %105 = add i64 %104, 1
  %106 = load float, ptr %0, align 8
  %107 = uitofp i64 %105 to float
  %108 = getelementptr inbounds nuw i8, ptr %0, i64 56
  %109 = load i64, ptr %108, align 8
  %110 = uitofp i64 %109 to float
  %111 = fdiv float %107, %110
  %112 = fcmp olt float %106, %111
  br i1 %112, label %113, label %154

113:                                              ; preds = %103
  %114 = fdiv float %107, %106
  %115 = tail call float @llvm.ceil.f32(float %114)
  %116 = fptoui float %115 to i64
  %117 = tail call i64 @llvm.umax.i64(i64 %116, i64 8)
  %118 = icmp ult i64 %109, %117
  br i1 %118, label %119, label %124

119:                                              ; preds = %113
  %120 = icmp ugt i64 %109, 511
  %121 = shl nuw nsw i64 %109, 3
  %122 = tail call i64 @llvm.umax.i64(i64 %121, i64 %117)
  %123 = select i1 %120, i64 %117, i64 %122
  br label %124

124:                                              ; preds = %119, %113
  %125 = phi i64 [ %109, %113 ], [ %123, %119 ]
  invoke void @"?_Forced_rehash@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAAX_K@Z"(ptr noundef nonnull align 8 dereferenceable(64) %0, i64 noundef %125)
          to label %126 unwind label %197

126:                                              ; preds = %124
  %127 = load i64, ptr %45, align 8, !noalias !58
  %128 = and i64 %127, %44
  %129 = load ptr, ptr %48, align 8, !noalias !58
  %130 = shl i64 %128, 4
  %131 = getelementptr inbounds nuw i8, ptr %129, i64 %130
  %132 = getelementptr inbounds nuw i8, ptr %131, i64 8
  %133 = load ptr, ptr %132, align 8, !noalias !58
  %134 = load ptr, ptr %54, align 8, !noalias !58
  %135 = icmp eq ptr %133, %134
  br i1 %135, label %154, label %136

136:                                              ; preds = %126
  %137 = load ptr, ptr %131, align 8, !noalias !58
  %138 = load ptr, ptr %87, align 8, !noalias !58
  %139 = getelementptr inbounds nuw i8, ptr %133, i64 16
  %140 = load ptr, ptr %139, align 8, !noalias !58
  %141 = icmp eq ptr %138, %140
  br i1 %141, label %142, label %145

142:                                              ; preds = %148, %136
  %143 = phi ptr [ %133, %136 ], [ %150, %148 ]
  %144 = load ptr, ptr %143, align 8, !noalias !58
  br label %154

145:                                              ; preds = %136, %148
  %146 = phi ptr [ %150, %148 ], [ %133, %136 ]
  %147 = icmp eq ptr %146, %137
  br i1 %147, label %154, label %148

148:                                              ; preds = %145
  %149 = getelementptr inbounds nuw i8, ptr %146, i64 8
  %150 = load ptr, ptr %149, align 8, !noalias !58
  %151 = getelementptr inbounds nuw i8, ptr %150, i64 16
  %152 = load ptr, ptr %151, align 8, !noalias !58
  %153 = icmp eq ptr %138, %152
  br i1 %153, label %142, label %145, !llvm.loop !49

154:                                              ; preds = %145, %142, %126, %103
  %155 = phi ptr [ %77, %103 ], [ %144, %142 ], [ %134, %126 ], [ %146, %145 ]
  store ptr null, ptr %83, align 8
  %156 = getelementptr inbounds nuw i8, ptr %155, i64 8
  %157 = load ptr, ptr %156, align 8
  %158 = load i64, ptr %78, align 8
  %159 = add i64 %158, 1
  store i64 %159, ptr %78, align 8
  store ptr %155, ptr %85, align 8
  %160 = getelementptr inbounds nuw i8, ptr %85, i64 8
  store ptr %157, ptr %160, align 8
  store ptr %85, ptr %157, align 8
  store ptr %85, ptr %156, align 8
  %161 = load ptr, ptr %54, align 8
  %162 = load ptr, ptr %48, align 8
  %163 = load i64, ptr %45, align 8
  %164 = and i64 %163, %44
  %165 = shl i64 %164, 4
  %166 = getelementptr inbounds nuw i8, ptr %162, i64 %165
  %167 = getelementptr inbounds nuw i8, ptr %166, i64 8
  %168 = load ptr, ptr %166, align 8
  %169 = icmp eq ptr %168, %161
  br i1 %169, label %170, label %171

170:                                              ; preds = %154
  store ptr %85, ptr %166, align 8
  store ptr %85, ptr %167, align 8
  br label %178

171:                                              ; preds = %154
  %172 = icmp eq ptr %168, %155
  br i1 %172, label %173, label %174

173:                                              ; preds = %171
  store ptr %85, ptr %166, align 8
  br label %178

174:                                              ; preds = %171
  %175 = load ptr, ptr %167, align 8
  %176 = icmp eq ptr %175, %157
  br i1 %176, label %177, label %178

177:                                              ; preds = %174
  store ptr %85, ptr %167, align 8
  br label %178

178:                                              ; preds = %170, %173, %174, %177
  %179 = ptrtoint ptr %85 to i64
  store i64 %179, ptr %1, align 8
  %180 = getelementptr inbounds nuw i8, ptr %1, i64 8
  store i8 1, ptr %180, align 8
  invoke void @llvm.seh.scope.end()
          to label %181 unwind label %197

181:                                              ; preds = %178
  invoke void @llvm.seh.scope.begin()
          to label %182 unwind label %190

182:                                              ; preds = %181
  %183 = load ptr, ptr %83, align 8
  %184 = icmp eq ptr %183, null
  br i1 %184, label %187, label %185

185:                                              ; preds = %182
  %186 = getelementptr inbounds nuw i8, ptr %183, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %186) #30
  br label %187

187:                                              ; preds = %185, %182
  invoke void @llvm.seh.scope.end()
          to label %188 unwind label %190

188:                                              ; preds = %187
  br i1 %184, label %196, label %189

189:                                              ; preds = %188
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %183, i64 noundef 56) #30
  br label %196

190:                                              ; preds = %187, %181
  %191 = cleanuppad within none []
  %192 = load ptr, ptr %83, align 8
  %193 = icmp eq ptr %192, null
  br i1 %193, label %195, label %194

194:                                              ; preds = %190
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %192, i64 noundef 56) #30 [ "funclet"(token %191) ]
  br label %195

195:                                              ; preds = %194, %190
  cleanupret from %191 unwind to caller

196:                                              ; preds = %188, %189
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #30
  br label %199

197:                                              ; preds = %124, %178, %102
  %198 = cleanuppad within none []
  call void @"??1?$_List_node_emplace_op2@V?$allocator@U?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(16) %5) #30 [ "funclet"(token %198) ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #30
  cleanupret from %198 unwind to caller

199:                                              ; preds = %196, %72
  ret void
}

declare dllimport i64 @VirtualQuery(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: read)
declare dso_local i32 @memcmp(ptr noundef captures(none), ptr noundef captures(none), i64 noundef) local_unnamed_addr #19

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1?$_List_node_emplace_op2@V?$allocator@U?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(16) %0) unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  invoke void @llvm.seh.scope.begin()
          to label %2 unwind label %14

2:                                                ; preds = %1
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = icmp eq ptr %4, null
  br i1 %5, label %8, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds nuw i8, ptr %4, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %7) #30
  br label %8

8:                                                ; preds = %6, %2
  invoke void @llvm.seh.scope.end()
          to label %9 unwind label %14

9:                                                ; preds = %8
  %10 = load ptr, ptr %3, align 8
  %11 = icmp eq ptr %10, null
  br i1 %11, label %13, label %12

12:                                               ; preds = %9
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %10, i64 noundef 56) #30
  br label %13

13:                                               ; preds = %9, %12
  ret void

14:                                               ; preds = %8, %1
  %15 = cleanuppad within none []
  %16 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %17 = load ptr, ptr %16, align 8
  %18 = icmp eq ptr %17, null
  br i1 %18, label %20, label %19

19:                                               ; preds = %14
  call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %17, i64 noundef 56) #30 [ "funclet"(token %15) ]
  br label %20

20:                                               ; preds = %14, %19
  cleanupret from %15 unwind to caller
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@QEBD@Z"(ptr noundef nonnull returned align 8 dereferenceable(32) %0, ptr noundef %1) unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(32) %0, i8 0, i64 32, i1 false)
  invoke void @llvm.seh.scope.begin()
          to label %3 unwind label %37

3:                                                ; preds = %2
  %4 = tail call noundef i64 @strlen(ptr noundef nonnull dereferenceable(1) %1) #30
  %5 = icmp slt i64 %4, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  invoke void @"?_Xlen_string@std@@YAXXZ"() #32
          to label %7 unwind label %37

7:                                                ; preds = %6
  unreachable

8:                                                ; preds = %3
  %9 = icmp samesign ult i64 %4, 16
  br i1 %9, label %10, label %14

10:                                               ; preds = %8
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %4, ptr %11, align 8
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 15, ptr %12, align 8
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(32) %0, ptr nonnull align 1 %1, i64 %4, i1 false)
  %13 = getelementptr inbounds nuw [16 x i8], ptr %0, i64 0, i64 %4
  store i8 0, ptr %13, align 1
  br label %35

14:                                               ; preds = %8
  %15 = or i64 %4, 15
  %16 = tail call i64 @llvm.umax.i64(i64 %15, i64 22)
  %17 = icmp samesign ugt i64 %15, 4094
  br i1 %17, label %18, label %27

18:                                               ; preds = %14
  %19 = add nuw i64 %16, 40
  %20 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %19) #33
          to label %21 unwind label %37

21:                                               ; preds = %18
  %22 = ptrtoint ptr %20 to i64
  %23 = add i64 %22, 39
  %24 = and i64 %23, -32
  %25 = inttoptr i64 %24 to ptr
  %26 = getelementptr inbounds i8, ptr %25, i64 -8
  store i64 %22, ptr %26, align 8
  br label %30

27:                                               ; preds = %14
  %28 = add nuw nsw i64 %16, 1
  %29 = invoke noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %28) #33
          to label %30 unwind label %37

30:                                               ; preds = %27, %21
  %31 = phi ptr [ %25, %21 ], [ %29, %27 ]
  store ptr %31, ptr %0, align 8
  %32 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %4, ptr %32, align 8
  %33 = getelementptr inbounds nuw i8, ptr %0, i64 24
  store i64 %16, ptr %33, align 8
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 1 %31, ptr nonnull align 1 %1, i64 %4, i1 false)
  %34 = getelementptr inbounds nuw i8, ptr %31, i64 %4
  store i8 0, ptr %34, align 1
  br label %35

35:                                               ; preds = %30, %10
  invoke void @llvm.seh.scope.end()
          to label %36 unwind label %37

36:                                               ; preds = %35
  ret ptr %0

37:                                               ; preds = %27, %18, %6, %35, %2
  %38 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %38 unwind to caller
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local void @"?_Forced_rehash@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAAX_K@Z"(ptr noundef nonnull align 8 dereferenceable(64) %0, i64 noundef %1) local_unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  %3 = alloca %"struct.std::_Hash<std::_Umap_traits<const void *, std::basic_string<char>, std::_Uhash_compare<const void *, std::hash<const void *>, std::equal_to<const void *>>, std::allocator<std::pair<const void *const, std::basic_string<char>>>, false>>::_Clear_guard", align 8
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %5 = icmp ugt i64 %1, 576460752303423488
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  tail call void @"?_Xlength_error@std@@YAXPEBD@Z"(ptr noundef nonnull @"??_C@_0BK@OGNNAFAB@invalid?5hash?5bucket?5count?$AA@") #32
  unreachable

7:                                                ; preds = %2
  %8 = add nsw i64 %1, -1
  %9 = or i64 %8, 1
  %10 = tail call range(i64 0, 64) i64 @llvm.ctlz.i64(i64 %9, i1 true)
  %11 = sub nuw nsw i64 64, %10
  %12 = shl nuw i64 1, %11
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %14 = load ptr, ptr %13, align 8, !noalias !61
  %15 = shl i64 2, %11
  %16 = ptrtoint ptr %14 to i64
  tail call void @"?_Assign_grow@?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAAX_KV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@@Z"(ptr noundef nonnull align 8 dereferenceable(24) %4, i64 noundef %15, i64 %16)
  %17 = add i64 %12, -1
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 48
  store i64 %17, ptr %18, align 8
  %19 = getelementptr inbounds nuw i8, ptr %0, i64 56
  store i64 %12, ptr %19, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #30
  store ptr %0, ptr %3, align 8
  invoke void @llvm.seh.scope.begin()
          to label %20 unwind label %125

20:                                               ; preds = %7
  %21 = load ptr, ptr %13, align 8, !noalias !66
  %22 = load ptr, ptr %21, align 8, !noalias !66
  %23 = icmp eq ptr %22, %14
  br i1 %23, label %24, label %25

24:                                               ; preds = %122, %20
  store ptr null, ptr %3, align 8
  invoke void @llvm.seh.scope.end()
          to label %124 unwind label %125

25:                                               ; preds = %20, %122
  %26 = phi ptr [ %27, %122 ], [ %22, %20 ]
  %27 = load ptr, ptr %26, align 8
  %28 = getelementptr inbounds nuw i8, ptr %26, i64 16
  %29 = load i8, ptr %28, align 1
  %30 = zext i8 %29 to i64
  %31 = xor i64 %30, -3750763034362895579
  %32 = mul i64 %31, 1099511628211
  %33 = getelementptr inbounds nuw i8, ptr %26, i64 17
  %34 = load i8, ptr %33, align 1
  %35 = zext i8 %34 to i64
  %36 = xor i64 %32, %35
  %37 = mul i64 %36, 1099511628211
  %38 = getelementptr inbounds nuw i8, ptr %26, i64 18
  %39 = load i8, ptr %38, align 1
  %40 = zext i8 %39 to i64
  %41 = xor i64 %37, %40
  %42 = mul i64 %41, 1099511628211
  %43 = getelementptr inbounds nuw i8, ptr %26, i64 19
  %44 = load i8, ptr %43, align 1
  %45 = zext i8 %44 to i64
  %46 = xor i64 %42, %45
  %47 = mul i64 %46, 1099511628211
  %48 = getelementptr inbounds nuw i8, ptr %26, i64 20
  %49 = load i8, ptr %48, align 1
  %50 = zext i8 %49 to i64
  %51 = xor i64 %47, %50
  %52 = mul i64 %51, 1099511628211
  %53 = getelementptr inbounds nuw i8, ptr %26, i64 21
  %54 = load i8, ptr %53, align 1
  %55 = zext i8 %54 to i64
  %56 = xor i64 %52, %55
  %57 = mul i64 %56, 1099511628211
  %58 = getelementptr inbounds nuw i8, ptr %26, i64 22
  %59 = load i8, ptr %58, align 1
  %60 = zext i8 %59 to i64
  %61 = xor i64 %57, %60
  %62 = mul i64 %61, 1099511628211
  %63 = getelementptr inbounds nuw i8, ptr %26, i64 23
  %64 = load i8, ptr %63, align 1
  %65 = zext i8 %64 to i64
  %66 = xor i64 %62, %65
  %67 = mul i64 %66, 1099511628211
  %68 = load i64, ptr %18, align 8
  %69 = and i64 %67, %68
  %70 = load ptr, ptr %4, align 8
  %71 = shl i64 %69, 4
  %72 = getelementptr inbounds nuw i8, ptr %70, i64 %71
  %73 = getelementptr inbounds nuw i8, ptr %72, i64 8
  %74 = load ptr, ptr %72, align 8
  %75 = icmp eq ptr %74, %14
  br i1 %75, label %76, label %78

76:                                               ; preds = %25
  %77 = ptrtoint ptr %26 to i64
  store i64 %77, ptr %72, align 8
  store i64 %77, ptr %73, align 8
  br label %122

78:                                               ; preds = %25
  %79 = load i64, ptr %73, align 8
  %80 = inttoptr i64 %79 to ptr
  %81 = getelementptr inbounds nuw i8, ptr %80, i64 16
  %82 = load ptr, ptr %28, align 8
  %83 = load ptr, ptr %81, align 8
  %84 = icmp eq ptr %82, %83
  br i1 %84, label %85, label %97

85:                                               ; preds = %78
  %86 = load ptr, ptr %80, align 8
  %87 = icmp eq ptr %86, %26
  br i1 %87, label %95, label %88

88:                                               ; preds = %85
  %89 = getelementptr inbounds nuw i8, ptr %26, i64 8
  %90 = load ptr, ptr %89, align 8
  store ptr %27, ptr %90, align 8
  %91 = getelementptr inbounds nuw i8, ptr %27, i64 8
  %92 = load ptr, ptr %91, align 8
  store ptr %86, ptr %92, align 8
  %93 = getelementptr inbounds nuw i8, ptr %86, i64 8
  %94 = load ptr, ptr %93, align 8
  store ptr %26, ptr %94, align 8
  store ptr %92, ptr %93, align 8
  store ptr %90, ptr %91, align 8
  store ptr %94, ptr %89, align 8
  br label %95

95:                                               ; preds = %88, %85
  %96 = ptrtoint ptr %26 to i64
  store i64 %96, ptr %73, align 8
  br label %122

97:                                               ; preds = %78, %108
  %98 = phi ptr [ %110, %108 ], [ %80, %78 ]
  %99 = icmp eq ptr %74, %98
  br i1 %99, label %100, label %108

100:                                              ; preds = %97
  %101 = getelementptr inbounds nuw i8, ptr %26, i64 8
  %102 = load ptr, ptr %101, align 8
  store ptr %27, ptr %102, align 8
  %103 = getelementptr inbounds nuw i8, ptr %27, i64 8
  %104 = load ptr, ptr %103, align 8
  store ptr %98, ptr %104, align 8
  %105 = getelementptr inbounds nuw i8, ptr %98, i64 8
  %106 = load ptr, ptr %105, align 8
  store ptr %26, ptr %106, align 8
  store ptr %104, ptr %105, align 8
  store ptr %102, ptr %103, align 8
  store ptr %106, ptr %101, align 8
  %107 = ptrtoint ptr %26 to i64
  store i64 %107, ptr %72, align 8
  br label %122

108:                                              ; preds = %97
  %109 = getelementptr inbounds nuw i8, ptr %98, i64 8
  %110 = load ptr, ptr %109, align 8
  %111 = getelementptr inbounds nuw i8, ptr %110, i64 16
  %112 = load ptr, ptr %111, align 8
  %113 = icmp eq ptr %82, %112
  br i1 %113, label %114, label %97, !llvm.loop !71

114:                                              ; preds = %108
  %115 = load ptr, ptr %110, align 8
  %116 = getelementptr inbounds nuw i8, ptr %26, i64 8
  %117 = load ptr, ptr %116, align 8
  store ptr %27, ptr %117, align 8
  %118 = getelementptr inbounds nuw i8, ptr %27, i64 8
  %119 = load ptr, ptr %118, align 8
  store ptr %115, ptr %119, align 8
  %120 = getelementptr inbounds nuw i8, ptr %115, i64 8
  %121 = load ptr, ptr %120, align 8
  store ptr %26, ptr %121, align 8
  store ptr %119, ptr %120, align 8
  store ptr %117, ptr %118, align 8
  store ptr %121, ptr %116, align 8
  br label %122

122:                                              ; preds = %95, %114, %100, %76
  %123 = icmp eq ptr %27, %14
  br i1 %123, label %24, label %25, !llvm.loop !72

124:                                              ; preds = %24
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  ret void

125:                                              ; preds = %24, %7
  %126 = cleanuppad within none []
  call void @"??1_Clear_guard@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(8) %3) #30 [ "funclet"(token %126) ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #30
  cleanupret from %126 unwind to caller
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local void @"?_Assign_grow@?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAAX_KV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@@Z"(ptr noundef nonnull align 8 dereferenceable(24) %0, i64 noundef %1, i64 %2) local_unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %5 = load ptr, ptr %4, align 8
  %6 = load ptr, ptr %0, align 8
  %7 = ptrtoint ptr %5 to i64
  %8 = ptrtoint ptr %6 to i64
  %9 = sub i64 %7, %8
  %10 = ashr exact i64 %9, 3
  %11 = icmp ult i64 %10, %1
  br i1 %11, label %12, label %83

12:                                               ; preds = %3
  %13 = icmp ugt i64 %1, 2305843009213693951
  br i1 %13, label %14, label %15

14:                                               ; preds = %12
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

15:                                               ; preds = %12
  %16 = shl nuw i64 %1, 3
  %17 = icmp samesign ugt i64 %1, 511
  br i1 %17, label %18, label %29

18:                                               ; preds = %15
  %19 = icmp samesign ult i64 %1, 2305843009213693948
  br i1 %19, label %21, label %20

20:                                               ; preds = %18
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

21:                                               ; preds = %18
  %22 = add nuw i64 %16, 39
  %23 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %22) #33
  %24 = ptrtoint ptr %23 to i64
  %25 = add i64 %24, 39
  %26 = and i64 %25, -32
  %27 = inttoptr i64 %26 to ptr
  %28 = getelementptr inbounds i8, ptr %27, i64 -8
  store i64 %24, ptr %28, align 8
  br label %31

29:                                               ; preds = %15
  %30 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %16) #33
  br label %31

31:                                               ; preds = %21, %29
  %32 = phi ptr [ %27, %21 ], [ %30, %29 ]
  %33 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %34 = load ptr, ptr %33, align 8
  %35 = load ptr, ptr %0, align 8
  %36 = ptrtoint ptr %34 to i64
  %37 = ptrtoint ptr %35 to i64
  %38 = sub i64 %36, %37
  %39 = icmp eq i64 %38, 0
  br i1 %39, label %55, label %40

40:                                               ; preds = %31
  %41 = icmp ugt i64 %38, 4095
  br i1 %41, label %42, label %52

42:                                               ; preds = %40
  %43 = getelementptr inbounds i8, ptr %35, i64 -8
  %44 = load i64, ptr %43, align 8
  %45 = add i64 %37, -8
  %46 = sub i64 %45, %44
  %47 = icmp ult i64 %46, 32
  br i1 %47, label %49, label %48

48:                                               ; preds = %42
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

49:                                               ; preds = %42
  %50 = add i64 %38, 39
  %51 = inttoptr i64 %44 to ptr
  br label %52

52:                                               ; preds = %40, %49
  %53 = phi i64 [ %50, %49 ], [ %38, %40 ]
  %54 = phi ptr [ %51, %49 ], [ %35, %40 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %54, i64 noundef %53) #30
  br label %55

55:                                               ; preds = %52, %31
  store ptr %32, ptr %0, align 8
  %56 = getelementptr inbounds nuw i8, ptr %32, i64 %16
  store ptr %56, ptr %4, align 8
  store ptr %56, ptr %33, align 8
  tail call void @llvm.seh.scope.begin()
  %57 = add i64 %16, -8
  %58 = lshr exact i64 %57, 3
  %59 = add nuw nsw i64 %58, 1
  %60 = icmp ult i64 %57, 24
  br i1 %60, label %76, label %61

61:                                               ; preds = %55
  %62 = and i64 %59, 4611686018427387900
  %63 = shl i64 %62, 3
  %64 = getelementptr i8, ptr %32, i64 %63
  %65 = insertelement <2 x i64> poison, i64 %2, i64 0
  %66 = shufflevector <2 x i64> %65, <2 x i64> poison, <2 x i32> zeroinitializer
  br label %67

67:                                               ; preds = %67, %61
  %68 = phi i64 [ 0, %61 ], [ %72, %67 ]
  %69 = shl i64 %68, 3
  %70 = getelementptr i8, ptr %32, i64 %69
  %71 = getelementptr i8, ptr %70, i64 16
  store <2 x i64> %66, ptr %70, align 8
  store <2 x i64> %66, ptr %71, align 8
  %72 = add nuw i64 %68, 4
  %73 = icmp eq i64 %72, %62
  br i1 %73, label %74, label %67, !llvm.loop !73

74:                                               ; preds = %67
  %75 = icmp eq i64 %59, %62
  br i1 %75, label %82, label %76

76:                                               ; preds = %55, %74
  %77 = phi ptr [ %32, %55 ], [ %64, %74 ]
  br label %78

78:                                               ; preds = %76, %78
  %79 = phi ptr [ %80, %78 ], [ %77, %76 ]
  store i64 %2, ptr %79, align 8
  %80 = getelementptr inbounds nuw i8, ptr %79, i64 8
  %81 = icmp eq ptr %80, %56
  br i1 %81, label %82, label %78, !llvm.loop !76

82:                                               ; preds = %78, %74
  tail call void @llvm.seh.scope.end()
  br label %112

83:                                               ; preds = %3
  %84 = icmp eq ptr %6, %5
  br i1 %84, label %112, label %85

85:                                               ; preds = %83
  %86 = add i64 %7, -8
  %87 = sub i64 %86, %8
  %88 = lshr i64 %87, 3
  %89 = add nuw nsw i64 %88, 1
  %90 = icmp ult i64 %87, 24
  br i1 %90, label %106, label %91

91:                                               ; preds = %85
  %92 = and i64 %89, 4611686018427387900
  %93 = shl i64 %92, 3
  %94 = getelementptr i8, ptr %6, i64 %93
  %95 = insertelement <2 x i64> poison, i64 %2, i64 0
  %96 = shufflevector <2 x i64> %95, <2 x i64> poison, <2 x i32> zeroinitializer
  br label %97

97:                                               ; preds = %97, %91
  %98 = phi i64 [ 0, %91 ], [ %102, %97 ]
  %99 = shl i64 %98, 3
  %100 = getelementptr i8, ptr %6, i64 %99
  %101 = getelementptr i8, ptr %100, i64 16
  store <2 x i64> %96, ptr %100, align 8
  store <2 x i64> %96, ptr %101, align 8
  %102 = add nuw i64 %98, 4
  %103 = icmp eq i64 %102, %92
  br i1 %103, label %104, label %97, !llvm.loop !77

104:                                              ; preds = %97
  %105 = icmp eq i64 %89, %92
  br i1 %105, label %112, label %106

106:                                              ; preds = %85, %104
  %107 = phi ptr [ %6, %85 ], [ %94, %104 ]
  br label %108

108:                                              ; preds = %106, %108
  %109 = phi ptr [ %110, %108 ], [ %107, %106 ]
  store i64 %2, ptr %109, align 8
  %110 = getelementptr inbounds nuw i8, ptr %109, i64 8
  %111 = icmp eq ptr %110, %5
  br i1 %111, label %112, label %108, !llvm.loop !78

112:                                              ; preds = %108, %104, %83, %82
  ret void
}

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local void @"??1_Clear_guard@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(8) %0) unnamed_addr #0 comdat align 2 {
  %2 = load ptr, ptr %0, align 8
  %3 = icmp eq ptr %2, null
  br i1 %3, label %67, label %4

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %6 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %7 = load i64, ptr %6, align 8
  %8 = icmp eq i64 %7, 0
  br i1 %8, label %67, label %9

9:                                                ; preds = %4
  %10 = getelementptr inbounds nuw i8, ptr %2, i64 56
  %11 = load i64, ptr %10, align 8
  %12 = lshr i64 %11, 3
  %13 = icmp ugt i64 %12, %7
  %14 = load ptr, ptr %5, align 8
  br i1 %13, label %15, label %18

15:                                               ; preds = %9
  %16 = load ptr, ptr %14, align 8
  %17 = tail call noundef ptr @"?_Unchecked_erase@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@AEAAPEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@2@PEAU32@QEAU32@@Z"(ptr noundef nonnull align 8 dereferenceable(64) %2, ptr noundef %16, ptr noundef nonnull %14) #30
  br label %67

18:                                               ; preds = %9
  %19 = getelementptr inbounds nuw i8, ptr %14, i64 8
  %20 = load ptr, ptr %19, align 8
  store ptr null, ptr %20, align 8
  %21 = load ptr, ptr %14, align 8
  %22 = icmp eq ptr %21, null
  br i1 %22, label %28, label %23

23:                                               ; preds = %18, %23
  %24 = phi ptr [ %25, %23 ], [ %21, %18 ]
  %25 = load ptr, ptr %24, align 8
  %26 = getelementptr inbounds nuw i8, ptr %24, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %26) #30
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %24, i64 noundef 56) #30
  %27 = icmp eq ptr %25, null
  br i1 %27, label %28, label %23, !llvm.loop !18

28:                                               ; preds = %23, %18
  %29 = load ptr, ptr %5, align 8
  store ptr %29, ptr %29, align 8
  %30 = getelementptr inbounds nuw i8, ptr %29, i64 8
  store ptr %29, ptr %30, align 8
  store i64 0, ptr %6, align 8
  %31 = getelementptr inbounds nuw i8, ptr %2, i64 24
  %32 = getelementptr inbounds nuw i8, ptr %2, i64 32
  %33 = load ptr, ptr %32, align 8
  %34 = load ptr, ptr %31, align 8
  %35 = icmp eq ptr %34, %33
  br i1 %35, label %67, label %36

36:                                               ; preds = %28
  %37 = ptrtoint ptr %34 to i64
  %38 = ptrtoint ptr %33 to i64
  %39 = load ptr, ptr %5, align 8, !noalias !79
  %40 = ptrtoint ptr %39 to i64
  %41 = add i64 %38, -8
  %42 = sub i64 %41, %37
  %43 = lshr i64 %42, 3
  %44 = add nuw nsw i64 %43, 1
  %45 = icmp ult i64 %42, 24
  br i1 %45, label %61, label %46

46:                                               ; preds = %36
  %47 = and i64 %44, 4611686018427387900
  %48 = shl i64 %47, 3
  %49 = getelementptr i8, ptr %34, i64 %48
  %50 = insertelement <2 x i64> poison, i64 %40, i64 0
  %51 = shufflevector <2 x i64> %50, <2 x i64> poison, <2 x i32> zeroinitializer
  br label %52

52:                                               ; preds = %52, %46
  %53 = phi i64 [ 0, %46 ], [ %57, %52 ]
  %54 = shl i64 %53, 3
  %55 = getelementptr i8, ptr %34, i64 %54
  %56 = getelementptr i8, ptr %55, i64 16
  store <2 x i64> %51, ptr %55, align 8
  store <2 x i64> %51, ptr %56, align 8
  %57 = add nuw i64 %53, 4
  %58 = icmp eq i64 %57, %47
  br i1 %58, label %59, label %52, !llvm.loop !84

59:                                               ; preds = %52
  %60 = icmp eq i64 %44, %47
  br i1 %60, label %67, label %61

61:                                               ; preds = %36, %59
  %62 = phi ptr [ %34, %36 ], [ %49, %59 ]
  br label %63

63:                                               ; preds = %61, %63
  %64 = phi ptr [ %65, %63 ], [ %62, %61 ]
  store i64 %40, ptr %64, align 8
  %65 = getelementptr inbounds nuw i8, ptr %64, i64 8
  %66 = icmp eq ptr %65, %33
  br i1 %66, label %67, label %63, !llvm.loop !85

67:                                               ; preds = %63, %59, %28, %15, %4, %1
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.ctlz.i64(i64, i1 immarg) #25

; Function Attrs: mustprogress nounwind sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"?_Unchecked_erase@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@AEAAPEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@2@PEAU32@QEAU32@@Z"(ptr noundef nonnull align 8 dereferenceable(64) %0, ptr noundef %1, ptr noundef %2) local_unnamed_addr #0 comdat align 2 personality ptr @__CxxFrameHandler3 {
  %4 = icmp eq ptr %1, %2
  br i1 %4, label %197, label %5

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %7 = load ptr, ptr %6, align 8
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %9 = load ptr, ptr %8, align 8
  %10 = getelementptr inbounds nuw i8, ptr %1, i64 8
  %11 = load ptr, ptr %10, align 8
  invoke void @llvm.seh.scope.begin()
          to label %12 unwind label %193

12:                                               ; preds = %5
  %13 = getelementptr inbounds nuw i8, ptr %1, i64 16
  %14 = load i8, ptr %13, align 1
  %15 = zext i8 %14 to i64
  %16 = xor i64 %15, -3750763034362895579
  %17 = mul i64 %16, 1099511628211
  %18 = getelementptr inbounds nuw i8, ptr %1, i64 17
  %19 = load i8, ptr %18, align 1
  %20 = zext i8 %19 to i64
  %21 = xor i64 %17, %20
  %22 = mul i64 %21, 1099511628211
  %23 = getelementptr inbounds nuw i8, ptr %1, i64 18
  %24 = load i8, ptr %23, align 1
  %25 = zext i8 %24 to i64
  %26 = xor i64 %22, %25
  %27 = mul i64 %26, 1099511628211
  %28 = getelementptr inbounds nuw i8, ptr %1, i64 19
  %29 = load i8, ptr %28, align 1
  %30 = zext i8 %29 to i64
  %31 = xor i64 %27, %30
  %32 = mul i64 %31, 1099511628211
  %33 = getelementptr inbounds nuw i8, ptr %1, i64 20
  %34 = load i8, ptr %33, align 1
  %35 = zext i8 %34 to i64
  %36 = xor i64 %32, %35
  %37 = mul i64 %36, 1099511628211
  %38 = getelementptr inbounds nuw i8, ptr %1, i64 21
  %39 = load i8, ptr %38, align 1
  %40 = zext i8 %39 to i64
  %41 = xor i64 %37, %40
  %42 = mul i64 %41, 1099511628211
  %43 = getelementptr inbounds nuw i8, ptr %1, i64 22
  %44 = load i8, ptr %43, align 1
  %45 = zext i8 %44 to i64
  %46 = xor i64 %42, %45
  %47 = mul i64 %46, 1099511628211
  %48 = getelementptr inbounds nuw i8, ptr %1, i64 23
  %49 = load i8, ptr %48, align 1
  %50 = zext i8 %49 to i64
  %51 = xor i64 %47, %50
  %52 = mul i64 %51, 1099511628211
  %53 = getelementptr inbounds nuw i8, ptr %0, i64 48
  %54 = load i64, ptr %53, align 8
  %55 = and i64 %52, %54
  %56 = shl i64 %55, 4
  %57 = getelementptr inbounds nuw i8, ptr %9, i64 %56
  %58 = getelementptr inbounds nuw i8, ptr %57, i64 8
  %59 = load ptr, ptr %57, align 8
  %60 = freeze ptr %59
  %61 = icmp eq ptr %60, %1
  %62 = load ptr, ptr %58, align 8
  %63 = getelementptr inbounds nuw i8, ptr %0, i64 16
  br i1 %61, label %73, label %64

64:                                               ; preds = %12, %71
  %65 = phi ptr [ %67, %71 ], [ %1, %12 ]
  %66 = icmp eq ptr %65, %62
  %67 = load ptr, ptr %65, align 8
  %68 = getelementptr inbounds nuw i8, ptr %65, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %68) #30
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %65, i64 noundef 56) #30
  %69 = load i64, ptr %63, align 8
  %70 = add i64 %69, -1
  store i64 %70, ptr %63, align 8
  br i1 %66, label %83, label %71

71:                                               ; preds = %64
  %72 = icmp eq ptr %67, %2
  br i1 %72, label %189, label %64

73:                                               ; preds = %12, %80
  %74 = phi ptr [ %76, %80 ], [ %1, %12 ]
  %75 = icmp eq ptr %74, %62
  %76 = load ptr, ptr %74, align 8
  %77 = getelementptr inbounds nuw i8, ptr %74, i64 16
  tail call void @"??$destroy_at@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@YAXQEAU?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@0@@Z"(ptr noundef nonnull %77) #30
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %74, i64 noundef 56) #30
  %78 = load i64, ptr %63, align 8
  %79 = add i64 %78, -1
  store i64 %79, ptr %63, align 8
  br i1 %75, label %83, label %80

80:                                               ; preds = %73
  %81 = icmp eq ptr %76, %2
  br i1 %81, label %82, label %73

82:                                               ; preds = %80
  store ptr %76, ptr %57, align 8
  br label %189

83:                                               ; preds = %64, %73
  %84 = phi ptr [ %76, %73 ], [ %67, %64 ]
  br i1 %61, label %85, label %86

85:                                               ; preds = %83
  store ptr %7, ptr %57, align 8
  br label %86

86:                                               ; preds = %85, %83
  %87 = phi ptr [ %7, %85 ], [ %11, %83 ]
  store ptr %87, ptr %58, align 8
  %88 = icmp eq ptr %84, %2
  br i1 %88, label %189, label %89

89:                                               ; preds = %86, %187
  %90 = phi ptr [ %140, %187 ], [ %84, %86 ]
  %91 = getelementptr inbounds nuw i8, ptr %90, i64 16
  %92 = load i8, ptr %91, align 1
  %93 = zext i8 %92 to i64
  %94 = xor i64 %93, -3750763034362895579
  %95 = mul i64 %94, 1099511628211
  %96 = getelementptr inbounds nuw i8, ptr %90, i64 17
  %97 = load i8, ptr %96, align 1
  %98 = zext i8 %97 to i64
  %99 = xor i64 %95, %98
  %100 = mul i64 %99, 1099511628211
  %101 = getelementptr inbounds nuw i8, ptr %90, i64 18
  %102 = load i8, ptr %101, align 1
  %103 = zext i8 %102 to i64
  %104 = xor i64 %100, %103
  %105 = mul i64 %104, 1099511628211
  %106 = getelementptr inbounds nuw i8, ptr %90, i64 19
  %107 = load i8, ptr %106, align 1
  %108 = zext i8 %107 to i64
  %109 = xor i64 %105, %108
  %110 = mul i64 %109, 1099511628211
  %111 = getelementptr inbounds nuw i8, ptr %90, i64 20
  %112 = load i8, ptr %111, align 1
  %113 = zext i8 %112 to i64
  %114 = xor i64 %110, %113
  %115 = mul i64 %114, 1099511628211
  %116 = getelementptr inbounds nuw i8, ptr %90, i64 21
  %117 = load i8, ptr %116, align 1
  %118 = zext i8 %117 to i64
  %119 = xor i64 %115, %118
  %120 = mul i64 %119, 1099511628211
  %121 = getelementptr inbounds nuw i8, ptr %90, i64 22
  %122 = load i8, ptr %121, align 1
  %123 = zext i8 %122 to i64
  %124 = xor i64 %120, %123
  %125 = mul i64 %124, 1099511628211
  %126 = getelementptr inbounds nuw i8, ptr %90, i64 23
  %127 = load i8, ptr %126, align 1
  %128 = zext i8 %127 to i64
  %129 = xor i64 %125, %128
  %130 = mul i64 %129, 1099511628211
  %131 = load i64, ptr %53, align 8
  %132 = and i64 %130, %131
  %133 = shl i64 %132, 4
  %134 = getelementptr inbounds nuw i8, ptr %9, i64 %133
  %135 = getelementptr inbounds nuw i8, ptr %134, i64 8
  %136 = load ptr, ptr %135, align 8
  br label %137

137:                                              ; preds = %184, %89
  %138 = phi ptr [ %90, %89 ], [ %140, %184 ]
  %139 = icmp eq ptr %138, %136
  %140 = load ptr, ptr %138, align 8
  invoke void @llvm.seh.scope.begin()
          to label %141 unwind label %178

141:                                              ; preds = %137
  invoke void @llvm.seh.scope.end()
          to label %142 unwind label %178

142:                                              ; preds = %141
  %143 = getelementptr inbounds nuw i8, ptr %138, i64 24
  invoke void @llvm.seh.scope.begin()
          to label %144 unwind label %172

144:                                              ; preds = %142
  %145 = getelementptr inbounds nuw i8, ptr %138, i64 48
  %146 = load i64, ptr %145, align 8
  %147 = icmp ugt i64 %146, 15
  br i1 %147, label %148, label %166

148:                                              ; preds = %144
  %149 = load ptr, ptr %143, align 8
  %150 = add i64 %146, 1
  %151 = icmp ugt i64 %150, 4095
  br i1 %151, label %152, label %163

152:                                              ; preds = %148
  %153 = getelementptr inbounds i8, ptr %149, i64 -8
  %154 = load i64, ptr %153, align 8
  %155 = ptrtoint ptr %149 to i64
  %156 = add i64 %155, -8
  %157 = sub i64 %156, %154
  %158 = icmp ult i64 %157, 32
  br i1 %158, label %160, label %159

159:                                              ; preds = %152
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

160:                                              ; preds = %152
  %161 = add i64 %146, 40
  %162 = inttoptr i64 %154 to ptr
  br label %163

163:                                              ; preds = %160, %148
  %164 = phi i64 [ %161, %160 ], [ %150, %148 ]
  %165 = phi ptr [ %162, %160 ], [ %149, %148 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %165, i64 noundef %164) #30
  br label %166

166:                                              ; preds = %163, %144
  %167 = getelementptr inbounds nuw i8, ptr %138, i64 40
  store i64 0, ptr %167, align 8
  store i64 15, ptr %145, align 8
  store i8 0, ptr %143, align 1
  invoke void @llvm.seh.scope.end()
          to label %168 unwind label %172

168:                                              ; preds = %166
  invoke void @llvm.seh.scope.begin()
          to label %169 unwind label %170

169:                                              ; preds = %168
  invoke void @llvm.seh.scope.end()
          to label %181 unwind label %170

170:                                              ; preds = %169, %168
  %171 = cleanuppad within none []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %171 unwind to caller

172:                                              ; preds = %166, %142
  %173 = cleanuppad within none []
  invoke void @llvm.seh.scope.begin()
          to label %174 unwind label %175

174:                                              ; preds = %172
  invoke void @llvm.seh.scope.end()
          to label %177 unwind label %175

175:                                              ; preds = %174, %172
  %176 = cleanuppad within %173 []
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %176 unwind to caller

177:                                              ; preds = %174
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  cleanupret from %173 unwind to caller

178:                                              ; preds = %141, %137
  %179 = cleanuppad within none []
  %180 = getelementptr inbounds nuw i8, ptr %138, i64 24
  call void @"??1?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(32) %180) #30 [ "funclet"(token %179) ]
  cleanupret from %179 unwind to caller

181:                                              ; preds = %169
  tail call void @llvm.seh.scope.begin()
  tail call void @llvm.seh.scope.end()
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef nonnull %138, i64 noundef 56) #30
  %182 = load i64, ptr %63, align 8
  %183 = add i64 %182, -1
  store i64 %183, ptr %63, align 8
  br i1 %139, label %187, label %184

184:                                              ; preds = %181
  %185 = icmp eq ptr %140, %2
  br i1 %185, label %186, label %137

186:                                              ; preds = %184
  store ptr %140, ptr %134, align 8
  br label %189

187:                                              ; preds = %181
  store ptr %7, ptr %134, align 8
  store ptr %7, ptr %135, align 8
  %188 = icmp eq ptr %140, %2
  br i1 %188, label %189, label %89, !llvm.loop !86

189:                                              ; preds = %71, %187, %86, %186, %82
  %190 = phi ptr [ %76, %82 ], [ %140, %186 ], [ %84, %86 ], [ %140, %187 ], [ %67, %71 ]
  invoke void @llvm.seh.scope.end()
          to label %191 unwind label %193

191:                                              ; preds = %189
  store ptr %190, ptr %11, align 8
  %192 = getelementptr inbounds nuw i8, ptr %190, i64 8
  store ptr %11, ptr %192, align 8
  br label %197

193:                                              ; preds = %189, %5
  %194 = phi ptr [ %190, %189 ], [ %1, %5 ]
  %195 = cleanuppad within none []
  store ptr %194, ptr %11, align 8
  %196 = getelementptr inbounds nuw i8, ptr %194, i64 8
  store ptr %11, ptr %196, align 8
  cleanupret from %195 unwind to caller

197:                                              ; preds = %3, %191
  ret ptr %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.ceil.f32(float) #25

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_grow_by@V<lambda_1>@?0??append@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@QEAAAEAV34@QEBD_K@Z@PEBD_K@?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??append@01@QEAAAEAV01@QEBD0@Z@PEBD_K@Z"(ptr noundef nonnull align 8 dereferenceable(32) %0, i64 noundef %1, i8 %2, ptr noundef %3, i64 noundef %4) local_unnamed_addr #5 comdat align 2 {
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %7 = load i64, ptr %6, align 8
  %8 = sub i64 9223372036854775807, %7
  %9 = icmp ult i64 %8, %1
  br i1 %9, label %10, label %11

10:                                               ; preds = %5
  tail call void @"?_Xlen_string@std@@YAXXZ"() #32
  unreachable

11:                                               ; preds = %5
  %12 = add i64 %7, %1
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %14 = load i64, ptr %13, align 8
  %15 = or i64 %12, 15
  %16 = icmp slt i64 %12, 0
  br i1 %16, label %31, label %17

17:                                               ; preds = %11
  %18 = lshr i64 %14, 1
  %19 = xor i64 %18, 9223372036854775807
  %20 = icmp ugt i64 %14, %19
  br i1 %20, label %31, label %21

21:                                               ; preds = %17
  %22 = add nuw i64 %18, %14
  %23 = tail call i64 @llvm.umax.i64(i64 %15, i64 %22)
  %24 = add i64 %23, 1
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %42, label %26

26:                                               ; preds = %21
  %27 = icmp ugt i64 %24, 4095
  br i1 %27, label %28, label %40

28:                                               ; preds = %26
  %29 = icmp ult i64 %24, -39
  br i1 %29, label %31, label %30

30:                                               ; preds = %28
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

31:                                               ; preds = %17, %11, %28
  %32 = phi i64 [ %23, %28 ], [ 9223372036854775807, %11 ], [ 9223372036854775807, %17 ]
  %33 = add nuw i64 %32, 40
  %34 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %33) #33
  %35 = ptrtoint ptr %34 to i64
  %36 = add i64 %35, 39
  %37 = and i64 %36, -32
  %38 = inttoptr i64 %37 to ptr
  %39 = getelementptr inbounds i8, ptr %38, i64 -8
  store i64 %35, ptr %39, align 8
  br label %42

40:                                               ; preds = %26
  %41 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %24) #33
  br label %42

42:                                               ; preds = %21, %31, %40
  %43 = phi i64 [ %32, %31 ], [ %23, %40 ], [ -1, %21 ]
  %44 = phi ptr [ %38, %31 ], [ %41, %40 ], [ null, %21 ]
  store i64 %12, ptr %6, align 8
  store i64 %43, ptr %13, align 8
  %45 = icmp ugt i64 %14, 15
  br i1 %45, label %46, label %66

46:                                               ; preds = %42
  %47 = load ptr, ptr %0, align 8
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %44, ptr align 1 %47, i64 %7, i1 false)
  %48 = getelementptr i8, ptr %44, i64 %7
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %48, ptr align 1 %3, i64 %4, i1 false)
  %49 = getelementptr i8, ptr %48, i64 %4
  store i8 0, ptr %49, align 1
  %50 = add i64 %14, 1
  %51 = icmp ugt i64 %50, 4095
  br i1 %51, label %52, label %63

52:                                               ; preds = %46
  %53 = getelementptr inbounds i8, ptr %47, i64 -8
  %54 = load i64, ptr %53, align 8
  %55 = ptrtoint ptr %47 to i64
  %56 = add i64 %55, -8
  %57 = sub i64 %56, %54
  %58 = icmp ult i64 %57, 32
  br i1 %58, label %60, label %59

59:                                               ; preds = %52
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

60:                                               ; preds = %52
  %61 = add i64 %14, 40
  %62 = inttoptr i64 %54 to ptr
  br label %63

63:                                               ; preds = %46, %60
  %64 = phi i64 [ %61, %60 ], [ %50, %46 ]
  %65 = phi ptr [ %62, %60 ], [ %47, %46 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %65, i64 noundef %64) #30
  br label %69

66:                                               ; preds = %42
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %44, ptr nonnull align 8 %0, i64 %7, i1 false)
  %67 = getelementptr i8, ptr %44, i64 %7
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %67, ptr align 1 %3, i64 %4, i1 false)
  %68 = getelementptr i8, ptr %67, i64 %4
  store i8 0, ptr %68, align 1
  br label %69

69:                                               ; preds = %66, %63
  store ptr %44, ptr %0, align 8
  ret ptr %0
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef nonnull align 8 dereferenceable(32) ptr @"??$_Reallocate_for@V<lambda_1>@?0??assign@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEAAAEAV34@QEB_W_K@Z@PEB_W@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@AEAAAEAV01@_KV<lambda_1>@?0??assign@01@QEAAAEAV01@QEB_W0@Z@PEB_W@Z"(ptr noundef nonnull align 8 dereferenceable(32) %0, i64 noundef %1, i8 %2, ptr noundef %3) local_unnamed_addr #5 comdat align 2 {
  %5 = icmp ugt i64 %1, 9223372036854775806
  br i1 %5, label %6, label %7

6:                                                ; preds = %4
  tail call void @"?_Xlen_string@std@@YAXXZ"() #32
  unreachable

7:                                                ; preds = %4
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %9 = load i64, ptr %8, align 8
  %10 = or i64 %1, 7
  %11 = icmp samesign ugt i64 %10, 9223372036854775806
  br i1 %11, label %28, label %12

12:                                               ; preds = %7
  %13 = lshr i64 %9, 1
  %14 = sub nsw i64 9223372036854775806, %13
  %15 = icmp ugt i64 %9, %14
  br i1 %15, label %28, label %16

16:                                               ; preds = %12
  %17 = add i64 %13, %9
  %18 = tail call i64 @llvm.umax.i64(i64 %10, i64 %17)
  %19 = add i64 %18, 1
  %20 = icmp slt i64 %19, 0
  br i1 %20, label %21, label %22

21:                                               ; preds = %16
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

22:                                               ; preds = %16
  %23 = shl nuw i64 %19, 1
  %24 = icmp ne i64 %19, 0
  tail call void @llvm.assume(i1 %24)
  %25 = icmp samesign ugt i64 %19, 2047
  br i1 %25, label %26, label %37

26:                                               ; preds = %22
  %27 = icmp samesign ult i64 %19, 9223372036854775789
  br i1 %27, label %29, label %28

28:                                               ; preds = %7, %12, %26
  tail call void @"?_Throw_bad_array_new_length@std@@YAXXZ"() #32
  unreachable

29:                                               ; preds = %26
  %30 = add nuw i64 %23, 39
  %31 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %30) #33
  %32 = ptrtoint ptr %31 to i64
  %33 = add i64 %32, 39
  %34 = and i64 %33, -32
  %35 = inttoptr i64 %34 to ptr
  %36 = getelementptr inbounds i8, ptr %35, i64 -8
  store i64 %32, ptr %36, align 8
  br label %39

37:                                               ; preds = %22
  %38 = tail call noalias noundef nonnull ptr @"??2@YAPEAX_K@Z"(i64 noundef %23) #33
  br label %39

39:                                               ; preds = %29, %37
  %40 = phi ptr [ %35, %29 ], [ %38, %37 ]
  %41 = getelementptr inbounds nuw i8, ptr %0, i64 16
  store i64 %1, ptr %41, align 8
  store i64 %18, ptr %8, align 8
  %42 = shl nuw i64 %1, 1
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 2 %40, ptr align 2 %3, i64 %42, i1 false)
  %43 = getelementptr inbounds nuw i16, ptr %40, i64 %1
  store i16 0, ptr %43, align 2
  %44 = icmp ugt i64 %9, 7
  br i1 %44, label %45, label %64

45:                                               ; preds = %39
  %46 = load ptr, ptr %0, align 8
  %47 = shl i64 %9, 1
  %48 = add i64 %47, 2
  %49 = icmp ugt i64 %48, 4095
  br i1 %49, label %50, label %61

50:                                               ; preds = %45
  %51 = getelementptr inbounds i8, ptr %46, i64 -8
  %52 = load i64, ptr %51, align 8
  %53 = ptrtoint ptr %46 to i64
  %54 = add i64 %53, -8
  %55 = sub i64 %54, %52
  %56 = icmp ult i64 %55, 32
  br i1 %56, label %58, label %57

57:                                               ; preds = %50
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

58:                                               ; preds = %50
  %59 = add i64 %47, 41
  %60 = inttoptr i64 %52 to ptr
  br label %61

61:                                               ; preds = %45, %58
  %62 = phi i64 [ %59, %58 ], [ %48, %45 ]
  %63 = phi ptr [ %60, %58 ], [ %46, %45 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %63, i64 noundef %62) #30
  br label %64

64:                                               ; preds = %39, %61
  store ptr %40, ptr %0, align 8
  ret ptr %0
}

; Function Attrs: mustprogress sspstrong uwtable
define linkonce_odr dso_local noundef ptr @"??0?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAA@AEBV?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@1@AEBV?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@1@@Z"(ptr noundef nonnull returned align 8 dereferenceable(64) %0, ptr noundef nonnull align 4 dereferenceable(4) %1, ptr noundef nonnull align 1 dereferenceable(1) %2) unnamed_addr #5 comdat align 2 personality ptr @__CxxFrameHandler3 {
  %4 = load i32, ptr %1, align 4
  store i32 %4, ptr %0, align 8
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  %6 = tail call noalias noundef nonnull dereferenceable(56) ptr @"??2@YAPEAX_K@Z"(i64 noundef 56) #33
  store ptr %6, ptr %6, align 8
  %7 = getelementptr inbounds nuw i8, ptr %6, i64 8
  store ptr %6, ptr %7, align 8
  store ptr %6, ptr %5, align 8
  invoke void @llvm.seh.scope.begin()
          to label %8 unwind label %61

8:                                                ; preds = %3
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 24
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %9, i8 0, i64 24, i1 false)
  invoke void @llvm.seh.scope.begin()
          to label %10 unwind label %58

10:                                               ; preds = %8
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 48
  store i64 7, ptr %11, align 8
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 56
  store i64 8, ptr %12, align 8
  store float 1.000000e+00, ptr %0, align 8
  %13 = ptrtoint ptr %6 to i64
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %15 = invoke noalias noundef nonnull dereferenceable(128) ptr @"??2@YAPEAX_K@Z"(i64 noundef 128) #33
          to label %16 unwind label %58

16:                                               ; preds = %10
  %17 = getelementptr inbounds nuw i8, ptr %0, i64 40
  %18 = load ptr, ptr %17, align 8
  %19 = load ptr, ptr %9, align 8
  %20 = ptrtoint ptr %18 to i64
  %21 = ptrtoint ptr %19 to i64
  %22 = sub i64 %20, %21
  %23 = icmp eq i64 %22, 0
  br i1 %23, label %39, label %24

24:                                               ; preds = %16
  %25 = icmp ugt i64 %22, 4095
  br i1 %25, label %26, label %36

26:                                               ; preds = %24
  %27 = getelementptr inbounds i8, ptr %19, i64 -8
  %28 = load i64, ptr %27, align 8
  %29 = add i64 %21, -8
  %30 = sub i64 %29, %28
  %31 = icmp ult i64 %30, 32
  br i1 %31, label %33, label %32

32:                                               ; preds = %26
  tail call void @_invoke_watson(ptr noundef null, ptr noundef null, ptr noundef null, i32 noundef 0, i64 noundef 0) #29
  unreachable

33:                                               ; preds = %26
  %34 = add i64 %22, 39
  %35 = inttoptr i64 %28 to ptr
  br label %36

36:                                               ; preds = %33, %24
  %37 = phi i64 [ %34, %33 ], [ %22, %24 ]
  %38 = phi ptr [ %35, %33 ], [ %19, %24 ]
  tail call void @"??3@YAXPEAX_K@Z"(ptr noundef %38, i64 noundef %37) #30
  br label %39

39:                                               ; preds = %16, %36
  store ptr %15, ptr %9, align 8
  %40 = getelementptr inbounds nuw i8, ptr %15, i64 128
  store ptr %40, ptr %14, align 8
  store ptr %40, ptr %17, align 8
  tail call void @llvm.seh.scope.begin()
  store i64 %13, ptr %15, align 8
  %41 = getelementptr inbounds nuw i8, ptr %15, i64 8
  store i64 %13, ptr %41, align 8
  %42 = getelementptr inbounds nuw i8, ptr %15, i64 16
  store i64 %13, ptr %42, align 8
  %43 = getelementptr inbounds nuw i8, ptr %15, i64 24
  store i64 %13, ptr %43, align 8
  %44 = getelementptr inbounds nuw i8, ptr %15, i64 32
  store i64 %13, ptr %44, align 8
  %45 = getelementptr inbounds nuw i8, ptr %15, i64 40
  store i64 %13, ptr %45, align 8
  %46 = getelementptr inbounds nuw i8, ptr %15, i64 48
  store i64 %13, ptr %46, align 8
  %47 = getelementptr inbounds nuw i8, ptr %15, i64 56
  store i64 %13, ptr %47, align 8
  %48 = getelementptr inbounds nuw i8, ptr %15, i64 64
  store i64 %13, ptr %48, align 8
  %49 = getelementptr inbounds nuw i8, ptr %15, i64 72
  store i64 %13, ptr %49, align 8
  %50 = getelementptr inbounds nuw i8, ptr %15, i64 80
  store i64 %13, ptr %50, align 8
  %51 = getelementptr inbounds nuw i8, ptr %15, i64 88
  store i64 %13, ptr %51, align 8
  %52 = getelementptr inbounds nuw i8, ptr %15, i64 96
  store i64 %13, ptr %52, align 8
  %53 = getelementptr inbounds nuw i8, ptr %15, i64 104
  store i64 %13, ptr %53, align 8
  %54 = getelementptr inbounds nuw i8, ptr %15, i64 112
  store i64 %13, ptr %54, align 8
  %55 = getelementptr inbounds nuw i8, ptr %15, i64 120
  store i64 %13, ptr %55, align 8
  tail call void @llvm.seh.scope.end()
  invoke void @llvm.seh.scope.end()
          to label %56 unwind label %58

56:                                               ; preds = %39
  invoke void @llvm.seh.scope.end()
          to label %57 unwind label %61

57:                                               ; preds = %56
  ret ptr %0

58:                                               ; preds = %10, %39, %8
  %59 = cleanuppad within none []
  invoke void @llvm.seh.scope.end() [ "funclet"(token %59) ]
          to label %60 unwind label %61

60:                                               ; preds = %58
  call void @"??1?$_Hash_vec@V?$allocator@V?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@std@@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(24) %9) #30 [ "funclet"(token %59) ]
  cleanupret from %59 unwind label %61

61:                                               ; preds = %56, %60, %58, %3
  %62 = cleanuppad within none []
  call void @"??1?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(16) %5) #30 [ "funclet"(token %62) ]
  cleanupret from %62 unwind to caller
}

; Function Attrs: sspstrong uwtable
define internal void @_GLOBAL__sub_I_tick_split.cpp() #1 personality ptr @__CxxFrameHandler3 {
  %1 = alloca %"class.std::allocator.49", align 1
  %2 = alloca %"class.std::_Uhash_compare", align 4
  %3 = tail call i32 @atexit(ptr nonnull @"??__Fg_path@?A0xB9C01504@opf@@YAXXZ") #30
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %1) #30
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #30
  store float 0.000000e+00, ptr %2, align 4
  %4 = call noundef ptr @"??0?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEAA@AEBV?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@1@AEBV?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@1@@Z"(ptr noundef nonnull align 8 dereferenceable(64) @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A", ptr noundef nonnull align 4 dereferenceable(4) %2, ptr noundef nonnull align 1 dereferenceable(1) %1)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #30
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %1) #30
  invoke void @llvm.seh.scope.begin()
          to label %5 unwind label %6

5:                                                ; preds = %0
  invoke void @llvm.seh.scope.end()
          to label %8 unwind label %6

6:                                                ; preds = %5, %0
  %7 = cleanuppad within none []
  call void @"??1?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA@XZ"(ptr noundef nonnull align 8 dereferenceable(64) @"?g_names@?A0xB9C01504@opf@@3V?$unordered_map@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@U?$hash@PEBX@2@U?$equal_to@PEBX@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@A") #30 [ "funclet"(token %7) ]
  cleanupret from %7 unwind to caller

8:                                                ; preds = %5
  %9 = call i32 @atexit(ptr nonnull @"??__Fg_names@?A0xB9C01504@opf@@YAXXZ") #30
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.usub.sat.i64(i64, i64) #26

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #26

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite)
declare void @llvm.experimental.noalias.scope.decl(metadata) #27

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umax.i64(i64, i64) #26

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #26

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #28

attributes #0 = { mustprogress nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind }
attributes #3 = { inlinehint mustprogress nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #8 = { nofree nosync nounwind memory(none) }
attributes #9 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #10 = { mustprogress nofree norecurse nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #11 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #12 = { nofree nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #13 = { mustprogress nofree norecurse nosync nounwind sspstrong willreturn memory(read, argmem: write, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #14 = { mustprogress nofree nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #15 = { nobuiltin nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #16 = { noreturn "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #17 = { inlinehint mustprogress noreturn sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #18 = { nobuiltin allocsize(0) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #19 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: read) "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #20 = { mustprogress nofree norecurse nosync nounwind sspstrong memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #21 = { mustprogress nounwind willreturn memory(write) }
attributes #22 = { mustprogress noreturn sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #23 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #24 = { mustprogress noinline nounwind sspstrong uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #25 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #26 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #27 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #28 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #29 = { noreturn nounwind }
attributes #30 = { nounwind }
attributes #31 = { nounwind willreturn memory(read) }
attributes #32 = { noreturn }
attributes #33 = { allocsize(0) }
attributes #34 = { noinline }
attributes #35 = { builtin nounwind }
attributes #36 = { noinline nounwind }

!llvm.dbg.cu = !{!0}
!llvm.linker.options = !{!2, !3, !4, !5, !6, !7, !8, !9, !10}
!llvm.module.flags = !{!11, !12, !13, !14, !15, !16}
!llvm.ident = !{!17}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 21.1.8", isOptimized: true, runtimeVersion: 0, emissionKind: NoDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "src/diagnostics/tick_split.cpp", directory: "/home/ExtraToast/Projects/opf-crash/src/OblivionPerfFix")
!2 = !{!"/DEFAULTLIB:libcmt.lib"}
!3 = !{!"/DEFAULTLIB:oldnames.lib"}
!4 = !{!"/FAILIFMISMATCH:\22_MSC_VER=1900\22"}
!5 = !{!"/FAILIFMISMATCH:\22_ITERATOR_DEBUG_LEVEL=0\22"}
!6 = !{!"/FAILIFMISMATCH:\22RuntimeLibrary=MT_StaticRelease\22"}
!7 = !{!"/DEFAULTLIB:libcpmt.lib"}
!8 = !{!"/FAILIFMISMATCH:\22_CRT_STDIO_ISO_WIDE_SPECIFIERS=0\22"}
!9 = !{!"/FAILIFMISMATCH:\22annotate_string=0\22"}
!10 = !{!"/FAILIFMISMATCH:\22annotate_vector=0\22"}
!11 = !{i32 2, !"Debug Info Version", i32 3}
!12 = !{i32 1, !"wchar_size", i32 2}
!13 = !{i32 2, !"eh-asynch", i32 1}
!14 = !{i32 8, !"PIC Level", i32 2}
!15 = !{i32 7, !"uwtable", i32 2}
!16 = !{i32 1, !"MaxTLSAlign", i32 65536}
!17 = !{!"clang version 21.1.8"}
!18 = distinct !{!18, !19}
!19 = !{!"llvm.loop.mustprogress"}
!20 = !{i8 0, i8 2}
!21 = !{}
!22 = !{!23}
!23 = distinct !{!23, !24, !"??$?H_WU?$char_traits@_W@std@@V?$allocator@_W@1@@std@@YA?AV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@0@$$QEAV10@QEB_W@Z: argument 0"}
!24 = distinct !{!24, !"??$?H_WU?$char_traits@_W@std@@V?$allocator@_W@1@@std@@YA?AV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@0@$$QEAV10@QEB_W@Z"}
!25 = distinct !{!25, !19}
!26 = distinct !{!26, !19}
!27 = distinct !{!27, !19}
!28 = distinct !{!28, !19}
!29 = distinct !{!29, !19}
!30 = !{!31}
!31 = distinct !{!31, !32, !"?substr@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEBA?AV12@_K0@Z: argument 0"}
!32 = distinct !{!32, !"?substr@?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@std@@QEBA?AV12@_K0@Z"}
!33 = !{!34}
!34 = distinct !{!34, !35, !"??$?H_WU?$char_traits@_W@std@@V?$allocator@_W@1@@std@@YA?AV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@0@$$QEAV10@QEB_W@Z: argument 0"}
!35 = distinct !{!35, !"??$?H_WU?$char_traits@_W@std@@V?$allocator@_W@1@@std@@YA?AV?$basic_string@_WU?$char_traits@_W@std@@V?$allocator@_W@2@@0@$$QEAV10@QEB_W@Z"}
!36 = distinct !{!36, !19}
!37 = distinct !{!37, !19}
!38 = !{!39}
!39 = distinct !{!39, !40, !"??$?HDU?$char_traits@D@std@@V?$allocator@D@1@@std@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@0@QEBDAEBV10@@Z: argument 0"}
!40 = distinct !{!40, !"??$?HDU?$char_traits@D@std@@V?$allocator@D@1@@std@@YA?AV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@0@QEBDAEBV10@@Z"}
!41 = distinct !{!41, !19}
!42 = distinct !{!42, !19}
!43 = distinct !{!43, !19}
!44 = !{!45, !47}
!45 = distinct !{!45, !46, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z: argument 0"}
!46 = distinct !{!46, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z"}
!47 = distinct !{!47, !48, !"?find@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@AEBQEBX@Z: argument 0"}
!48 = distinct !{!48, !"?find@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@AEBQEBX@Z"}
!49 = distinct !{!49, !19}
!50 = distinct !{!50, !19}
!51 = distinct !{!51, !19}
!52 = distinct !{!52, !19}
!53 = distinct !{!53, !19}
!54 = distinct !{!54, !19}
!55 = !{!56}
!56 = distinct !{!56, !57, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z: argument 0"}
!57 = distinct !{!57, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z"}
!58 = !{!59}
!59 = distinct !{!59, !60, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z: argument 0"}
!60 = distinct !{!60, !"??$_Find_last@PEBX@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@IEBA?AU?$_Hash_find_last_result@PEAU?$_List_node@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@PEAX@std@@@1@AEBQEBX_K@Z"}
!61 = !{!62, !64}
!62 = distinct !{!62, !63, !"?_Unchecked_end@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!63 = distinct !{!63, !"?_Unchecked_end@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!64 = distinct !{!64, !65, !"?_Unchecked_end@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!65 = distinct !{!65, !"?_Unchecked_end@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!66 = !{!67, !69}
!67 = distinct !{!67, !68, !"?_Unchecked_begin@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!68 = distinct !{!68, !"?_Unchecked_begin@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!69 = distinct !{!69, !70, !"?_Unchecked_begin@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!70 = distinct !{!70, !"?_Unchecked_begin@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!71 = distinct !{!71, !19}
!72 = distinct !{!72, !19}
!73 = distinct !{!73, !74, !75}
!74 = !{!"llvm.loop.isvectorized", i32 1}
!75 = !{!"llvm.loop.unroll.runtime.disable"}
!76 = distinct !{!76, !75, !74}
!77 = distinct !{!77, !19, !74, !75}
!78 = distinct !{!78, !19, !75, !74}
!79 = !{!80, !82}
!80 = distinct !{!80, !81, !"?_Unchecked_end@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!81 = distinct !{!81, !"?_Unchecked_end@?$list@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!82 = distinct !{!82, !83, !"?_Unchecked_end@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ: argument 0"}
!83 = distinct !{!83, !"?_Unchecked_end@?$_Hash@V?$_Umap_traits@PEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@V?$_Uhash_compare@PEBXU?$hash@PEBX@std@@U?$equal_to@PEBX@2@@2@V?$allocator@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@2@$0A@@std@@@std@@QEAA?AV?$_List_unchecked_iterator@V?$_List_val@U?$_List_simple_types@U?$pair@QEBXV?$basic_string@DU?$char_traits@D@std@@V?$allocator@D@2@@std@@@std@@@std@@@std@@@2@XZ"}
!84 = distinct !{!84, !19, !74, !75}
!85 = distinct !{!85, !19, !75, !74}
!86 = distinct !{!86, !19}
