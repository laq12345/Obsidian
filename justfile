save comment:
    @git add --all
    @git commit -m "{{ comment }}，just save"
    @git push

log:
    @git log --graph --pretty=oneline --abbrev-commit
