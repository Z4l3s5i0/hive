# Converts decimal string to number.
def to_int:
  if . == null then . else .|tonumber end
;

# Converts "1" / "0" to boolean.
def to_bool:
  if . == null then . else
    if . == "1" then true else false end
  end
;

# Check for unsupported forks
def check_forks:
  if env.HIVE_CANCUN_TIMESTAMP != null then error("Cancun fork not supported by wasix-eth") else . end |
  if env.HIVE_PRAGUE_TIMESTAMP != null then error("Prague fork not supported by wasix-eth") else . end |
  if env.HIVE_OSAKA_TIMESTAMP != null then error("Osaka fork not supported by wasix-eth") else . end
;

# Replace config in input.
. + {
  "config": (
    .config + {
      "chainId": (env.HIVE_CHAIN_ID|to_int // .config.chainId),
      "homesteadBlock": (env.HIVE_FORK_HOMESTEAD|to_int // .config.homesteadBlock),
      "daoForkBlock": (env.HIVE_FORK_DAO_BLOCK|to_int // .config.daoForkBlock),
      "eip150Block": (env.HIVE_FORK_TANGERINE|to_int // .config.eip150Block),
      "eip155Block": (env.HIVE_FORK_SPURIOUS|to_int // .config.eip155Block),
      "eip158Block": (env.HIVE_FORK_SPURIOUS|to_int // .config.eip158Block),
      "byzantiumBlock": (env.HIVE_FORK_BYZANTIUM|to_int // .config.byzantiumBlock),
      "constantinopleBlock": (env.HIVE_FORK_CONSTANTINOPLE|to_int // .config.constantinopleBlock),
      "petersburgBlock": (env.HIVE_FORK_PETERSBURG|to_int // .config.petersburgBlock),
      "istanbulBlock": (env.HIVE_FORK_ISTANBUL|to_int // .config.istanbulBlock),
      "berlinBlock": (env.HIVE_FORK_BERLIN|to_int // .config.berlinBlock),
      "londonBlock": (env.HIVE_FORK_LONDON|to_int // .config.londonBlock),
      "shanghaiTime": (env.HIVE_SHANGHAI_TIMESTAMP|to_int // .config.shanghaiTime),
      "terminalTotalDifficulty": (env.HIVE_TERMINAL_TOTAL_DIFFICULTY|to_int // .config.terminalTotalDifficulty)
    }
  )
} | check_forks
