Some uselfull alias and function in bash
----------------------------------------

Some aliases 
```bash
# standard conf
alias me="echo $USER"
alias WORKSPACE="cd ~/workspace"

# git alias
alias gt="git tree"
alias gs="git status"
alias gf="git fetch"
alias gu="git update"
alias gb="git branch"
alias gsw="git swich"
```

Change directory
```bash
function changeDirectory {
	cd $1; ls -la
}
alias lcd=changeDirectory
```

Clean all snapshot from a secific date, by default 1 day 
cleanSnapshot <date?>
```bash
function cleadOldPackage {
	DATE=${1:-1}
	find $HOME -type f -mtime +$DATE -iname "*SNAPSHOT*" -exec rm -fr {} \;
}

```

Clean all docker images
```bash
docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
```

Extract archive
```bash
function extract {
	if [ -f $1 ] ; then 
	    case $1 in 
	        *.tar.bz2)   tar xjf $1     ;; 
	        *.tar.gz)    tar xzf $1     ;; 
	        *.bz2)       bunzip2 $1     ;; 
	        *.rar)       unrar e $1     ;; 
	        *.gz)        gunzip $1      ;; 
	        *.tar)       tar xf $1      ;; 
	        *.tbz2)      tar xjf $1     ;; 
	        *.tgz)       tar xzf $1     ;; 
	        *.zip)       unzip $1       ;; 
	        *.Z)         uncompress $1  ;; 
	        *.7z)        7z x $1        ;; 
	        *)     echo "'$1' cannot be extracted via extract()" ;; 
	    esac 
	else 
	         echo "'$1' is not a valid file" 
	fi 
}
```

Get file encoding
```bash
function fileEncoding {
	if [[ -f $1 ]]; then
		file -Ib $1
	else
		echo "'$1' is not a file"
	fi

}
```

Create a local ftp on mac
```bash
stop_local_ftp() {
	sudo -s launchctl unload -w /System/Library/LaunchDaemons/ftp.plist
}

start_local_ftp() {
	sudo -s launchctl load -w /System/Library/LaunchDaemons/ftp.plist
}
```

Clean all shell history
```bash
fucntion cleanHistory {
	history -c
	history -w

	if [ -e "$HOME/.bash_history" ]; then
		cat /dev/null > $HOME/.bash_history && history -c
	fi

	if [ -e "$HOME/.zsh_history" ]; then
		cat /dev/null > $HOME/.zsh_history && history -c
	fi

	exit
}
```

Http server with python
```bash
python -m SimpleHTTPServer
```

Change all file extension
```bash
function usage {
	echo 'usage "rename $1 $2"'
	exit 1
}

[[ $# -ne 2 ]] && usage

for i in *.$1; do mv "$i" "`basename $i .$1`.$2"; done
```

Find in current folder
```bash
function search {
	if [ "$#" -ne 1 ]; then
		echo "usage : search <param>"
	else
		find . -iname "*$1*"
	fi
}
```

Grep on running process
```bash
function process {
	ps aux | grep $1
}
```

Show open port
```bash
sudo lsof -iTCP -sTCP:LISTEN -P -n
```

Update auto all outdated libraries on mac
```bash
brew update && brew upgrade `brew outdated`
```

Get uptime
```bash
uptime | awk '{ print "Uptime:", $3, $4, $5 }' | sed 's/,//g'
```

Watch on cmd
```bash
watch -d -n 1 $1
```
List metadata from file 
```bash
mdls <file>
```

Edit picture metadata
```
xattr -w com.apple.metadata:<datatype> <data> <file>
#Ex 
xattr -w com.apple.metadata:kMDItemWhereFroms <data> <file>
``` 
