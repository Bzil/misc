# Some usefull custom git config 

### Add it in .gitconfig file

```bash
[user]
	name = Bzil
[core]
	excludesfile = $HOME/.gitignore_global
[alias]
	# Show all commit tree 
	tree = log --all --graph --decorate --pretty=oneline --abbrev-commit 
	otherTree = log --all --graph --color  --format='%C(yellow)%h%Creset %cr -%C(auto)%d%Creset %s - %C(blue)%cn%Creset'
	
	# Show branch commit
	bTree = log --all --graph --decorate --pretty=oneline --abbrev-commit 
	otherBTree = log --all --graph --color  --format='%C(yellow)%h%Creset %cr -%C(auto)%d%Creset %s - %C(blue)%cn%Creset'
	

	# Update project without merge, remove delete branches
	update = "!u() { git fetch && git fetch -p -t; }; u"
	
	# Show the diff between the latest commit and the current state
	show = !"git diff-index --quiet HEAD -- || clear; git --no-pager diff --patch-with-stat"
	
	# Switch to a branch, creating it if necessary
	switch = "!f() { git checkout -b \"$1\" 2> /dev/null || git checkout \"$1\"; }; f"

	# Interactive rebase with the given number of latest commits
	interactive = "!r() { git rebase -i HEAD~$1; }; r"

[color]
       branch = auto
       diff = auto
       interactive = auto
       status = auto

[push]
	default = simple

[pull]
	rebase = true
```
