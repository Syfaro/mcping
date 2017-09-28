require "./spec_helper"

describe MCPing do
  describe MCPing::Request do
    req = MCPing::Request.new

    it "creates a status request" do
      status = req.createStatusRequest
      status.should eq Bytes[0]
    end

    it "creates a handshake" do
      handshake = req.createHandshake "syfaro.net", 25565_u32
      handshake.should eq Bytes[
        0, 71, 10, 115,
        121, 102, 97, 114,
        111, 46, 110, 101,
        116, 99, 221, 1,
      ]

      handshake = req.createHandshake "mc.syfaro.net", 12345_u32
      handshake.should eq Bytes[
        0, 71, 13, 109,
        99, 46, 115, 121,
        102, 97, 114, 111,
        46, 110, 101, 116,
        48, 57, 1,
      ]
    end

    it "creates a packet" do
      packet = req.createPacket req.createStatusRequest
      packet.should eq Bytes[1, 0]

      packet = req.createPacket req.createHandshake "syfaro.net", 25565_u32
      packet.should eq Bytes[
        16, 0, 71, 10,
        115, 121, 102, 97,
        114, 111, 46, 110,
        101, 116, 99, 221,
        1,
      ]
    end
  end

  describe MCPing::Ping do
    it "pings a server" do
      # TODO: not rely on a 3rd party server
      pinger = MCPing::Ping.new "c.nerd.nu"
      ping = pinger.ping

      ping.should_not be_nil
    end

    it "fails on invalid servers" do
      pinger = MCPing::Ping.new "asdfasdf"

      expect_raises(Socket::Error) { pinger.ping }
    end
  end

  describe MCPing::Query do
    it "queries a server" do
      # TODO: not rely on a 3rd party server
      querier = MCPing::Query.new "play.phanaticmc.com"
      query = querier.query

      query.should_not be_nil
    end

    it "fails on invalid servers" do
      querier = MCPing::Query.new "asdfasdf"

      expect_raises(Socket::Error) { querier.query }
    end
  end
end
