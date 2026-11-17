# Operation Vulnex — DVWA × Metasploit Lab Kit

A runnable, self-contained kit for the Operation Vulnex lab: DVWA in Docker as
the target, Metasploit as the weapon, and a set of small scripts that drive each
phase so you can focus on learning the technique, not typing long commands.

> Authorized, isolated training only. Everything targets the local `dvwa`
> container on your own machine. Full ethics brief is in the lab manual.
>
> **New here?** On Windows, open your **Ubuntu (WSL)** terminal and run
> `./scripts/install-ubuntu.sh` — it installs Docker and all the tools for you.
> Then follow the lab manual.

## Quick start

**Windows (WSL2 + Ubuntu) — most students:** open the **Ubuntu** terminal, put the
kit in your Linux home (`~`, not `/mnt/c`), then:
```bash
./scripts/install-ubuntu.sh    # installs Docker (inside WSL) + Metasploit, nmap, hydra, sqlmap
# reopen the Ubuntu terminal so the docker group applies, then:
cp lab.env.example lab.env     # LHOST default 172.17.0.1 is correct for WSL
./scripts/00-setup.sh          # start DVWA; prints the addresses you need
./scripts/90-verify.sh         # confirm tools + target are ready
```

**macOS / Kali:** install the tools (see the manual's setup section), then run the
same `00-setup.sh` → `cp lab.env.example lab.env` → `90-verify.sh`.

Then follow the **lab manual** (provided in your course's Teams / Notion space —
English and pt-PT), working the numbered scripts as you reach each phase.

## What's inside
| Path | Purpose |
| --- | --- |
| `docker-compose.yml` | The DVWA target (port 42080) |
| `lab.env.example` | RHOST / LHOST / ports — copy to `lab.env` |
| `scripts/install-ubuntu.sh` | One-shot Ubuntu/WSL setup: Docker + Metasploit + nmap/hydra/sqlmap |
| `scripts/00-setup.sh` | Start DVWA, print container IP and the LHOST for your platform |
| `scripts/10-payloads.sh` | Build the Phase 2 + Phase 3 payloads with msfvenom |
| `scripts/20-handler-cmd.sh` | Phase 2 handler (reverse bash) |
| `scripts/21-handler-php.sh` | Phase 3 handler (PHP Meterpreter) |
| `scripts/30-recon.sh` | Phase 0 recon into the Metasploit DB |
| `scripts/40-brute.sh` | Phase 1 Hydra brute force (needs PHPSESSID) |
| `scripts/50-sqli.sh` | Boss 4 sqlmap dump (needs PHPSESSID) |
| `scripts/get-session.sh` | Log into DVWA and print a live PHPSESSID |
| `scripts/90-verify.sh` | Environment self-check |
| `scripts/99-reset.sh` | Reset DVWA between runs |
| `wordlists/` | Bundled password list for the brute-force phase |

## Requirements
Docker, plus Metasploit, Hydra, Nmap, and sqlmap on the attacker side.
- **Windows:** WSL2 with Ubuntu. Run `./scripts/install-ubuntu.sh` once — it installs
  Docker Engine *inside* WSL and all four tools. (Docker runs in the distro, so the
  reverse-shell callback address is simply the `docker0` gateway, `172.17.0.1`.)
- **macOS:** Homebrew for the tools, OrbStack or Docker Desktop for the container.
- **Kali/Linux:** all four tools via `apt`; `docker.io` for the container.

## Prefer app + db compose?
This kit uses the single `vulnerables/web-dvwa` image for zero-config startup.
If you want the maintained split image, swap the service for
`ghcr.io/digininja/dvwa` with its companion MariaDB — the lab steps are identical.
