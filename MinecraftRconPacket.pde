import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.BufferUnderflowException;

public class MinecraftRconPacket
{
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

