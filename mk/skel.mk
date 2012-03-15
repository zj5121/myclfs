# skeletons and functions

define include_submk
dir_stack := $(d) $(dir_stack)
d := $(d)/$(1)
include $(addsuffix /Rules.mk,$$(d))
d := $$(firstword $$(dir_stack))
dir_stack := $$(wordlist 2,$$(words $$(dir_stack)),$$(dir_stack))
endef