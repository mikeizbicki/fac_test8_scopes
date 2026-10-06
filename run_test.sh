#!/bin/bash

# This test verifies that fac.yaml scopes work as intended.
# See fac.yaml for the list of features covered.

source ../framework.sh

# Prints each built file's path and contents, in deterministic order.
# We show contents (not just `ls -R`) because the interesting thing
# in a scope test is variable substitution, which only appears in
# file contents.
show_files() {
    for f in $(find . -name "*.txt" -not -path "./.*" | sort); do
        echo "=== $f ==="
        cat "$f"
    done
}

# Build each target from a clean repo.
# Building from scratch isolates the behavior of one target from the
# effects of any previously-built targets; this matters because
# scope-level dependency inheritance means that building, e.g.,
# scope1/a.txt also builds top.txt.

reset_git
fac 'top.txt'
show_files | dotest checkpoint_top

reset_git
fac 'scope1/a.txt'
show_files | dotest checkpoint_a

reset_git
fac 'scope1/b.txt'
show_files | dotest checkpoint_b

reset_git
fac 'scope1/c.txt'
show_files | dotest checkpoint_c

reset_git
fac 'scope1/deep/d.txt'
show_files | dotest checkpoint_d

reset_git
fac 'other/e.txt'
show_files | dotest checkpoint_e

# Build everything in an order chosen to differ from the
# "natural" file-system order, and check the final state.
# This is where we catch state-dependence bugs (e.g. context
# merging across sibling scopes).
reset_git
fac 'other/e.txt'
fac 'scope1/deep/d.txt'
fac 'scope1/b.txt'
fac 'top.txt'
fac 'scope1/c.txt'
fac 'scope1/a.txt'
show_files | dotest checkpoint_all

# Rerun every command. Since nothing was modified, all builds must be
# no-ops and the state must be unchanged.
fac 'other/e.txt'
fac 'scope1/deep/d.txt'
fac 'scope1/b.txt'
fac 'top.txt'
fac 'scope1/c.txt'
fac 'scope1/a.txt'
show_files | dotest checkpoint_all

# Rerun in a different order, again expecting no-ops.
fac 'scope1/c.txt'
fac 'top.txt'
fac 'scope1/a.txt'
fac 'scope1/deep/d.txt'
fac 'scope1/b.txt'
fac 'other/e.txt'
show_files | dotest checkpoint_all

finalize_tests
