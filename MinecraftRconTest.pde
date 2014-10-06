import java.io.UnsupportedEncodingException;
import processing.net.*;

int requestId = int(random(1000000, 10000000));
ByteBuffer receiveBuffer;
boolean loggedIn = false;

void setup()
{
  receiveBuffer = ByteBuffer.allocate(100);
  Client client = new Client(this, "localhost", 25575);

  MinecraftRconPacket loginPacket = new MinecraftRconPacket();
  loginPacket.requestId = requestId;
  loginPacket.type = MinecraftRconPacket.TYPE_LOGIN;
  loginPacket.payload = stringToBytes("password");

  client.write(loginPacket.toByteArray());

  delay(1000);

  MinecraftRconPacket packet = new MinecraftRconPacket();
  packet.requestId = requestId;
  packet.type = MinecraftRconPacket.TYPE_COMMAND;
  packet.payload = stringToBytes("list");

  client.write(packet.toByteArray());

  delay(1000);
}

byte[] stringToBytes(String string)
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

String bytesToString(byte[] bytes)
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

void clientEvent(Client client)
{
  byte[] newBytes = client.readBytes();
  receiveBuffer.put(newBytes);

  int abSize = receiveBuffer.position();
  byte[] allBytes = new byte[abSize];
  receiveBuffer.rewind();
  receiveBuffer.get(allBytes);

  MinecraftRconPacket packet = fromByteArray(allBytes);

  if (packet != null) {
    receiveBuffer.clear();
    packetReceived(packet);
  }
}

void packetReceived(MinecraftRconPacket packet)
{
  println(
    "Received packet with requestID " + packet.requestId +
    " type " + packet.type +
    " payload: \"" + bytesToString(packet.payload) + "\"" +
    " (" + packet.payload.length + ")"
  );
}

void draw()
{
}

