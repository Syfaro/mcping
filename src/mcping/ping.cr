require "json"
require "socket"

# Pings a Minecraft server.
class MCPing::Ping
  # Version information about the server.
  struct PingVersion
    JSON.mapping(
      name: String,
      protocol: Int32,
    )
  end

  # Player information.
  struct PingPlayers
    JSON.mapping(
      max: Int32,
      online: Int32,
    )
  end

  # Server MOTD.
  struct PingDescription
    JSON.mapping(
      text: String,
    )
  end

  # Data from pinging a server.
  struct PingResponse
    JSON.mapping(
      version: PingVersion,
      players: PingPlayers,
      description: PingDescription,
      favicon: String,
    )
  end

  # Creates a new pinger.
  #
  # Requires the server's domain name or IP address and port number.
  def initialize(@ip : String, @port : UInt32 = 25565_u32)
    @req = Request.new
  end

  # Sends the ping request.
  #
  # TODO: Options for changing the timeouts from 2 seconds.
  def ping
    client = TCPSocket.new @ip, @port, dns_timeout: 2, connect_timeout: 2
    client.read_timeout = 2

    client.write @req.createPacket @req.createHandshake @ip, @port
    client.write @req.createPacket @req.createStatusRequest

    resp = PingResponse.from_json @req.readStatus client

    client.close

    resp
  end
end
