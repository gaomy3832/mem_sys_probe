
DISABLE_PREFETCH ?= 0

HUGEPAGE ?= 0
LIBHUGETLBFSDIR ?= /usr/local

################################################################################

SRCDIR := src
BINDIR := bin

PROG := aca_ch2_cs2

CFLAGS = -O0 -g

ifneq (0,$(HUGEPAGE))
  LDFLAGS = -B $(LIBHUGETLBFSDIR)/share/libhugetlbfs \
			-Wl,--hugetlbfs-align \
			-L$(LIBHUGETLBFSDIR)/lib64
endif

################################################################################

default: $(BINDIR)/$(PROG)

################################################################################

$(BINDIR)/$(PROG): $(SRCDIR)/$(PROG).c | $(BINDIR)
	gcc -o $@ $< $(CFLAGS) $(LDFLAGS) -MP -MMD

-include $(wildcard $(BINDIR)/*.d)

$(BINDIR):
	@mkdir -p $(BINDIR)

################################################################################

run: $(BINDIR)/$(PROG)
ifneq (0,$(DISABLE_PREFETCH))
	@./scripts/prefetch_ctrl.sh -d
endif
ifneq (0,$(HUGEPAGE))
	@./scripts/mount_hugetlbfs.sh -m
	@LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(LIBHUGETLBFSDIR)/lib64 \
		$(LIBHUGETLBFSDIR)/bin/hugectl --text --data --bss $(BINDIR)/$(PROG) \
		|| { echo -e "\nEnsure enough huge pages in the pool.\n"; \
		$(LIBHUGETLBFSDIR)/bin/hugeadm --pool-list; \
		exit 1; }
	@./scripts/mount_hugetlbfs.sh -u
else
	@$(BINDIR)/$(PROG)
endif
ifneq (0,$(DISABLE_PREFETCH))
	@./scripts/prefetch_ctrl.sh -e
endif


check_libhugetlbfs:
	@if [ "$(HUGEPAGE)" -ne "0" ] \
		&& [ ! -f $(LIBHUGETLBFSDIR)/lib64/libhugetlbfs.so ]; then \
		echo -e "\nlibhugetlbfs is not installed or LIBHUGETLBFSDIR is not set.\n"; \
		exit 1; fi

$(BINDIR)/$(PROG): check_libhugetlbfs

run: check_libhugetlbfs


clean:
	@$(RM) -rf $(BINDIR)
	@./scripts/mount_hugetlbfs.sh -u
	@./scripts/prefetch_ctrl.sh -e

.PHONY: clean check_libhugetlbfs run

