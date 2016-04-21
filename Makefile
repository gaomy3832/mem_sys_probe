

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

MNTHUGETLBFS := mnt-hugetlbfs

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
ifneq (0,$(HUGEPAGE))
	@mkdir -p $(MNTHUGETLBFS)
	@sudo mount -t hugetlbfs none $(MNTHUGETLBFS) \
		-o uid=$(shell id -u),gid=$(shell id -g)
	@LD_LIBRARY_PATH=$(LD_LIBRARY_PATH):$(LIBHUGETLBFSDIR)/lib64 \
		$(LIBHUGETLBFSDIR)/bin/hugectl --text --data --bss $(BINDIR)/$(PROG) \
		|| { echo -e "\nEnsure enough huge pages in the pool.\n"; \
		$(LIBHUGETLBFSDIR)/bin/hugeadm --pool-list; \
		exit 1; }
	@sudo umount $(MNTHUGETLBFS)
	@rm -rf $(MNTHUGETLBFS)
else
	@$(BINDIR)/$(PROG)
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
	@sudo umount $(MNTHUGETLBFS)
	@rm -rf $(MNTHUGETLBFS)

.PHONY: clean check_libhugetlbfs run

