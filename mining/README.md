# Monero mining on a Mac

A setup script that installs [XMRig](https://github.com/xmrig/xmrig) and mines Monero (XMR) through the [SupportXMR](https://supportxmr.com) pool, using about half your CPU.

This is for learning, not income. A laptop earns roughly a few cents a day, often less than the electricity it uses.

## Before you start: make a wallet

The script can't make one for you, because only you should ever see your recovery words.

1. Install a Monero wallet: [Cake Wallet](https://cakewallet.com) (phone or Mac) or the official [Monero GUI Wallet](https://www.getmonero.org/downloads/).
2. Create a new wallet and **write down the seed phrase** on paper. Anyone who has it can take your coins, and without it you can't recover them.
3. Copy your wallet's **receive address**: a long string starting with `4` (or `8` for a subaddress).

## Install and run

1. Download `setup-mac.sh` from this folder.
2. Open **Terminal** (press Cmd+Space, type "Terminal", press Enter).
3. Run the script, replacing the path if you saved it somewhere other than Downloads:
   ```
   bash ~/Downloads/setup-mac.sh
   ```
4. Paste your wallet address when asked. The script downloads XMRig from its official GitHub page, checks the file against the published checksums, and installs it in `~/xmrig-miner`.
5. Answer `y` to start mining now, or start it later with:
   ```
   ~/xmrig-miner/start-mining.sh
   ```
6. To stop, press **Ctrl+C** in the Terminal window.

While it runs, XMRig prints your hashrate (guesses per second) about once a minute. A recent Mac typically does roughly 1,000–4,000 H/s.

## Checking your earnings

Go to [supportxmr.com](https://supportxmr.com) and paste your wallet address into the search box. It shows your hashrate and pending balance. The pool pays out once your balance reaches its minimum, which at laptop speeds can take weeks or months.

## Looking after your laptop

- **Keep it plugged in** and on a hard, flat surface so air can reach the vents.
- **Watch the heat.** Open Activity Monitor to check CPU load. If the laptop gets uncomfortably hot, or the fans stay at full speed, stop mining or lower the CPU share.
- **Lower or raise the CPU share** by editing `~/xmrig-miner/start-mining.sh` and changing `--cpu-max-threads-hint=50` to another percentage, such as `25`.
- **Don't leave it running 24/7.** Constant full load wears the battery for very little reward.
- **Don't use a work or school computer.** Mining usually breaks their usage policies.

## If something goes wrong

- **"xmrig cannot be opened because the developer cannot be verified":** open System Settings → Privacy & Security, scroll down, and click **Open Anyway** next to the xmrig message. Then run `start-mining.sh` again.
- **Antivirus warning:** security tools often flag XMRig because criminals hide it in malware. This script only downloads it from the official GitHub releases and verifies the checksum, so the warning is expected here.
- **"checksum mismatch":** the download was corrupted or altered, so nothing was installed. Run the script again; if it keeps happening, don't proceed.

## Uninstall

```
rm -rf ~/xmrig-miner
```
