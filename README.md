# mcping

Crystal implementation of Minecraft server pinging and querying.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  mcping:
    github: Syfaro/mcping
```

## Usage

```crystal
require "mcping"

pinger = MCPing::Ping.new "c.nerd.nu"
ping = pinger.ping

querier = MCPing::Query.new "play.phanaticmc.com"
query = querier.query
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/Syfaro/mcping/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Syfaro](https://github.com/Syfaro) - creator, maintainer
