setopt zle
setopt list_rows_first

LC_ALL=C
PS1="<PROMPT>"
TERM=dumb
fpath=(${TEST_FPATH-$ZDOTDIR} $fpath)
LISTMAX=1000 # There seems to be a bug in zsh with several thousands

autoload -U compinit && compinit -u

zstyle ":completion:*:default" list-colors "no=<NO>" "fi=<NO>" "di=<NO>" "sp=<SP>" "lc=<LC>" "rc=<RC>" "ec=<EC>\n"
zstyle ':completion:*' verbose no

zle_complete () {
	zle list-choices
	zle kill-whole-line
	print "<END-CHOICES>"
}
zle -N zle_complete
bindkey "^I" zle_complete

functions[_default]=:

functions[__git_commit_objects_prefer_recent]=:
