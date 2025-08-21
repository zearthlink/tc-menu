# tc-menu v2.4

Menu-driven `tc/netem` controller for inline L2 bridges (Raspberry Pi friendly).

- Presets, custom NETEM, DSCP-targeted flows, timed scenarios
- Optional HTB(root) → class 1:1 → child NETEM via `RATE_CAP`
- Logging to `/var/log/tc-menu.log`, dry-run mode, offload toggler

## Run
```bash
sudo /usr/local/sbin/tc-menu.sh
```

## License
MIT (see `LICENSE`).
