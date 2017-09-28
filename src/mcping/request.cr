require "uvarint"

# The request class is used internally by both the ping and query functions.
#
# It likely does not have anything terribly interesting for external use.
class MCPing::Request
  PROTOCOL_VERSION = 0x47_u8

  # Finalizes a packet to be sent.
  #
  # It adds the size of the bytes as a uvarint to the beginning then
  # appends the provided bytes.
  def createPacket(pl : Bytes)
    arr = [] of UInt8

    i = UVarInt.new pl.size.to_big_i
    arr.concat i.bytes
    arr.concat pl

    Slice.new arr.to_unsafe, arr.size
  end

  # Creates a handshake packet.
  #
  # Requires the server host and port for creating a correct packet.
  def createHandshake(host : String, port : UInt32)
    arr = [] of UInt8

    arr.push 0x00_u8
    arr.push PROTOCOL_VERSION

    i = UVarInt.new host.size.to_u32
    arr.concat i.bytes
    arr.concat host.bytes

    p = Bytes.new 2
    IO::ByteFormat::BigEndian.encode(port.to_i16, p)
    arr.concat p

    arr.push 0x01_u8

    Slice.new arr.to_unsafe, arr.size
  end

  # Makes the packet for a status request. It's a very simple packet.
  def createStatusRequest
    arr = [] of UInt8

    arr.push 0x00_u8

    Slice.new arr.to_unsafe, arr.size
  end

  # Reads a varint from a `TCPSocket`.
  def readVarInt(conn : TCPSocket)
    x = 0.to_big_i
    s = 0
    len = 0

    while true
      b = Bytes.new 1
      conn.read(b)

      len += 1

      if b[0] < 0x80_u8
        return x | (b[0].to_big_i << s), len
      end

      x = x | ((b[0] & 0x7F_u8).to_big_i << s)

      s += 7
    end

    return x, len
  end

  # Reads a varint from an UInt8 Array.
  def readVarInt(by : Array(UInt8))
    x = 0.to_big_i
    s = 0
    len = 0

    while true
      b = by[len]

      len += 1

      if b < 0x80_u8
        return x | (b.to_big_i << s), len
      end

      x = x | ((b & 0x7F_u8).to_big_i << s)

      s += 7
    end

    return x, len
  end

  # Reads the ping response data from the socket.
  def readStatus(conn : TCPSocket)
    len, _ = readVarInt conn

    data = Bytes.new len
    conn.read_fully(data)

    data_arr = data.to_a

    _, l1 = readVarInt data_arr
    _, l2 = readVarInt data_arr[l1..data_arr.size]

    json_data = data_arr[l1 + l2..data_arr.size]

    String.new Slice.new json_data.to_unsafe, json_data.size
  end
end
