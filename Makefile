W ?= 32
H ?= 16

empty =
space = $(empty) $(empty)
head = $(firstword $1)
tail = $(wordlist 2,$(words $1),$1)
reverse = $(strip $(if $1,$(call reverse,$(call tail,$1)) $(call head,$1)))
implode = $(subst $(space),,$1)

map = $(foreach a,$2,$(call $1,$a))
map2 = $(if $2$3,$(call $1,$(call head,$2),$(call head,$3)) $(call map2,$1,$(call tail,$2),$(call tail,$3)))

reduce = $(if $(call tail,$2),$(call $1,$(call head,$2),$(call reduce,$1,$(call tail,$2))),$2)

u_add = $1$2
u_sub = $(patsubst $2%,%,$1)
u_mul = $(subst 0,$1,$2)
u_mod = $(subst $2,,$1)
u_div = $(subst 1,0,$(subst 0,,$(subst $2,1,$1)))
u_eq = $(if $(call u_sub,$1,$2),,0)
u_gte = $(call u_eq,$(call u_sub,x$2,x$1),x$2)
u_lte = $(call u_eq,$(call u_sub,x$1,x$2),x$1)
u_to_dec = $(words $(subst 0,0 ,$1))
u_sq = $(subst 0,$1,$1)
u_cb = $(subst 0,$(subst 0,$1,$1),$1)

dec_explode_digit = $(subst $1,$1 ,$2)
dec_explode_r = $(if $1,$(call dec_explode_digit,$(call head,$1),$(call dec_explode_r,$(call tail,$1),$2)),$2)
dec_explode = $(call dec_explode_r,0 1 2 3 4 5 6 7 8 9,$1)
dec_to_u_lut_0 =
dec_to_u_lut_1 = 0
dec_to_u_lut_2 = 00
dec_to_u_lut_3 = 000
dec_to_u_lut_4 = 0000
dec_to_u_lut_5 = 00000
dec_to_u_lut_6 = 000000
dec_to_u_lut_7 = 0000000
dec_to_u_lut_8 = 00000000
dec_to_u_lut_9 = 000000000
dec_to_u_f = $(dec_to_u_lut_$1)$(call u_mul,$(call u_sub,$2,0),0000000000)0
dec_to_u = $(call u_sub,$(call reduce,dec_to_u_f,$(call reverse,$(call dec_explode,$1)) 0),0)
dec_sign = $(firstword $(subst -,- ,$(subst +,+ ,$1)))
dec_to_s = $(if $(subst -,,$(call dec_sign,$1)),+$(call dec_to_u,$(subst +,,$1)),-$(call dec_to_u,$(subst -,,$1)))

s_is_positive = $(patsubst -%,,$1)
s_sign = $(if $(call s_is_positive,$1),+,-)
s_to_u = $(patsubst +%,%,$(patsubst -%,%,$1))
s_to_udec = $(call u_to_dec,$(call s_to_u,$1))
s_to_dec = $(call s_sign,$1)$(call u_to_dec,$(call s_to_u,$1))
s_negate = $(if $(call s_is_positive,$1),$(subst +,-,$1),$(subst -,+,$1))
s_is_0 = $(if $(call s_to_u,$1),,0)
s_neq = $(subst $1,,$2)

s_add++ = +$1$2
s_add-- = -$1$2
s_add+- = $(if $(call u_gte,$1,$2),+$(call u_sub,$1,$2),-$(call u_sub,$2,$1))
s_add-+ = $(if $(call u_lte,$1,$2),+$(call u_sub,$2,$1),-$(call u_sub,$1,$2))
s_add = $(call s_add$(call s_sign,$1)$(call s_sign,$2),$(call s_to_u,$1),$(call s_to_u,$2))
s_sub = $(call s_add,$1,$(call s_negate,$2))

s_mul_sign++ = +
s_mul_sign+- = -
s_mul_sign-+ = -
s_mul_sign-- = +
s_mul = $(s_mul_sign$(call s_sign,$1)$(call s_sign,$2))$(call u_mul,$(call s_to_u,$1),$(call s_to_u,$2))
s_div = $(s_mul_sign$(call s_sign,$1)$(call s_sign,$2))$(call u_div,$(call s_to_u,$1),$(call s_to_u,$2))
s_mod = $(s_mul_sign$(call s_sign,$1)$(call s_sign,$2))$(call u_mod,$(call s_to_u,$1),$(call s_to_u,$2))
s_div2 = $(call s_div,$1,+00)

s_mk_range = $(if $(call s_neq,$1,$2),$1 $(call s_mk_range,$(call s_add,$1,+0),$2))

f_ubase := $(call dec_to_u,1000)
f_sbase := +$(f_ubase)

s_to_f = $(call s_mul,$1,$(f_sbase))
f_from_parts = $(call s_add,$(call s_mul,$1,$(f_sbase)),$2)
f_ipart = $(call s_div,$1,$(f_sbase))
dec_to_f = $(call s_to_f,$(call dec_to_s,$1))

f_is_positive = $(call s_is_positive,$1)

f_add = $(call s_add,$1,$2)
f_sub = $(call s_sub,$1,$2)
f_mul = $(call s_div,$(call s_mul,$1,$2),$(f_sbase))
f_div = $(call s_div,$(call s_mul,$1,$(f_sbase)),$2)
f_sq = $(call f_mul,$1,$1)

f_fpart_to_dec = $(call implode,$(call reverse,$(wordlist 1,3,$(call reverse,$(call dec_explode,$(call u_to_dec,$(call u_add,$(call s_to_u,$1),$(f_ubase))))))))
f_to_dec = $(call s_to_dec,$(call f_ipart,$1)).$(call f_fpart_to_dec,$1)

f_one := $(f_sbase)
f_two := $(call s_to_f,+00)
f_three := $(call s_to_f,+000)
f_half := $(call f_div,$(f_one),$(f_two))

f_div2 = $(call f_mul,$1,$(f_half))

f_sqrt_iter = $(call f_div2,$(call f_add,$(call f_div,$1,$2),$2))
f_sqrt = $(call f_sqrt_iter,$1,$(call f_sqrt_iter,$1,$(call f_sqrt_iter,$1,$(call f_sqrt_iter,$1,$(call f_div2,$1)))))

v_to_dec = $(call map,f_to_dec,$1)
v_add = $(call map2,f_add,$1,$2)
v_sub = $(call map2,f_sub,$1,$2)
v_mul = $(call map2,f_mul,$1,$2)
v_div = $(call map2,f_div,$1,$2)
v_dot = $(call reduce,f_add,$(call v_mul,$1,$2))
v_len_sq = $(call v_dot,$1,$1)
v_len = $(call f_sqrt,$(call v_len_sq,$1))
v_normalize2 = $(foreach x,$1,$(call f_div,$x,$2))
v_normalize = $(call v_normalize2,$1,$(call v_len,$1))
v_to_dec = $(call map,f_to_dec,$1)
v_scale = $(foreach x,$1,$(call f_mul,$x,$2))

sphere_test4 = $(or $(call f_is_positive,$(call f_sub,$1,$2)),$(call f_is_positive,$(call f_add,$1,$2)))
sphere_test3 = $(if $(call f_is_positive,$2),$(call sphere_test4,$1,$(call f_sqrt,$2)))
sphere_test2 = $(call sphere_test3,$1,$(call f_add,$(call f_sub,$(call f_sq,$1),$(call v_len_sq,$2)),$(call f_sq,$3)))
sphere_test = $(call sphere_test2,$(call v_dot,$1,$3),$1,$2)

w := $(call dec_to_s,$W)
h := $(call dec_to_s,$H)

f_w := $(call s_to_f,$w)
f_h := $(call s_to_f,$h)

range_h := $(call s_mk_range,+,$w)
range_v := $(call s_mk_range,+,$h)

pixel_to_world = $(call f_sub,$(call f_div,$(call f_add,$(call s_to_f,$1),$(f_half)),$2),$(f_half))
pixel_to_ray = $(call v_normalize,$(call pixel_to_world,$1,$(f_w)) $(call pixel_to_world,$2,$(f_h)) $(f_half))

s := + + $(call dec_to_f,+3)
r := $(call dec_to_f,+2)
l := $(call v_normalize,$(call dec_to_f,-1) $(call dec_to_f,-2) $(call dec_to_f,+3))

ramp := N . ' ^ " , : ; I l ! i > < ~ + _ - ? ] [ } { 1 ) ( | \ / t f j r x n u v c z X Y U J C L Q 0 O Z m w q p d b k h a o * \# M W & 8 % B @ $$
# ramp := N . : - = + * \# % @
ramp_len := $(call dec_to_f,$(call words,$(ramp)))
intensity_to_char = $(word $(call u_to_dec,0$(call s_to_u,$(call f_ipart,$(call f_mul,$1,$(ramp_len))))),$(ramp) $$)

color_sphere2 = $(call intensity_to_char,$(call v_dot,$1,$l))
color_sphere = $(call color_sphere2,$(call v_normalize,$(call v_sub,$(call v_scale,$1,$2))))

trace2 = $(if $2,$(call color_sphere,$1,$2),N)
trace = $(call trace2,$1,$(call sphere_test,$s,$r,$1))

trace_h = $(foreach x,$(range_h),$(call trace,$(call pixel_to_ray,$x,$1)))
trace_v_at = $(subst N, ,$(call implode,$(call trace_h,$1)))
trace_v = $(foreach y,$(range_v),$(info $(call trace_v_at,$y)))

_ := $(call trace_v)
