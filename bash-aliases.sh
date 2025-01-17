# Add to ~/.bashrc or ~/.bash_aliases for some useful tools

# Docker audit
alias caudit='docker run -it --net host --pid host --cap-add audit_control -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock --label docker_bench_security docker/docker-bench-security'

# Ctop container resource visualization
alias ctop='docker run --rm -ti --name=ctop --volume /var/run/docker.sock:/var/run/docker.sock:ro quay.io/vektorlab/ctop:latest'
