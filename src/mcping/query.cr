require "json"
require "socket"

# Queries a Minecraft server.
class MCPing::Query
  enum QueryType
    Basic
    Full
  end

  # A basic response from a server query.
  #
  # Note that numeric fields are still represented as strings, as that is
  # how the server returns them.
  struct QueryBasic
    property motd : String?
    property gametype : String?
    property map : String?
    property numplayers : String?
    property maxplayers : String?
    property hostport : Int16?
    property hostip : String?

    def initialize(@motd = nil, @gametype = nil, @map = nil, @numplayers = nil, @maxplayers = nil, @hostport = nil, @hostip = nil)
    end
  end

  # A full response from a server query.
  #
  # Note that numeric fields are still represented as strings, as that is
  # how the server returns them.
  struct QueryFull
    property hostname : String?
    property gametype : String?
    property game_id : String?
    property version : String?
    property plugins : String?
    property map : String?
    property numplayers : String?
    property maxplayers : String?
    property hostport : String?
    property hostip : String?
    property players : Array(String)

    def initialize(@hostname = nil, @gametype = nil, @game_id = nil, @version = nil, @plugins = nil, @map = nil, @numplayers = nil, @maxplayers = nil, @hostport = nil, @hostip = nil, @players = [] of String)
    end
  end

  # Creates a new querier.
  #
  # Requires the server's domain name or IP address and port number.
  def initialize(@ip : String, @port : UInt32 = 25565_u32, @qtype = QueryType::Basic)
    @req = Request.new
  end

  # Reads a string until a null byte is received from the server.
  private def stringUntilNull(client : UDPSocket)
    buffer = String::Builder.new

    while true
      char = client.read_byte

      if !char || char == 0x00_u8
        return buffer.to_s
      end

      buffer << char.chr
    end

    buffer.to_s
  end

  # Sends the ping request.
  #
  # TODO: Options for changing the timeouts from 2 seconds.
  def query
    client = UDPSocket.new
    client.connect @ip, @port
    client.read_timeout = 2

    id = Random.new.rand(1..2147483647) & 0x0F0F0F0F
    encoded_id = Bytes.new 4
    IO::ByteFormat::BigEndian.encode id, encoded_id

    handshake = Slice[
      # magic bytes
      0xFE_u8,
      0xFD_u8,

      # type
      0x09_u8,

      # session ID
      encoded_id[0],
      encoded_id[1],
      encoded_id[2],
      encoded_id[3],
    ]

    client.write handshake

    resp = Bytes.new 1
    client.read_fully resp

    sess = Bytes.new 4
    client.read_fully sess

    challenge = stringUntilNull client
    challenge_num = challenge.to_i32

    encoded_challenge = Bytes.new 4
    IO::ByteFormat::BigEndian.encode challenge_num, encoded_challenge

    request = [
      # magic bytes
      0xFE_u8,
      0xFD_u8,

      # type
      0x00_u8,
    ]

    request.concat encoded_id
    request.concat encoded_challenge

    if @qtype == QueryType::Full
      request.concat [
        # 8 bytes of padding for magic
        0x00_u8,
        0x00_u8,
        0x00_u8,
        0x00_u8,
      ]
    end

    client.write Slice.new request.to_unsafe, request.size

    resp = Bytes.new 1
    client.read_fully resp

    sess = Bytes.new 4
    client.read_fully sess

    case @qtype
    when QueryType::Basic
      motd = stringUntilNull client
      gametype = stringUntilNull client
      map = stringUntilNull client
      numplayers = stringUntilNull client
      maxplayers = stringUntilNull client
      hostport = Bytes.new 2
      client.read hostport
      port = IO::ByteFormat::LittleEndian.decode Int16, hostport
      hostip = stringUntilNull client

      return QueryBasic.new motd, gametype, map, numplayers, maxplayers, port, hostip
    when QueryType::Full
      garbage = Bytes.new 11
      client.read_fully garbage

      q = QueryFull.new

      while true
        key = stringUntilNull client
        break if key == ""
        val = stringUntilNull client

        case key
        when "hostname"
          q.hostname = val
        when "gametype"
          q.gametype = val
        when "game_id"
          q.game_id = val
        when "version"
          q.version = val
        when "plugins"
          q.plugins = val
        when "map"
          q.map = val
        when "numplayers"
          q.numplayers = val
        when "maxplayers"
          q.maxplayers = val
        when "hostport"
          q.hostport = val
        when "hostip"
          q.hostip = val
        end
      end

      garbage = Bytes.new 10
      client.read_fully garbage

      while true
        player = stringUntilNull client
        break if player == ""

        q.players << player
      end

      return q
    end
  end
end
