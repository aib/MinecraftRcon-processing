import java.io.UnsupportedEncodingException;
import java.util.TimerTask;
import java.util.Timer;
import processing.net.Client;

public class MinecraftRcon extends PApplet
{
  public static final int LOGIN_TIMEOUT = 10;
  public static final int COMMAND_TIMEOUT = 10;

  private static final int LOGINSTATE_NONE = 0;
  private static final int LOGINSTATE_SUCCESS = 1;
  private static final int LOGINSTATE_FAIL = 2;
  private static final int LOGINSTATE_TIMEOUT = 3;

  private ByteBuffer receiveBuffer;
  private Client client;
  private int requestId;
  private String rconPassword;

  private int loginState = LOGINSTATE_NONE;
  private boolean commandInProgress = false;
  private MinecraftRconPacket commandResponsePacket = null;

  public MinecraftRcon(String serverAddress, int rconPort, String rconPassword)
  {
    this.receiveBuffer = ByteBuffer.allocate(4096);
    this.client = new Client(this, serverAddress, rconPort);
    this.rconPassword = rconPassword;
    this.requestId = int(random(1000000, 10000000));
  }

  public boolean login()
  {
    final MinecraftRcon mcr = this;
    TimerTask loginTimeout = new TimerTask() {
      public void run() {
        println("Login timeout");
        if (mcr.loginState == LOGINSTATE_NONE) {
          mcr.loginState = LOGINSTATE_TIMEOUT;
        }
      }
    };

    MinecraftRconPacket loginPacket = new MinecraftRconPacket();
    loginPacket.requestId = requestId;
    loginPacket.type = MinecraftRconPacket.TYPE_LOGIN;
    loginPacket.payload = stringToBytes(rconPassword);

    new Timer().schedule(loginTimeout, LOGIN_TIMEOUT * 1000);
    sendPacket(loginPacket);

    while (loginState == LOGINSTATE_NONE) {
      delay(50);
    }

    loginTimeout.cancel();

    if (loginState == LOGINSTATE_SUCCESS) {
      return true;
    } else {
      return false;
    }
  }

  public String sendCommand(String command)
  {
    if (loginState != LOGINSTATE_SUCCESS) {
      return null;
    }

    if (commandInProgress) {
      return null;
    }

    final MinecraftRcon mcr = this;
    TimerTask commandTimeout = new TimerTask() {
      public void run() {
        println("Command timeout");
        if (commandInProgress) {
          commandInProgress = false;
        }
      }
    };

    MinecraftRconPacket commandPacket = new MinecraftRconPacket();
    commandPacket.requestId = requestId;
    commandPacket.type = MinecraftRconPacket.TYPE_COMMAND;
    commandPacket.payload = stringToBytes(command);

    commandInProgress = true;
    commandResponsePacket = null;

    new Timer().schedule(commandTimeout, COMMAND_TIMEOUT * 1000);
    sendPacket(commandPacket);

    while (commandInProgress) {
      delay(50);
    }

    commandTimeout.cancel();

    if (commandResponsePacket == null) {
      return null;
    } else {
      return bytesToString(commandResponsePacket.payload);
    }
  }

  private byte[] stringToBytes(String string)
  {
    byte[] bytes;

    try {
      bytes = string.getBytes("UTF-8");
    } catch (UnsupportedEncodingException e) {
      println("Exception converting String to bytes: " + e);
      bytes = new byte[0];
    }

    return bytes;
  }

  private String bytesToString(byte[] bytes)
  {
    String string;

    try {
      string = new String(bytes, "UTF-8");
    } catch (UnsupportedEncodingException e) {
      println("Exception converting bytes to String: " + e);
      string = "";
    }

    return string;
  }

  private void sendPacket(MinecraftRconPacket packet)
  {
//    println(
//      "Sending  packet with"
//      + " requestID " + packet.requestId
//      + " type " + packet.type
//      + " " + (packet.payload == null
//               ? "no payload"
//               : "payload \"" + bytesToString(packet.payload) + "\"" + " (" + packet.payload.length + ")")
//    );

    client.write(packet.toByteArray());
  }

  private void packetReceived(MinecraftRconPacket packet)
  {
//    println(
//      "Received packet with"
//      + " requestID " + packet.requestId
//      + " type " + packet.type
//      + " " + (packet.payload == null
//               ? "no payload"
//               : "payload \"" + bytesToString(packet.payload) + "\"" + " (" + packet.payload.length + ")")
//    );

    if (loginState == LOGINSTATE_NONE) {
      if (packet.requestId == requestId) {
        loginState = LOGINSTATE_SUCCESS;
      } else {
        loginState = LOGINSTATE_FAIL;
      }
      return;
    }

    if (commandInProgress) {
      commandResponsePacket = packet;
      commandInProgress = false;
    }
  }

  void clientEvent(Client client)
  {
    byte[] newBytes = client.readBytes();
    receiveBuffer.put(newBytes);

    int abSize = receiveBuffer.position();
    byte[] allBytes = new byte[abSize];
    receiveBuffer.rewind();
    receiveBuffer.get(allBytes);

    MinecraftRconPacket packet = new MinecraftRconPacket();
    int parseStatus = packet.parseFromByteArray(allBytes);

    if (parseStatus == MinecraftRconPacket.PACKET_PARSE_SUCCESS) {
      receiveBuffer.clear();
      packetReceived(packet);
    }
  }
}

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.BufferUnderflowException;

public class MinecraftRconPacket
{
  public static final int TYPE_RESPONSE = 0;
  public static final int TYPE_COMMAND = 2;
  public static final int TYPE_LOGIN = 3;

  public static final int PACKET_PARSE_SUCCESS = 0;
  public static final int PACKET_PARSE_ERROR_LENGTH = 1;
  public static final int PACKET_PARSE_ERROR_BUFFER_SIZE = 2;
  public static final int PACKET_PARSE_ERROR_PAYLOAD = 3;
  public static final int PACKET_PARSE_ERROR_PADDING = 4;

  public int requestId;
  public int type;
  public byte[] payload;

  public byte[] toByteArray()
  {
    ByteBuffer packetBuffer = ByteBuffer.allocate(4096);
    packetBuffer.order(ByteOrder.LITTLE_ENDIAN);

    packetBuffer.putInt(0); //reserve for length
    packetBuffer.putInt(requestId);
    packetBuffer.putInt(type);
    packetBuffer.put(payload);
    packetBuffer.put((byte) 0); //padding
    packetBuffer.put((byte) 0); //padding

    int packetLength = packetBuffer.position();

    packetBuffer.putInt(0, packetLength - 4);

    packetBuffer.flip();
    byte[] bytes = new byte[packetLength];
    packetBuffer.get(bytes, 0, packetLength);

    return bytes;
  }

  public int parseFromByteArray(byte[] bytes)
  {
    try {
      ByteBuffer packetBuffer = ByteBuffer.wrap(bytes);
      packetBuffer.order(ByteOrder.LITTLE_ENDIAN);

      int packetLength = packetBuffer.getInt();

      if (packetLength != bytes.length - 4) {
        return PACKET_PARSE_ERROR_LENGTH;
      }

      int payloadLength = packetLength - 4 - 4 - 2;

      if (payloadLength < 0) {
        return PACKET_PARSE_ERROR_PAYLOAD;
      }

      this.requestId = packetBuffer.getInt();
      this.type = packetBuffer.getInt();
      byte[] payload = new byte[payloadLength];
      packetBuffer.get(payload);
      this.payload = payload;

      if (packetBuffer.get() != (byte) 0) {
        return PACKET_PARSE_ERROR_PADDING;
      }

      if (packetBuffer.get() != (byte) 0) {
        return PACKET_PARSE_ERROR_PADDING;
      }

      return PACKET_PARSE_SUCCESS;
    } catch (BufferUnderflowException e) {
      return PACKET_PARSE_ERROR_BUFFER_SIZE;
    }
  }
}

