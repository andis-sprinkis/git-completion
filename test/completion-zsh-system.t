#!/bin/sh
#
# Copyright (c) 2012-2020 Felipe Contreras
#

test_description='test zsh official completion'

. ./lib-bash.sh

if ! test_have_prereq ZSH; then
	skip_all='skipping complete-zsh tests; zsh not available'
	test_done
fi

export SRC_DIR
export TEST_FPATH=

run_completion ()
{
	"$SRC_DIR/test/zsh/completion" "$1" > out
	[[ -s out ]] || { echo > out ; }
}

test_completion ()
{
	if test $# -gt 1
	then
		printf '%s\n' "$2" >expected
	else
		sed -e 's/[ \.=]\?Z$//' | sort | uniq -u >expected
	fi &&
	run_completion "$1" &&
	sort out | uniq -u >out_sorted &&
	test_cmp expected out_sorted
}

if test_have_prereq MINGW
then
	ROOT="$(pwd -W)"
else
	ROOT="$(pwd)"
fi

test_expect_success 'setup for ref completion' '
	git commit --allow-empty -m initial &&
	git branch matching-branch &&
	git tag matching-tag &&
	(
		git init otherrepo &&
		cd otherrepo &&
		git commit --allow-empty -m initial &&
		git branch -m master master-in-other &&
		git branch branch-in-other &&
		git tag tag-in-other
	) &&
	git remote add other "$ROOT/otherrepo/.git" &&
	git fetch --no-tags other &&
	rm -f .git/FETCH_HEAD &&
	git init thirdrepo
'

test_expect_success 'git switch - with no options, complete local branches and unique remote branch names for DWIM logic' '
	test_completion "git switch " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - completes refs and unique remote branches for DWIM' '
	test_completion "git checkout " <<-\EOF
	HEAD Z
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with --no-guess, complete only local branches' '
	test_completion "git switch --no-guess " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - a later --guess overrides previous --no-guess, complete local and remote unique branches for DWIM' '
	test_completion "git switch --no-guess --guess " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - a later --no-guess overrides previous --guess, complete only local branches' '
	test_completion "git switch --guess --no-guess " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - with --no-guess, only completes refs' '
	test_completion "git checkout --no-guess " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git checkout - a later --guess overrides previous --no-guess, complete refs and unique remote branches for DWIM' '
	test_completion "git checkout --no-guess --guess " <<-\EOF
	HEAD Z
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git checkout - a later --no-guess overrides previous --guess, complete only refs' '
	test_completion "git checkout --guess --no-guess " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - with --detach, complete all references' '
	test_completion "git switch --detach " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with --detach, complete only references' '
	test_completion "git checkout --detach " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - with -d, complete all references' '
	test_completion "git switch -d " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git checkout - with -d, complete only references' '
	test_completion "git checkout -d " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - with --track, complete only remote branches' '
	test_completion "git switch --track " <<-\EOF
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with --track, complete only remote branches' '
	test_completion "git checkout --track " <<-\EOF
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with --no-track, complete only local branch names' '
	test_completion "git switch --no-track " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git checkout - with --no-track, complete only local references' '
	test_completion "git checkout --no-track " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - with -c, complete all references' '
	test_completion "git switch -c new-branch " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - with -C, complete all references' '
	test_completion "git switch -C new-branch " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with -c and --track, complete all references' '
	test_completion "git switch -c new-branch --track " <<-EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with -C and --track, complete all references' '
	test_completion "git switch -C new-branch --track " <<-EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with -c and --no-track, complete all references' '
	test_completion "git switch -c new-branch --no-track " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_failure 'git switch - with -C and --no-track, complete all references' '
	test_completion "git switch -C new-branch --no-track " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b, complete all references' '
	test_completion "git checkout -b new-branch " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B, complete all references' '
	test_completion "git checkout -B new-branch " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b and --track, complete all references' '
	test_completion "git checkout -b new-branch --track " <<-EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B and --track, complete all references' '
	test_completion "git checkout -B new-branch --track " <<-EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -b and --no-track, complete all references' '
	test_completion "git checkout -b new-branch --no-track " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git checkout - with -B and --no-track, complete all references' '
	test_completion "git checkout -B new-branch --no-track " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'git switch - for -c, complete local branches and unique remote branches' '
	test_completion "git switch -c " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git switch - for -C, complete local branches and unique remote branches' '
	test_completion "git switch -C " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - for -c with --no-guess, complete local branches only' '
	test_completion "git switch --no-guess -c " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - for -C with --no-guess, complete local branches only' '
	test_completion "git switch --no-guess -C " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - for -c with --no-track, complete local branches only' '
	test_completion "git switch --no-track -c " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - for -C with --no-track, complete local branches only' '
	test_completion "git switch --no-track -C " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git checkout - for -b, complete local branches and unique remote branches' '
	test_completion "git checkout -b " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_failure 'git checkout - for -B, complete local branches and unique remote branches' '
	test_completion "git checkout -B " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -b with --no-guess, complete local branches only' '
	test_completion "git checkout --no-guess -b " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -B with --no-guess, complete local branches only' '
	test_completion "git checkout --no-guess -B " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -b with --no-track, complete local branches only' '
	test_completion "git checkout --no-track -b " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - for -B with --no-track, complete local branches only' '
	test_completion "git checkout --no-track -B " <<-\EOF
	master Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - with --orphan completes local branch names and unique remote branch names' '
	test_completion "git switch --orphan " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_failure 'git switch - --orphan with branch already provided completes nothing else' '
	test_completion "git switch --orphan master " <<-\EOF

	EOF
'

test_expect_failure 'git checkout - with --orphan completes local branch names and unique remote branch names' '
	test_completion "git checkout --orphan " <<-\EOF
	branch-in-other Z
	master Z
	master-in-other Z
	matching-branch Z
	EOF
'

test_expect_success 'git checkout - --orphan with branch already provided completes local refs for a start-point' '
	test_completion "git checkout --orphan master " <<-\EOF
	HEAD Z
	master Z
	matching-branch Z
	matching-tag Z
	other/branch-in-other Z
	other/master-in-other Z
	EOF
'

test_expect_success 'teardown after ref completion' '
	git branch -d matching-branch &&
	git tag -d matching-tag &&
	git remote remove other
'

test_expect_success 'setup for integration tests' '
	echo content >file1 &&
	echo more >file2 &&
	git add file1 file2 &&
	git commit -m one &&
	git branch mybranch &&
	git tag mytag
'

test_expect_success 'checkout completes ref names' '
	test_completion "git checkout m" <<-\EOF
	master Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_failure 'git -C <path> checkout uses the right repo' '
	test_completion "git -C subdir -C subsubdir -C .. -C ../otherrepo checkout b" <<-\EOF
	branch-in-other Z
	EOF
'

test_expect_failure 'show completes all refs' '
	test_completion "git show m" <<-\EOF
	master Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_success '<ref>: completes paths' '
	test_completion "git show mytag:f" <<-\EOF
	file1Z
	file2Z
	EOF
'

test_expect_success 'complete tree filename with spaces' '
	echo content >"name with spaces" &&
	git add "name with spaces" &&
	git commit -m spaces &&
	test_completion "git show HEAD:nam" <<-\EOF
	name with spacesZ
	EOF
'

test_expect_success 'complete tree filename with metacharacters' '
	echo content >"name with \${meta}" &&
	git add "name with \${meta}" &&
	git commit -m meta &&
	test_completion "git show HEAD:nam" <<-\EOF
	name with ${meta}Z
	name with spacesZ
	EOF
'

test_expect_failure PERL 'send-email' '
	test_completion "git send-email ma" "master " &&
	test_completion "git send-email --cov" <<-\EOF
	--cover-from-description=Z
	--cover-letter Z
	EOF
'

test_expect_failure 'complete files' '
	git init tmp && cd tmp &&
	test_when_finished "cd .. && rm -rf tmp" &&

	echo "expected" > .gitignore &&
	echo "out" >> .gitignore &&
	echo "out_sorted" >> .gitignore &&

	git add .gitignore &&
	test_completion "git commit " ".gitignore" &&

	git commit -m ignore &&

	touch new &&
	test_completion "git add " "new" &&

	git add new &&
	git commit -a -m new &&
	test_completion "git add " "" &&

	git mv new modified &&
	echo modify > modified &&
	test_completion "git add " "modified" &&

	mkdir -p some/deep &&
	touch some/deep/path &&
	test_completion "git add some/" "some/deep" &&
	git clean -f some &&

	touch untracked &&

	: TODO .gitignore should not be here &&
	test_completion "git rm " <<-\EOF &&
	.gitignore
	modified
	EOF

	test_completion "git clean " "untracked" &&

	: TODO .gitignore should not be here &&
	test_completion "git mv " <<-\EOF &&
	.gitignore
	modified
	EOF

	mkdir dir &&
	touch dir/file-in-dir &&
	git add dir/file-in-dir &&
	git commit -m dir &&

	mkdir untracked-dir &&

	: TODO .gitignore should not be here &&
	test_completion "git mv modified " <<-\EOF &&
	.gitignore
	dir
	modified
	untracked
	untracked-dir
	EOF

	test_completion "git commit " "modified" &&

	: TODO .gitignore should not be here &&
	test_completion "git ls-files " <<-\EOF &&
	.gitignore
	dir
	modified
	EOF

	touch momified &&
	test_completion "git add mom" "momified"
'

test_expect_failure "completion uses <cmd> completion for alias: !sh -c 'git <cmd> ...'" '
	test_config_global alias.co "!sh -c '"'"'git checkout ...'"'"'" &&
	test_completion "git co m" <<-\EOF
	master Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_failure 'completion uses <cmd> completion for alias: !f () { VAR=val git <cmd> ... }' '
	test_config_global alias.co "!f () { VAR=val git checkout ... ; } f" &&
	test_completion "git co m" <<-\EOF
	master Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_failure 'completion used <cmd> completion for alias: !f() { : git <cmd> ; ... }' '
	test_config_global alias.co "!f() { : git checkout ; if ... } f" &&
	test_completion "git co m" <<-\EOF
	master Z
	mybranch Z
	mytag Z
	EOF
'

test_expect_failure 'complete with tilde expansion' '
	git init tmp && cd tmp &&
	test_when_finished "cd .. && rm -rf tmp" &&

	touch ~/tmp/file &&

	test_completion "git add ~/tmp/" "~/tmp/file"
'

test_expect_success 'setup other remote for remote reference completion' '
	git remote add other otherrepo &&
	git fetch other
'

test_expect_success 'git config - section' '
	test_completion "git config br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_success 'git config - variable name' '
	test_completion "git config log.d" <<-\EOF
	date Z
	decorate Z
	EOF
'

test_expect_success 'git config - value' '
	test_completion "git config color.pager " <<-\EOF
	false Z
	true Z
	no Z
	yes Z
	on Z
	off Z
	EOF
'

test_expect_success 'git config - direct completions' '
	test_completion "git config branch.autoSetup" <<-\EOF
	autosetupmerge Z
	autosetuprebase Z
	EOF
'

test_expect_success 'git -c - section' '
	test_completion "git -c br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_success 'git -c - variable name' '
	test_completion "git -c log.d" <<-\EOF
	date=Z
	decorate=Z
	EOF
'

test_expect_success 'git -c - value' '
	test_completion "git -c color.pager=" <<-\EOF
	false Z
	true Z
	no Z
	yes Z
	on Z
	off Z
	EOF
'

test_expect_failure 'git clone --config= - section' '
	test_completion "git clone --config=br" <<-\EOF
	branch.Z
	browser.Z
	EOF
'

test_expect_failure 'git clone --config= - variable name' '
	test_completion "git clone --config=log.d" <<-\EOF
	log.date=Z
	log.decorate=Z
	EOF
'

test_expect_failure 'git clone --config= - value' '
	test_completion "git clone --config=color.pager=" <<-\EOF
	false Z
	true Z
	EOF
'

test_done
